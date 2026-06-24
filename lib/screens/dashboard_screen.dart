// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/adherence_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_tab.dart';
import 'medications/medications_screen.dart';
import 'adherence/adherence_screen.dart';
import 'caregiver/caregiver_screen.dart';
import 'caregiver/link_caregiver_sheet.dart'; // Added the import
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _role = 'patient';
  String _name = '';
  int _unreadCount = 0;

  final GlobalKey<NotificationsScreenState> _notifKey =
      GlobalKey<NotificationsScreenState>();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUnread();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('user_role') ?? 'patient';
      _name = prefs.getString('user_name') ?? '';
    });
  }

  Future<void> _loadUnread() async {
    try {
      final notifs = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _unreadCount = notifs.where((n) => n['is_read'] == 0).length;
      });
    } catch (_) {}
  }

  // LOGOUT LOGIC
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Sign out', style: AppTheme.titleMedium),
        content: const Text(
          'Are you sure you want to sign out of MedTrack?',
          style: AppTheme.body,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // 1. Clear Provider State (Important for UI consistency)
      await Provider.of<AdherenceProvider>(context, listen: false).logout();

      // 2. Navigate back to login and remove all previous routes
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  List<Widget> get _tabs => [
        HomeTab(userName: _name, role: _role),
        const MedicationsScreen(),
        const AdherenceScreen(),
        if (_role == 'caregiver') const CaregiverScreen(),
        NotificationsScreen(key: _notifKey, onRead: _loadUnread),
      ];

  List<String> get _titles => [
        'MedTrack',
        'Medications',
        'History',
        if (_role == 'caregiver') 'Patients',
        'Alerts',
      ];

  bool get _onNotificationsTab => _currentIndex == _tabs.length - 1;

  @override
  Widget build(BuildContext context) {
    final isCaregiver = _role == 'caregiver';
    final tabs = _tabs;
    final titles = _titles;
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(titles[safeIndex]),
        actions: [
          if (_onNotificationsTab)
            TextButton(
              onPressed: () => _notifKey.currentState?.markAllRead(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Mark all read'),
            ),

          // ONLY visible to patients: Link Caregiver Button
          if (!isCaregiver)
            IconButton(
              tooltip: 'Link Caregiver',
              onPressed: () => LinkCaregiverSheet.show(context),
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    size: 18, color: AppTheme.primary),
              ),
            ),

          IconButton(
            tooltip: 'Sign out',
            onPressed: _handleLogout,
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 18, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: safeIndex,
            onDestinationSelected: (i) {
              setState(() => _currentIndex = i);
              if (i == tabs.length - 1) _loadUnread();
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication_rounded),
                label: 'Meds',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'History',
              ),
              if (isCaregiver)
                const NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(Icons.group_rounded),
                  label: 'Patients',
                ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: _unreadCount > 0,
                  label: Text('$_unreadCount'),
                  backgroundColor: AppTheme.pulse,
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: const Icon(Icons.notifications_rounded),
                label: 'Alerts',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
