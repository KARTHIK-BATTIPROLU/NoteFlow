import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
  String? _localFilePath;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isSavingToDownloads = false;

  @override
  void initState() {
    super.initState();
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
      final filePath = await apiService.downloadFile(
        widget.resource.fileId,
        onProgress: (progress) {
          // Progress callback if needed
        },
      );

      if (mounted) {
        setState(() {
          _localFilePath = filePath;
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

  Future<void> _saveToDownloads() async {
    if (_localFilePath == null) return;

    setState(() {
      _isSavingToDownloads = true;
    });

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Could not access downloads directory');
      }

      // Create destination file
      final fileName = '${widget.resource.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
      final destinationPath = '${downloadsDir.path}/$fileName';

      // Copy file
      final sourceFile = File(_localFilePath!);
      await sourceFile.copy(destinationPath);

      // Save to Hive
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

  void _showShareComingSoon() {
    Toast.show(context, 'Share feature coming soon!');
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
          if (!_isLoading && !_hasError && _localFilePath != null) ...[
            IconButton(
              icon: Icon(
                Icons.share_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: _showShareComingSoon,
              tooltip: 'Share',
            ),
            IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: _isSavingToDownloads ? null : _saveToDownloads,
              tooltip: 'Download',
            ),
          ],
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
              'Downloading PDF...',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please wait',
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
                'Failed to load PDF',
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

    if (_localFilePath == null) {
      return Center(
        child: Text(
          'No file available',
          style: AppTextStyles.bodyLarge,
        ),
      );
    }

    return SfPdfViewer.file(
      File(_localFilePath!),
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      onDocumentLoadFailed: (details) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load PDF: ${details.error}';
        });
      },
    );
  }
}
