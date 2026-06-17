import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:klassinfo_app/core/services/notification_service.dart';
import '../../../core/constants/app_secrets.dart';
import '../../../core/services/firestore_service.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final FirestoreService _firestoreService = FirestoreService();

  Stream<List<AnnouncementModel>> announcementsStream(
    String classCode,
    String courseId,
  ) {
    return _firestoreService
        .announcementsStream(classCode, courseId)
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AnnouncementModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> postAnnouncement({
    required String classCode,
    required String courseId,
    required AnnouncementModel announcement,
  }) async {
    // 1. Write to Firestore
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classCode)
        .collection('courses')
        .doc(courseId)
        .collection('announcements')
        .add(announcement.toMap());

    // 2. Send push notification to the class topic
    await _sendTopicNotification(
      classCode: classCode,
      title: announcement.title,
      body: announcement.body,
    );
  }

  Future<void> deleteAnnouncement({
    required String classCode,
    required String courseId,
    required String announcementId,
  }) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classCode)
        .collection('courses')
        .doc(courseId)
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }

  Future<void> _sendTopicNotification({
    required String classCode,
    required String title,
    required String body,
  }) async {
    await NotificationService().sendAnnouncementNotification(
      classCode: classCode,
      title: title,
      body: body,
    );
  }
}
