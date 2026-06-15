import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
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

  // We hold a reference to the stream subscription so we can
  // cancel it when this provider is disposed. Always do this —
  // not cancelling causes memory leaks.
  StreamSubscription<UserModel?>? _userSubscription;

  void init(String uid) {
    // Cancel any existing subscription before starting a new one
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

  void reset() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _user = null;
    _classes = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Clean up the stream when the provider is destroyed.
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
