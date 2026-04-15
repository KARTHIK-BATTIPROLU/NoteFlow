import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/local_db.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = LocalDb.getAllDownloads();

    if (downloads.isEmpty) {
      return const Center(
        child: Text('No downloaded resources.'),
      );
    }

    return ListView.builder(
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final item = downloads[index];

        return ListTile(
          leading: Icon(
            item['fileType']?.toString().toLowerCase() == 'pdf'
                ? Icons.picture_as_pdf
                : Icons.slideshow,
            color: Colors.redAccent,
          ),
          title: Text(item['title'] ?? 'Unknown Document'),
          subtitle: const Text('Available offline'),
          onTap: () {
            if (item['fileType']?.toString().toLowerCase() == 'pdf') {
              context.push('/home/pdf-viewer', extra: item['localPath']);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use external ppt viewer')),
              );
            }
          },
        );
      },
    );
  }
}
