import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);

    ref.listen(uploadProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
      if (next.isSuccess && prev?.isSuccess != next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
        notifier.reset(); // Reset form on success
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload Resource',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setTitle,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Subject ID',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setSubject,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Topic ID',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setTopic,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: state.isUploading ? null : () => notifier.pickFile(),
              icon: const Icon(Icons.attach_file),
              label: Text(state.selectedFile?.name ?? 'Select PDF/PPT File'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            if (state.isUploading) ...[
              LinearProgressIndicator(value: state.uploadProgress),
              const SizedBox(height: 16),
              Text(
                'Uploading... \${(state.uploadProgress * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
              ),
            ] else
              ElevatedButton(
                onPressed: state.selectedFile == null ? null : () => notifier.upload(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Upload'),
              ),
          ],
        ),
      ),
    );
  }
}
