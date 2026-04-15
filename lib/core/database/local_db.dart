import 'package:hive_flutter/hive_flutter.dart';

class LocalDb {
  static const String downloadsBoxName = 'downloads';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(downloadsBoxName);
  }

  static Box<Map> get downloadsBox => Hive.box<Map>(downloadsBoxName);

  static Future<void> saveDownloadedFile(String resourceId, Map<String, dynamic> metadata) async {
    await downloadsBox.put(resourceId, metadata);
  }

  static Future<void> removeDownloadedFile(String resourceId) async {
    await downloadsBox.delete(resourceId);
  }

  static List<Map> getAllDownloads() {
    return downloadsBox.values.toList();
  }

  static bool isDownloaded(String resourceId) {
    return downloadsBox.containsKey(resourceId);
  }
}
