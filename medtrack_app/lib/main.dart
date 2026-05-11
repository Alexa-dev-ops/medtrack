import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart'; // 1. Added Provider import
import 'package:shared_preferences/shared_preferences.dart';


import 'package:medtrack_app/providers/adherence_provider.dart'; // 2. Added AdherenceProvider import
import 'package:medtrack_app/screens/splash_screen.dart';
import 'package:medtrack_app/screens/auth/login_screen.dart';
import 'package:medtrack_app/screens/dashboard_screen.dart';
import 'package:medtrack_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  ); // 3. Added missing semicolon here
}

class MedTrackApp extends StatelessWidget {
  const MedTrackApp({super.key});

  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null ? '/dashboard' : '/login';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedTrack',

      // Removed useInheritedMediaQuery as it is deprecated and handled by DevicePreview.appBuilder
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<String>(
        future: _getInitialRoute(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          return snap.data == '/dashboard'
              ? const DashboardScreen()
              : const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
