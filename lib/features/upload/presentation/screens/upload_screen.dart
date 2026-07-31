import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../../home/presentation/providers/search_provider.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  bool _formSubmitted = false;
  String? _selectedSubjectId;
  String? _selectedTopicId;
  
  late AnimationController _successAnimationController;
  late Animation<double> _successScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _successScaleAnimation = CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_outlined;
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (ext == 'ppt' || ext == 'pptx') return Icons.slideshow;
    return Icons.insert_drive_file_outlined;
  }

  Color _getFileIconColor(String? fileName) {
    if (fileName == null) return AppColors.textSecondary;
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return AppColors.pdfRed;
    if (ext == 'ppt' || ext == 'pptx') return AppColors.pptOrange;
    return AppColors.otherBlue;
  }

  void _handleUpload() async {
    setState(() {
      _formSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(uploadProvider.notifier);
    await notifier.upload();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);

    ref.listen(uploadProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        Toast.show(context, next.error!, isError: true);
      }
      
      if (next.isSuccess && prev?.isSuccess != next.isSuccess) {
        _successAnimationController.forward().then((_) {
          Toast.show(context, 'Uploaded successfully!');
          
          // Reset form
          Future.delayed(const Duration(milliseconds: 1500), () {
            notifier.reset();
            _titleController.clear();
            setState(() {
              _selectedSubjectId = null;
              _selectedTopicId = null;
              _formSubmitted = false;
            });
            _successAnimationController.reset();
          });
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Resource'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          autovalidateMode: _formSubmitted 
              ? AutovalidateMode.onUserInteraction 
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Picker Area
              _buildFilePicker(state, notifier),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Title Field
              _buildTitleField(notifier),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Subject Field (backend dynamic dropdown)
              _buildSubjectField(notifier),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Topic Field (backend dynamic dropdown)
              _buildTopicField(notifier),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Upload Button
              _buildUploadButton(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(UploadState state, UploadNotifier notifier) {
    final hasFile = state.selectedFile != null;
    
    return GestureDetector(
      onTap: state.isUploading ? null : () => notifier.pickFile(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: hasFile 
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: hasFile 
            ? _buildFileInfo(state.selectedFile!, notifier, state.isUploading)
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tap to select a PDF or PPT file',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Supported formats: PDF, PPT, PPTX (max 50 MB)',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFileInfo(PlatformFile file, UploadNotifier notifier, bool isUploading) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: _getFileIconColor(file.name).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            _getFileIcon(file.name),
            size: 32,
            color: _getFileIconColor(file.name),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                file.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatFileSize(file.size),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isUploading)
          IconButton(
            onPressed: () {
              notifier.reset();
            },
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
            tooltip: 'Remove file',
          ),
      ],
    );
  }

  Widget _buildTitleField(UploadNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Enter resource title',
            prefixIcon: Icon(Icons.title, size: 20),
            errorMaxLines: 2,
          ),
          onChanged: notifier.setTitle,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubjectField(UploadNotifier notifier) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        subjectsAsync.when(
          data: (subjects) {
            return DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              decoration: const InputDecoration(
                hintText: 'Select a subject',
                prefixIcon: Icon(Icons.school, size: 20),
                errorMaxLines: 2,
              ),
              items: subjects.map((subject) {
                return DropdownMenuItem<String>(
                  value: subject.id, // Backend MongoDB ObjectId string
                  child: Text(subject.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubjectId = value;
                  _selectedTopicId = null;
                });
                if (value != null) {
                  notifier.setSubject(value);
                  notifier.setTopic('');
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a subject';
                }
                return null;
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, stack) => Text(
            'Failed to load subjects',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicField(UploadNotifier notifier) {
    if (_selectedSubjectId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topic',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              hintText: 'Select a subject first',
              prefixIcon: Icon(Icons.topic, size: 20),
            ),
          ),
        ],
      );
    }

    final topicsAsync = ref.watch(topicsProvider(_selectedSubjectId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topic',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        topicsAsync.when(
          data: (topics) {
            return DropdownButtonFormField<String>(
              value: _selectedTopicId,
              decoration: const InputDecoration(
                hintText: 'Select a topic',
                prefixIcon: Icon(Icons.topic, size: 20),
                errorMaxLines: 2,
              ),
              items: topics.map((topic) {
                return DropdownMenuItem<String>(
                  value: topic.id, // Backend MongoDB ObjectId string
                  child: Text(topic.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopicId = value;
                });
                if (value != null) {
                  notifier.setTopic(value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a topic';
                }
                return null;
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, stack) => Text(
            'Failed to load topics',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(UploadState state) {
    final isUploading = state.isUploading;
    final isSuccess = state.isSuccess;
    
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isUploading || isSuccess ? null : _handleUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSuccess ? AppColors.success : AppColors.primary,
          disabledBackgroundColor: isSuccess 
              ? AppColors.success 
              : AppColors.primary.withOpacity(0.6),
        ),
        child: isUploading
            ? Stack(
                alignment: Alignment.center,
                children: [
                  LinearProgressIndicator(
                    value: state.uploadProgress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  Text(
                    '${(state.uploadProgress * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.buttonText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : isSuccess
                ? ScaleTransition(
                    scale: _successScaleAnimation,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Uploaded!'),
                      ],
                    ),
                  )
                : Text(
                    'Upload Resource',
                    style: AppTextStyles.buttonText.copyWith(
                      color: Colors.white,
                    ),
                  ),
      ),
    );
  }
}
