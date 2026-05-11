import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onRead;

  const NotificationsScreen({super.key, this.onRead});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      setState(() {
        _notifs = n;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'adherence':
        return Icons.check_circle_outline;
      case 'missed':
        return Icons.warning_amber_outlined;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService.markAllNotificationsRead();
              _load();
              widget.onRead?.call();
            },
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifs.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = _notifs[i];
                      final unread = n['is_read'] == 0;
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        child: Card(
                          color: unread
                              ? AppTheme.primary.withValues(alpha: 0.05)
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _typeColor(n['type']).withValues(alpha: 0.1),
                              child: Icon(
                                _typeIcon(n['type']),
                                color: _typeColor(n['type']),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              n['title'],
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n['body']),
                                const SizedBox(height: 2),
                                Text(
                                  n['created_at'],
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            trailing: unread
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                            onTap: () async {
                              if (unread) {
                                await ApiService.markNotificationRead(n['id']);
                                _load();
                                widget.onRead?.call();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
