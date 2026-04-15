import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mongoDbProvider = Provider<Db>((ref) {
  throw UnimplementedError('MongoDB must be initialized before use');
});

class MongoService {
  final Db _db;

  MongoService(this._db);

  DbCollection resources() => _db.collection('resources');
  DbCollection subjects() => _db.collection('subjects');
  DbCollection topics() => _db.collection('topics');

  Future<void> initIndexes() async {
    await subjects().createIndex(keys: {'name': 1}, unique: true);
    await topics().createIndex(keys: {'name': 1, 'subject': 1}, unique: true);
    await resources().createIndex(keys: {'subject': 1, 'topic': 1});
  }
}

final mongoServiceProvider = Provider<MongoService>((ref) {
  final db = ref.watch(mongoDbProvider);
  return MongoService(db);
});

Future<Db> initMongo(String uri) async {
  final db = await Db.create(uri);
  await db.open();
  return db;
}
