import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String classCode;     // document ID
  final String name;
  final String description;
  final String adminId;
  final DateTime createdAt;

  const ClassModel({
    required this.classCode,
    required this.name,
    required this.description,
    required this.adminId,
    required this.createdAt,
  });

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      classCode: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      adminId: data['adminId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}