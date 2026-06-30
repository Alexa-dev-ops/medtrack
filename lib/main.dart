import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
// Note: SharedPreferences import removed since SplashScreen handles the check now
import 'package:medtrack_app/providers/adherence_provider.dart';
import 'package:medtrack_app/screens/splash_screen.dart';
import 'package:medtrack_app/screens/auth/login_screen.dart';
import 'package:medtrack_app/screens/dashboard_screen.dart';
import 'package:medtrack_app/theme/app_theme.dart';
import 'package:medtrack_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up local notifications (medication reminders) before the app runs.
  await NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AdherenceProvider()..refreshData()),
      ],
      child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => const MedTrackApp(),
      ),
    ),
  );
}

class MedTrackApp extends StatelessWidget {
  const MedTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedTrack',
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      // 1. Theme correctly wired up
      theme: AppTheme.lightTheme,
      // 2. Home points directly to the Splash Screen to give it time to animate
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}