import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String postedBy;      // uid of the admin who posted
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.postedBy,
    required this.createdAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      postedBy: data['postedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'postedBy': postedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}