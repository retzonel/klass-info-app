import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final FirestoreService _firestoreService = FirestoreService();

  // Live stream of announcements for a course, newest first
  Stream<List<AnnouncementModel>> announcementsStream(
    String classCode,
    String courseId,
  ) {
    return _firestoreService
        .announcementsStream(classCode, courseId)
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  // Posts a new announcement to Firestore
  Future<void> postAnnouncement({
    required String classCode,
    required String courseId,
    required AnnouncementModel announcement,
  }) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classCode)
        .collection('courses')
        .doc(courseId)
        .collection('announcements')
        .add(announcement.toMap());
  }
}