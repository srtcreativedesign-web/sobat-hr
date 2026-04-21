import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/payroll/payroll_screen.dart';
import 'screens/payroll/thr_screen.dart';
import 'screens/submission/submission_menu_screen.dart';
import 'screens/submission/submission_screen.dart';
import 'screens/submission/create_submission_screen.dart';
import 'screens/announcement/announcement_list_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/attendance/attendance_history_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/update_service.dart';
import 'services/connectivity_service.dart';
import 'services/background_sync_service.dart';
import 'utils/error_handler.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Requires Full Rebuild if Gradle files changed)
  try {
    await Firebase.initializeApp();
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint(
      'If this is Android, please perform a FULL app stop and re-run.',
    );
  }

  // Initialize connectivity monitoring
  try {
    await ConnectivityService().initialize();
  } catch (e) {
    debugPrint('ConnectivityService initialization failed: $e');
  }

  // Initialize background sync for offline attendance
  try {
    initializeBackgroundSync();
  } catch (e) {
    debugPrint('Background sync initialization failed: $e');
  }

  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();

  // Check for in-app updates (non-blocking)
  try {
    UpdateService().checkForUpdate();
  } catch (e) {
    debugPrint('Update check failed: $e');
  }

  // --- GLOBAL ERROR HANDLING ---
  // 1. Capture errors during build phase (The Red Screen)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorHandler.errorWidget;
  };

  // 2. Capture errors outside build phase (Framework Errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // Still log to console
    AppErrorHandler.showInternalError(details.exception, details.stack);
  };

  // 3. Capture errors from asynchronous gaps (Platform Errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    AppErrorHandler.showInternalError(error, stack);
    return true; // Mark as handled
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge display for Android 15+ (SDK 35)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  ));

  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
            navigatorKey: AppErrorHandler.navigatorKey,
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
              '/payroll/thr': (context) => const ThrScreen(),
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

            return const WelcomeScreen();
          },
        );
      },
    );
  }
}
