import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:klassinfo_app/features/files/screens/file_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/classes/screens/join_class_screen.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/classes/screens/class_detail_screen.dart';
import 'features/classes/screens/course_detail_screen.dart';
import 'features/announcements/screens/post_announcement_screen.dart';

class KlassInfoApp extends StatelessWidget {
  const KlassInfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'KlassInfo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),

        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const AuthGate(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.dashboard: (_) => const DashboardScreen(),
          AppRoutes.joinClass: (_) => const JoinClassScreen(),
          AppRoutes.classDetail: (_) => const ClassDetailScreen(),
          AppRoutes.courseDetail: (_) => const CourseDetailScreen(),
          AppRoutes.postAnnouncement: (_) => const PostAnnouncementScreen(),
          AppRoutes.fileViewer: (_) => const FileViewerScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
