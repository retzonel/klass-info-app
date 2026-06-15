import '../../../core/services/firestore_service.dart';
import '../models/class_model.dart';

class ClassService {
  final FirestoreService _firestoreService = FirestoreService();

  // Validates the code then adds it to the user's joined list.
  // Returns an error string if something goes wrong, null if success.
  Future<String?> joinClass({
    required String uid,
    required String classCode,
  }) async {
    final code = classCode.trim().toUpperCase();

    if (code.isEmpty) return 'Please enter a class code.';

    // Check if this class actually exists in Firestore
    final exists = await _firestoreService.classExists(code);
    if (!exists) {
      return 'Class code "$code" not found. Check the code and try again.';
    }

    // Add to user's joinedClassIds
    await _firestoreService.joinClass(uid, code);
    return null; // null = success
  }

  // Fetches full ClassModel objects for a list of class codes.
  Future<List<ClassModel>> getClassesForUser(List<String> classIds) async {
    final docs = await _firestoreService.getClassesForUser(classIds);
    return docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
  }
}