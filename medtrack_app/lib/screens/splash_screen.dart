// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';

/// Splash screen built around a single signature moment: a heartbeat.
///
/// A "lub-dub" double pulse drives the logo's scale and glow, while a
/// small ECG strip beneath it scrolls continuously — the same rhythm,
/// rendered two ways. After ~5 seconds it checks for a stored session
/// and routes to the dashboard or the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _beatController;
  late final AnimationController _traceController;
  late final Animation<double> _scale;

  static const _beatPeriod = Duration(milliseconds: 1000);
  static const _holdDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    _beatController = AnimationController(vsync: this, duration: _beatPeriod)
      ..repeat();

    // A real ECG cadence: a quick sharp beat (the "R" spike), a smaller
    // secondary bump, then a flat rest — not a smooth sine wave.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 64),
    ]).animate(_beatController);

    _traceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    Future.delayed(_holdDuration, () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final hasSession = prefs.getString('token') != null;
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) =>
              hasSession ? const DashboardScreen() : const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _beatController.dispose();
    _traceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _scale,
                  builder: (context, child) {
                    final beat = _scale.value;
                    // Glow intensity rides the same curve as the scale.
                    final glow = ((beat - 0.96) / 0.26).clamp(0.0, 1.0);
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.pulse.withOpacity(0.25 + glow * 0.30),
                            blurRadius: 40 + glow * 30,
                            spreadRadius: 4 + glow * 10,
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: beat,
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AppTheme.softShadow(
                              color: Colors.black,
                              opacity: 0.18,
                            ),
                          ),
                          child: const Icon(
                            Icons.medication_rounded,
                            size: 56,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'MedTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your smart medication companion',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 240,
                  height: 64,
                  child: AnimatedBuilder(
                    animation: _traceController,
                    builder: (context, _) {
                      return ClipRect(
                        child: CustomPaint(
                          size: const Size(240, 64),
                          painter: _HeartbeatTracePainter(
                            progress: _traceController.value,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a looping ECG-style waveform that scrolls continuously from
/// right to left, like a bedside heart-rate monitor.
class _HeartbeatTracePainter extends CustomPainter {
  final double progress; // 0..1, one full cycle
  final Color color;

  _HeartbeatTracePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final midY = size.height * 0.55;
    final amp = size.height * 0.5;
    final unitWidth = size.width;
    final shift = progress * unitWidth;

    final path = Path();
    for (int i = -1; i <= 1; i++) {
      final dx = i * unitWidth - shift;
      path.addPath(_buildCycle(unitWidth, midY, amp), Offset(dx, 0));
    }

    canvas.drawPath(path, paint);
  }

  /// One QRS-style heartbeat cycle spanning [width], centred on [midY].
  Path _buildCycle(double width, double midY, double amp) {
    final p = Path();
    p.moveTo(0, midY);
    p.lineTo(width * 0.14, midY);
    p.lineTo(width * 0.20, midY - amp * 0.18);
    p.lineTo(width * 0.26, midY + amp * 0.12);
    p.lineTo(width * 0.32, midY - amp * 0.95);
    p.lineTo(width * 0.38, midY + amp * 0.55);
    p.lineTo(width * 0.44, midY - amp * 0.08);
    p.lineTo(width * 0.50, midY);
    p.lineTo(width * 0.70, midY);
    p.lineTo(width * 0.77, midY - amp * 0.22);
    p.lineTo(width * 0.84, midY);
    p.lineTo(width, midY);
    return p;
  }

  @override
  bool shouldRepaint(covariant _HeartbeatTracePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
