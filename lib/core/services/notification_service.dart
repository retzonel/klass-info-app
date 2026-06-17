import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import '../../core/constants/app_secrets.dart';

// Top-level function — required by FCM for background message handling.
// Must be outside any class and annotated with @pragma.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart so we don't need to
  // call initializeApp() here again.
  debugPrint('Background message received: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Call this once from main.dart before runApp()
  static Future<void> initialize() async {
    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Call this after the user logs in
  Future<void> setup() async {
    // Request permission (required on iOS, recommended on Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    debugPrint('FCM Device Token: $token');

    // Listen for messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      // In a real app you'd show an in-app banner here.
      // For now, FCM handles background/closed state automatically.
    });

    // When the user taps a notification and the app was in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'Notification tapped (background): ${message.notification?.title}',
      );
      // You could navigate to the relevant course here in a future iteration
    });

    // Check if the app was opened from a terminated state via a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'App opened from notification: ${initialMessage.notification?.title}',
      );
    }
  }

  // Subscribe to a class topic — call when a student joins a class
  Future<void> subscribeToClass(String classCode) async {
    final topic = _topicName(classCode);
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  // Unsubscribe — call if you later add a "leave class" feature
  Future<void> unsubscribeFromClass(String classCode) async {
    await _messaging.unsubscribeFromTopic(_topicName(classCode));
  }

  // FCM topic names must be alphanumeric + underscores/hyphens only.
  // Class codes like "CSC300A" are fine. This sanitizes just in case.
  String _topicName(String classCode) {
    return classCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase();
  }

  Future<void> sendAnnouncementNotification({
    required String classCode,
    required String title,
    required String body,
  }) async {
    try {
      final token = await _getAccessToken();
      final topic = _topicName(classCode);

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/${AppSecrets.fcmProjectId}/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': {
            'topic': topic,
            'notification': {'title': title, 'body': body},
            'data': {'classCode': classCode, 'type': 'announcement'},
            'android': {
              'notification': {
                'channel_id': 'klassinfo_channel',
                'sound': 'default',
              },
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default'},
              },
            },
          },
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('FCM V1 error: ${response.body}');
      } else {
        debugPrint('Notification sent to topic: $topic');
      }
    } catch (e) {
      // Non-fatal — announcement is already in Firestore
      debugPrint('Notification send failed: $e');
    }
  }

  Future<String> _getAccessToken() async {
    final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson({
      'type': 'service_account',
      'project_id': AppSecrets.fcmProjectId,
      'client_email': AppSecrets.fcmClientEmail,
      'private_key': AppSecrets.fcmPrivateKey,
      // googleapis_auth requires this field — value can be empty string
      'client_id': AppSecrets.fcmClientId,
      'token_uri': 'https://oauth2.googleapis.com/token',
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await auth.clientViaServiceAccount(
      serviceAccountCredentials,
      scopes,
    );

    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }
}
