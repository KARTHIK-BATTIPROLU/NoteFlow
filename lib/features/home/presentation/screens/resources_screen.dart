import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/local_db.dart';
import '../providers/search_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ResourcesScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;

  const ResourcesScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  final Map<String, bool> _downloadingMap = {};

  Future<void> _downloadResource(dynamic resource, BuildContext context) async {
    setState(() {
      _downloadingMap[resource.id] = true;
    });

    try {
      final response = await http.get(Uri.parse(resource.fileUrl));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '\${dir.path}/\${resource.id}.\${resource.fileType}';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        await LocalDb.saveDownloadedFile(resource.id, {
          'id': resource.id,
          'title': resource.title,
          'fileType': resource.fileType,
          'localPath': filePath,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download complete!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: \$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingMap[resource.id] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(resourcesProvider(widget.topicId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName),
      ),
      body: resourcesAsync.when(
        data: (resources) {
          if (resources.isEmpty) {
            return const Center(child: Text('No resources available.'));
          }
          return ListView.builder(
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final resource = resources[index];
              final isDownloaded = LocalDb.isDownloaded(resource.id);
              final isDownloading = _downloadingMap[resource.id] ?? false;

              return ListTile(
                leading: Icon(
                  resource.fileType.toLowerCase() == 'pdf' ? Icons.picture_as_pdf : Icons.slideshow,
                  color: Colors.redAccent,
                ),
                title: Text(resource.title),
                subtitle: Text('Uploaded by \${resource.uploadedBy}'),
                trailing: isDownloading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(isDownloaded ? Icons.download_done : Icons.download),
                        color: isDownloaded ? Colors.green : null,
                        tooltip: isDownloaded ? 'Already downloaded' : 'Download file',
                        onPressed: isDownloaded
                            ? null
                            : () => _downloadResource(resource, context),
                      ),
                onTap: isDownloaded
                    ? () {
                        final localData = LocalDb.downloadsBox.get(resource.id);
                        if (localData != null && localData['localPath'] != null) {
                          if (resource.fileType.toLowerCase() == 'pdf') {
                            context.push('/home/pdf-viewer', extra: localData['localPath']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cannot preview PPTX in app. Use external viewer.')),
                            );
                          }
                        }
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please download the file to view it.')),
                        );
                      },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: \$error')),
      ),
    );
  }
}
