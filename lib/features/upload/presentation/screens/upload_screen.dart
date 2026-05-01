import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  
  bool _formSubmitted = false;
  
  // Static predefined subjects
  final List<Map<String, String>> _predefinedSubjects = [
    {'id': 'cs', 'name': 'Computer Science'},
    {'id': 'math', 'name': 'Mathematics'},
    {'id': 'physics', 'name': 'Physics'},
    {'id': 'chemistry', 'name': 'Chemistry'},
  ];
  
  // Static predefined topics for each subject
  final Map<String, List<Map<String, String>>> _predefinedTopics = {
    'cs': [
      {'id': 'cs_dsa', 'name': 'Data Structures & Algorithms'},
      {'id': 'cs_oop', 'name': 'Object-Oriented Programming'},
      {'id': 'cs_db', 'name': 'Database Management'},
      {'id': 'cs_os', 'name': 'Operating Systems'},
      {'id': 'cs_networks', 'name': 'Computer Networks'},
      {'id': 'cs_web', 'name': 'Web Development'},
      {'id': 'cs_ai', 'name': 'Artificial Intelligence'},
      {'id': 'cs_ml', 'name': 'Machine Learning'},
    ],
    'math': [
      {'id': 'math_calculus', 'name': 'Calculus'},
      {'id': 'math_algebra', 'name': 'Linear Algebra'},
      {'id': 'math_stats', 'name': 'Statistics'},
      {'id': 'math_discrete', 'name': 'Discrete Mathematics'},
      {'id': 'math_diff', 'name': 'Differential Equations'},
    ],
    'physics': [
      {'id': 'phy_mechanics', 'name': 'Mechanics'},
      {'id': 'phy_thermo', 'name': 'Thermodynamics'},
      {'id': 'phy_em', 'name': 'Electromagnetism'},
      {'id': 'phy_optics', 'name': 'Optics'},
      {'id': 'phy_quantum', 'name': 'Quantum Physics'},
    ],
    'chemistry': [
      {'id': 'chem_organic', 'name': 'Organic Chemistry'},
      {'id': 'chem_inorganic', 'name': 'Inorganic Chemistry'},
      {'id': 'chem_physical', 'name': 'Physical Chemistry'},
      {'id': 'chem_analytical', 'name': 'Analytical Chemistry'},
    ],
  };
  
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
    _topicController.dispose();
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
            _topicController.clear();
            _selectedSubjectId = null;
            _selectedTopicId = null;
            setState(() {
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
              
              // Subject Field with Autocomplete
              _buildSubjectField(notifier),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Topic Field with Autocomplete
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
            color: hasFile 
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.4),
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
          'Supported formats: PDF, PPT, PPTX',
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
          decoration: InputDecoration(
            hintText: 'Enter resource title',
            prefixIcon: const Icon(Icons.title, size: 20),
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
        DropdownButtonFormField<String>(
          value: _selectedSubjectId,
          decoration: InputDecoration(
            hintText: 'Select a subject',
            prefixIcon: const Icon(Icons.school, size: 20),
            errorMaxLines: 2,
          ),
          items: _predefinedSubjects.map((subject) {
            return DropdownMenuItem<String>(
              value: subject['id'],
              child: Text(subject['name']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSubjectId = value;
              _selectedTopicId = null; // Reset topic when subject changes
              _topicController.clear();
            });
            if (value != null) {
              notifier.setSubject(value);
              notifier.setTopic(''); // Clear topic
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a subject';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTopicField(UploadNotifier notifier) {
    final availableTopics = _selectedSubjectId != null 
        ? _predefinedTopics[_selectedSubjectId!] ?? []
        : [];
    
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
          value: _selectedTopicId,
          decoration: InputDecoration(
            hintText: _selectedSubjectId == null 
                ? 'Select a subject first'
                : 'Select a topic',
            prefixIcon: const Icon(Icons.topic, size: 20),
            errorMaxLines: 2,
          ),
          items: availableTopics.map((topic) {
            return DropdownMenuItem<String>(
              value: topic['id'],
              child: Text(topic['name']!),
            );
          }).toList(),
          onChanged: _selectedSubjectId == null ? null : (value) {
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
