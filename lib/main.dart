import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:leavesync/pages/auth/login_page.dart';
import 'package:leavesync/pages/auth/register_page.dart';
import 'package:leavesync/pages/auth/welcome_page.dart';
import 'package:leavesync/pages/auth/forgot_password_page.dart';
import 'package:leavesync/pages/dashboard/dashboard_page.dart';
import 'package:leavesync/pages/leave/apply_leave_page.dart';
import 'package:leavesync/pages/leave/leave_history_page.dart';
import 'package:leavesync/pages/profile/profile_page.dart';

void main() {
  runApp(
    DevicePreview(
      builder: (context) => const LeaveSyncApp(),
    ),
  );
}

class LeaveSyncApp extends StatelessWidget {
  const LeaveSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/apply': (context) => const ApplyLeavePage(),
        '/history': (context) => const LeaveHistoryPage(),
        '/profile': (context) => const ProfilePage(),
        '/welcome': (context) => const WelcomePage(),
      },    
    );
  }
}
