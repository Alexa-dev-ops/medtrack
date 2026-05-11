// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HomeTab extends StatefulWidget {
  final String userName;
  final String role;

  const HomeTab({super.key, required this.userName, required this.role});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> _todayDoses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doses = await ApiService.getAdherence();
      setState(() {
        _todayDoses = doses;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  double get _todayRate {
    if (_todayDoses.isEmpty) return 0;
    final taken = _todayDoses.where((d) => d['status'] == 'taken').length;
    return taken / _todayDoses.length;
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppTheme.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting,',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              Text(
                                widget.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.role == 'caregiver'
                                    ? 'Monitoring your patients today'
                                    : "Here's your medication summary",
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Adherence Ring Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  "Today's Adherence",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 120,
                                  width: 120,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _todayRate,
                                        strokeWidth: 10,
                                        backgroundColor:
                                            const Color(0xFFE0E0E0),
                                        valueColor: AlwaysStoppedAnimation(
                                          _todayRate >= 0.8
                                              ? AppTheme.success
                                              : _todayRate >= 0.5
                                                  ? AppTheme.warning
                                                  : AppTheme.error,
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          '${(_todayRate * 100).toInt()}%',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _StatPill(
                                      'Taken',
                                      '${_todayDoses.where((d) => d['status'] == 'taken').length}',
                                      AppTheme.success,
                                    ),
                                    _StatPill(
                                      'Pending',
                                      '${_todayDoses.where((d) => d['status'] == 'pending').length}',
                                      AppTheme.warning,
                                    ),
                                    _StatPill(
                                      'Skipped',
                                      '${_todayDoses.where((d) => d['status'] == 'skipped').length}',
                                      AppTheme.error,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Today's Schedule",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (_todayDoses.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'No medications scheduled today',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            ),
                          )
                        else
                          ..._todayDoses.map((dose) =>
                              _DoseCard(dose: dose, onRefresh: _load)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _DoseCard extends StatelessWidget {
  final Map dose;
  final VoidCallback onRefresh;

  const _DoseCard({required this.dose, required this.onRefresh});

  Color get _statusColor => dose['status'] == 'taken'
      ? AppTheme.success
      : dose['status'] == 'skipped'
          ? AppTheme.error
          : AppTheme.warning;

  IconData get _typeIcon {
    switch (dose['type']) {
      case 'tablet':
        return Icons.circle;
      case 'syrup':
        return Icons.water_drop;
      case 'injection':
        return Icons.colorize;
      default:
        return Icons.medication;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor.withOpacity(0.1),
          child: Icon(_typeIcon, color: _statusColor),
        ),
        title: Text(
          dose['medication_name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${dose['dosage']} · ${dose['scheduled_time']}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: dose['status'] == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: AppTheme.success),
                    onPressed: () async {
                      await ApiService.markTaken(dose['id']);
                      onRefresh();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined,
                        color: AppTheme.error),
                    onPressed: () async {
                      await ApiService.markSkipped(dose['id']);
                      onRefresh();
                    },
                  ),
                ],
              )
            : Chip(
                label: Text(
                  dose['status'].toString().toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: _statusColor,
                padding: EdgeInsets.zero,
              ),
      ),
    );
  }
}
