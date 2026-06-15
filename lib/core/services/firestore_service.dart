import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── USER ────────────────────────────────────────────────

  // Creates a user profile document after registration.
  // Called once, right after Firebase Auth creates the account.
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Fetches a single user document by their UID.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // A live stream of the user's document.
  // If their role or class list changes in Firestore, the app updates instantly.
  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ─── CLASSES ─────────────────────────────────────────────

  // Checks if a class with this code exists in Firestore.
  Future<bool> classExists(String classCode) async {
    final doc = await _db.collection('classes').doc(classCode).get();
    return doc.exists;
  }

  // Fetches a class document by its code.
  Future<DocumentSnapshot?> getClass(String classCode) async {
    final doc = await _db.collection('classes').doc(classCode).get();
    if (!doc.exists) return null;
    return doc;
  }

  // Adds a class code to the student's joinedClassIds list.
  // arrayUnion is Firestore's safe way to add to a list —
  // it won't add duplicates if the student joins twice.
  Future<void> joinClass(String uid, String classCode) async {
    await _db.collection('users').doc(uid).update({
      'joinedClassIds': FieldValue.arrayUnion([classCode]),
    });
  }

  // Fetches all class documents for a given list of class codes.
  Future<List<DocumentSnapshot>> getClassesForUser(
      List<String> classIds) async {
    if (classIds.isEmpty) return [];

    // Firestore's 'whereIn' fetches multiple documents in one query.
    // Limit: 10 items max per query — sufficient for MVP.
    final query = await _db
        .collection('classes')
        .where(FieldPath.documentId, whereIn: classIds)
        .get();

    return query.docs;
  }

  // ─── COURSES ─────────────────────────────────────────────

  // Live stream of all courses in a class — UI updates automatically.
  Stream<QuerySnapshot> coursesStream(String classCode) {
    return _db
        .collection('classes')
        .doc(classCode)
        .collection('courses')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ─── ANNOUNCEMENTS ───────────────────────────────────────

  Stream<QuerySnapshot> announcementsStream(
      String classCode, String courseId) {
    return _db
        .collection('classes')
        .doc(classCode)
        .collection('courses')
        .doc(courseId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── FILES ───────────────────────────────────────────────

  Stream<QuerySnapshot> filesStream(String classCode, String courseId) {
    return _db
        .collection('classes')
        .doc(classCode)
        .collection('courses')
        .doc(courseId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }
}