import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String classCode;    
  final String title;
  final String description;
  final DateTime createdAt;

  const CourseModel({
    required this.id,
    required this.classCode,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc, String classCode) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      classCode: classCode,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}