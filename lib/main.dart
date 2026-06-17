import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:klassinfo_app/core/services/notification_service.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //connect to firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

    await NotificationService.initialize();


  runApp(const KlassInfoApp());
}
