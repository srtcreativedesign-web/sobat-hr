import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/change_password_screen.dart'; // Added
import 'screens/payroll/payroll_screen.dart';
import 'screens/submission/submission_menu_screen.dart'; // Added
import 'screens/submission/submission_screen.dart'; // Added
import 'screens/submission/create_submission_screen.dart'; // Added
import 'screens/announcement/announcement_list_screen.dart'; // Added
import 'screens/notification/notification_screen.dart'; // Added
import 'screens/attendance/attendance_screen.dart';
import 'screens/attendance/attendance_history_screen.dart'; // Added
import 'screens/profile/enroll_face_screen.dart'; // Added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'SOBAT HR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),

          '/profile': (context) => const ProfileScreen(),
          '/profile/edit': (context) => const EditProfileScreen(),
          '/profile/change-password': (context) => const ChangePasswordScreen(),
          '/payroll': (context) => const PayrollScreen(),
          '/submission/menu': (context) => const SubmissionMenuScreen(),
          '/submission/list': (context) => const Scaffold(
            backgroundColor: Color(0xFFF9FAFB),
            body: SubmissionScreen(),
          ),
          '/submission/create': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as String;
            return CreateSubmissionScreen(type: args);
          },
          '/announcements': (context) => const AnnouncementListScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/attendance/history': (context) => const AttendanceHistoryScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorCyan),
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
