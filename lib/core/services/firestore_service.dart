import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/resource.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all subjects
  Future<List<Subject>> getSubjects() async {
    try {
      final snapshot = await _firestore
          .collection('subjects')
          .orderBy('name')
          .get();
      
      return snapshot.docs
          .map((doc) => Subject.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  // Get topics for a subject
  Future<List<Topic>> getTopics(String subjectId) async {
    try {
      final snapshot = await _firestore
          .collection('topics')
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('name')
          .get();
      
      return snapshot.docs
          .map((doc) => Topic.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching topics: $e');
      return [];
    }
  }

  // Get all resources (for home page - shows all uploads)
  Future<List<Resource>> getAllResources() async {
    try {
      final snapshot = await _firestore
          .collection('resources')
          .orderBy('uploadedAt', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs
          .map((doc) => Resource.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching all resources: $e');
      return [];
    }
  }

  // Get resources for a specific topic
  Future<List<Resource>> getResources(String topicId) async {
    try {
      final snapshot = await _firestore
          .collection('resources')
          .where('topicId', isEqualTo: topicId)
          .orderBy('uploadedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Resource.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching resources for topic: $e');
      return [];
    }
  }

  // Search resources by query (for search page - shows all files from everyone)
  Future<List<Resource>> searchResources({
    String? query,
    String? subjectId,
    String? topicId,
  }) async {
    try {
      Query resourceQuery = _firestore.collection('resources');

      // Filter by subject if provided
      if (subjectId != null && subjectId.isNotEmpty) {
        resourceQuery = resourceQuery.where('subjectId', isEqualTo: subjectId);
      }

      // Filter by topic if provided
      if (topicId != null && topicId.isNotEmpty) {
        resourceQuery = resourceQuery.where('topicId', isEqualTo: topicId);
      }

      // Order by upload date
      resourceQuery = resourceQuery.orderBy('uploadedAt', descending: true);

      final snapshot = await resourceQuery.limit(100).get();
      
      List<Resource> resources = snapshot.docs
          .map((doc) => Resource.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();

      // If query is provided, filter by title or description
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        resources = resources.where((resource) {
          return resource.title.toLowerCase().contains(lowerQuery) ||
                 (resource.description?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      return resources;
    } catch (e) {
      print('Error searching resources: $e');
      return [];
    }
  }

  // Get resources uploaded by a specific user
  Future<List<Resource>> getUserResources(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('resources')
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Resource.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching user resources: $e');
      return [];
    }
  }
}
