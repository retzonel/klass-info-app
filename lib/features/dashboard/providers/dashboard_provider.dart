import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../classes/models/class_model.dart';
import '../../classes/services/class_service.dart';

class DashboardProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ClassService _classService = ClassService();

  UserModel? _user;
  List<ClassModel> _classes = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  List<ClassModel> get classes => _classes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription<UserModel?>? _userSubscription;

  void init(String uid) {
    _userSubscription?.cancel();
    _userSubscription = null;

    _isLoading = true;
    notifyListeners();

    _userSubscription = _firestoreService
        .userStream(uid)
        .listen(
          (user) async {
            _user = user;

            if (user != null && user.joinedClassIds.isNotEmpty) {
              _classes = await _classService.getClassesForUser(
                user.joinedClassIds,
              );

              // Subscribe to topics in the background — do NOT await this.
              // If FCM is slow, it must never block the dashboard from loading.
              _subscribeToTopicsInBackground(user.joinedClassIds);
            } else {
              _classes = [];
            }

            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load your data. Please restart the app.';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Fire-and-forget. Never awaited, never blocks the UI.
  void _subscribeToTopicsInBackground(List<String> classIds) {
    final notificationService = NotificationService();
    for (final classId in classIds) {
      notificationService.subscribeToClass(classId).catchError((e) {
        debugPrint('Topic subscription failed for $classId: $e');
      });
    }
  }

  void reset() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _user = null;
    _classes = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
