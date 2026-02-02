import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/change_password_screen.dart'; // Added
import 'screens/settings/settings_screen.dart'; // Added
import 'screens/payroll/payroll_screen.dart';
import 'screens/submission/submission_menu_screen.dart'; // Added
import 'screens/submission/submission_screen.dart'; // Added
import 'screens/submission/create_submission_screen.dart'; // Added
import 'screens/announcement/announcement_list_screen.dart'; // Added
import 'screens/notification/notification_screen.dart'; // Added
import 'screens/attendance/attendance_screen.dart';
import 'screens/attendance/attendance_history_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'SOBAT HR',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('id')],
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/profile/edit': (context) => const EditProfileScreen(),
              '/profile/change-password': (context) =>
                  const ChangePasswordScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/payroll': (context) => const PayrollScreen(),
              '/submission/menu': (context) => const SubmissionMenuScreen(),
              '/submission/list': (context) => const Scaffold(
                backgroundColor: Color(0xFFF9FAFB),
                body: SubmissionScreen(),
              ),
              '/submission/create': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments as String;
                return CreateSubmissionScreen(type: args);
              },
              '/announcements': (context) => const AnnouncementListScreen(),
              '/notifications': (context) => const NotificationScreen(),
              '/attendance': (context) => const AttendanceScreen(),
              '/attendance/history': (context) =>
                  const AttendanceHistoryScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFirstLaunch(),
      builder: (context, snapshot) {
        // Show loading while checking
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorCyan),
              ),
            ),
          );
        }

        final hasSeenOnboarding = snapshot.data!;

        // If first launch, show onboarding
        if (!hasSeenOnboarding) {
          return const OnboardingScreen();
        }

        // Otherwise, check authentication
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.colorCyan,
                    ),
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
      },
    );
  }
}
