import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'providers/locale_provider.dart';
import 'services/connectivity_service.dart';
import 'utils/error_handler.dart';
import 'dart:ui';
import 'screens/sobat_outlet/sobat_outlet_login_screen.dart';
import 'screens/sobat_outlet/sobat_outlet_home_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ConnectivityService().initialize();
  } catch (e) {
    debugPrint('ConnectivityService initialization failed: $e');
  }

  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorHandler.errorWidget;
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppErrorHandler.showInternalError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppErrorHandler.showInternalError(error, stack);
    return true;
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(SobatOutletApp(prefs: prefs));
}

class SobatOutletApp extends StatelessWidget {
  final SharedPreferences prefs;

  const SobatOutletApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'SOBAT OUTLET',
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
              '/': (context) => const OutletAuthWrapper(),
              '/outlet-home': (context) => const SobatOutletHomeScreen(),
            },
          );
        },
      ),
    );
  }
}

class OutletAuthWrapper extends StatelessWidget {
  const OutletAuthWrapper({super.key});

  Future<bool> _checkOutletState() async {
    final sobatOutletData = await StorageService.getSobatOutletData();
    return sobatOutletData != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOutletState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorCyan),
              ),
            ),
          );
        }

        final isSobatOutlet = snapshot.data!;
        
        if (isSobatOutlet) {
          return const SobatOutletHomeScreen();
        }

        return const SobatOutletLoginScreen();
      },
    );
  }
}
