import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;              // "student" or "admin"
  final List<String> joinedClassIds;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.joinedClassIds,
    required this.createdAt,
  });

  // Converts a Firestore document snapshot into a UserModel object.
  // We'll call this everywhere we read a user from Firestore.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'student',
      joinedClassIds: List<String>.from(data['joinedClassIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Converts a UserModel into a Map for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'joinedClassIds': joinedClassIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isAdmin => role == 'admin';
}