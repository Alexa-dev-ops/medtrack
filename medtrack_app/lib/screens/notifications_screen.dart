// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onRead;

  const NotificationsScreen({super.key, this.onRead});

  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

/// Public state so [DashboardScreen] can drive "mark all read" from its
/// own AppBar action via a GlobalKey, instead of this screen owning a
/// second, redundant AppBar.
class NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final n = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifs = n;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> markAllRead() async {
    await ApiService.markAllNotificationsRead();
    await _load();
    widget.onRead?.call();
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'adherence':
        return Icons.check_circle_outline_rounded;
      case 'missed':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'adherence':
        return AppTheme.success;
      case 'missed':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 34,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("You're all caught up",
                        style: AppTheme.titleMedium),
                    const SizedBox(height: 6),
                    const Text(
                      'New alerts about doses and reminders\nwill show up here.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _notifs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = _notifs[i];
          final unread = n['is_read'] == 0;
          final color = _typeColor(n['type']);

          return Dismissible(
            key: Key('notif_${n['id']}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) async {
              await ApiService.markNotificationRead(n['id']);
              widget.onRead?.call();
            },
            background: Container(
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.check_rounded, color: Colors.white),
            ),
            child: GestureDetector(
              onTap: () async {
                if (unread) {
                  await ApiService.markNotificationRead(n['id']);
                  _load();
                  widget.onRead?.call();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: unread
                      ? Border.all(color: color.withOpacity(0.25))
                      : null,
                  boxShadow: AppTheme.softShadow(opacity: 0.04),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_typeIcon(n['type']), color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(n['body'], style: AppTheme.bodyMuted),
                          const SizedBox(height: 6),
                          Text(n['created_at'], style: AppTheme.caption),
                        ],
                      ),
                    ),
                    if (unread)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.pulse,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
