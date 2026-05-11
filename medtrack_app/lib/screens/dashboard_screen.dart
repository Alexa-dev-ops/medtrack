// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/adherence_provider.dart';
import '../services/api_service.dart';
import 'home_tab.dart';
import 'medications/medications_screen.dart';
import 'adherence/adherence_screen.dart';
import 'caregiver/caregiver_screen.dart';
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of MedTrack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Clear Provider State (Important for UI consistency)
      if (mounted) {
        await Provider.of<AdherenceProvider>(context, listen: false).logout();

        // 2. Navigate back to login and remove all previous routes
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  List<Widget> get _tabs => [
        HomeTab(userName: _name, role: _role),
        const MedicationsScreen(),
        const AdherenceScreen(),
        if (_role == 'caregiver') const CaregiverScreen(),
        NotificationsScreen(onRead: _loadUnread),
      ];

  @override
  Widget build(BuildContext context) {
    final isCaregiver = _role == 'caregiver';

    return Scaffold(
      // Added AppBar for the Logout Action
      appBar: AppBar(
        title: const Text('MedTrack'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          // Adjust index check based on role
          if (i == (isCaregiver ? 4 : 3)) _loadUnread();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'History',
          ),
          if (isCaregiver)
            const NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Patients',
            ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
