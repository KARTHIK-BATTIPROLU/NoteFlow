import 'dart:io' show Platform, Directory, File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/resource.dart';
import '../../../../core/services/api_provider.dart';
import '../../../../core/database/local_db.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/theme/app_theme.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final Resource resource;

  const PdfViewerScreen({
    super.key,
    required this.resource,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  Uint8List? _fileBytes;
  String? _downloadUrl;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isSavingToDownloads = false;
  late int _likesCount;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.resource.likes;
    _downloadFile();
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final url = await apiService.getDownloadUrl(widget.resource.id);
      final bytes = await apiService.downloadFileBytes(
        widget.resource.id,
        onProgress: (progress) {},
      );

      if (mounted) {
        setState(() {
          _downloadUrl = url;
          _fileBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLike() async {
    if (_isLiked) return;
    setState(() {
      _isLiked = true;
      _likesCount += 1;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final updatedLikes = await apiService.likeResource(widget.resource.id);
      if (mounted) {
        setState(() {
          _likesCount = updatedLikes;
        });
        Toast.show(context, 'Liked!');
      }
    } catch (e) {
      // Keep optimistic count
    }
  }

  void _shareNote() async {
    final title = widget.resource.title;
    final subject = widget.resource.subjectName ?? 'General';
    final topic = widget.resource.topicName ?? 'Notes';
    final uploader = widget.resource.uploaderHandle ?? 'student';
    final link = _downloadUrl ?? '';

    final shareText =
        'Check out "$title" on NoteFlow!\n'
        'Subject: $subject | Topic: $topic\n'
        'Uploaded by: @$uploader\n'
        '${link.isNotEmpty ? "View / Download: $link" : ""}';

    await Clipboard.setData(ClipboardData(text: shareText));
    if (mounted) {
      Toast.show(context, 'Note link & details copied to clipboard!');
    }
  }

  Future<void> _saveToDownloads() async {
    if (_fileBytes == null) return;

    setState(() {
      _isSavingToDownloads = true;
    });

    try {
      final fileName = '${widget.resource.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';

      if (kIsWeb) {
        // On Web, open download URL to trigger direct browser download
        if (_downloadUrl != null) {
          final uri = Uri.parse(_downloadUrl!);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) {
            Toast.show(context, 'Downloading note in browser...');
          }
        }
      } else {
        // Safe directory across mobile & desktop platforms
        Directory? downloadsDir;
        if (Platform.isAndroid || Platform.isIOS) {
          downloadsDir = await getApplicationDocumentsDirectory();
        } else {
          downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        }

        final destinationPath = '${downloadsDir.path}/$fileName';
        final file = File(destinationPath);
        await file.writeAsBytes(_fileBytes!);

        // Save to Hive for offline library
        await LocalDb.saveDownloadedFile(widget.resource.id, {
          'id': widget.resource.id,
          'title': widget.resource.title,
          'fileType': widget.resource.fileType,
          'localPath': destinationPath,
          'downloadedAt': DateTime.now().toIso8601String(),
          'size': widget.resource.size,
          'subject_name': widget.resource.subjectName,
          'topic_name': widget.resource.topicName,
        });

        if (mounted) {
          Toast.show(context, 'Saved to Downloads: $fileName');
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, 'Failed to save: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToDownloads = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.resource.title,
          style: AppTextStyles.headingMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Like Action
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
              color: _isLiked ? AppColors.error : AppColors.textPrimary,
            ),
            onPressed: _handleLike,
            tooltip: 'Like ($_likesCount)',
          ),
          // Share Action
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: _shareNote,
            tooltip: 'Share note',
          ),
          // Download Action
          if (!_isLoading && !_hasError && _fileBytes != null)
            IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: _isSavingToDownloads ? null : _saveToDownloads,
              tooltip: kIsWeb ? 'Download in browser' : 'Save to device',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Loading note...',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please wait while note is prepared',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Failed to load note',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: _downloadFile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_fileBytes == null) {
      return Center(
        child: Text(
          'No file content available',
          style: AppTextStyles.bodyLarge,
        ),
      );
    }

    return SfPdfViewer.memory(
      _fileBytes!,
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      onDocumentLoadFailed: (details) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to render PDF: ${details.error}';
        });
      },
    );
  }
}
