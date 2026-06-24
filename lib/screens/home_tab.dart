// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../providers/adherence_provider.dart';

class HomeTab extends StatelessWidget {
  final String userName;
  final String role;

  const HomeTab({super.key, required this.userName, required this.role});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Consumer<AdherenceProvider>(
      builder: (context, adherenceProvider, child) {
        final isLoading = adherenceProvider.isLoading;
        final todayDoses = adherenceProvider.todayDoses;

        double todayRate = 0;
        if (todayDoses.isNotEmpty) {
          final taken = todayDoses.where((d) => d['status'] == 'taken').length;
          todayRate = taken / todayDoses.length;
        }

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await adherenceProvider.refreshData();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 176,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primary,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration:
                        const BoxDecoration(gradient: AppTheme.heroGradient),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -30,
                          right: -20,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting,',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                userName.isEmpty ? 'there' : userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.favorite_rounded,
                                      size: 13,
                                      color: AppTheme.pulse.withOpacity(0.9)),
                                  const SizedBox(width: 6),
                                  Text(
                                    role == 'caregiver'
                                        ? 'Monitoring your patients today'
                                        : "Here's your medication summary",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Adherence ring card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.softShadow(opacity: 0.05),
                      ),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Today's adherence",
                              style: AppTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 132,
                            width: 132,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: todayRate,
                                  strokeWidth: 11,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: AppTheme.background,
                                  valueColor: AlwaysStoppedAnimation(
                                    todayRate >= 0.8
                                        ? AppTheme.success
                                        : todayRate >= 0.5
                                            ? AppTheme.warning
                                            : AppTheme.error,
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(todayRate * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const Text('on track', style: AppTheme.caption),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _StatPill(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Taken',
                                  value:
                                      '${todayDoses.where((d) => d['status'] == 'taken').length}',
                                  color: AppTheme.success,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatPill(
                                  icon: Icons.access_time_filled_rounded,
                                  label: 'Pending',
                                  value:
                                      '${todayDoses.where((d) => d['status'] == 'pending').length}',
                                  color: AppTheme.warning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatPill(
                                  icon: Icons.cancel_rounded,
                                  label: 'Skipped',
                                  value:
                                      '${todayDoses.where((d) => d['status'] == 'skipped').length}',
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text("Today's schedule", style: AppTheme.titleMedium),
                    const SizedBox(height: 10),
                    if (todayDoses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.softShadow(opacity: 0.05),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.medication_outlined,
                                  color: AppTheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No medications scheduled today',
                                style: AppTheme.bodyMuted,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...todayDoses.map((dose) => _DoseCard(
                            dose: dose,
                            onRefresh: () => adherenceProvider.refreshData(),
                          )),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: color),
          ),
          Text(label, style: AppTheme.caption),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow(opacity: 0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose['medication_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${dose['dosage']} · ${dose['scheduled_time']}',
                  style: AppTheme.bodyMuted,
                ),
              ],
            ),
          ),
          if (dose['status'] == 'pending')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.check_rounded,
                  color: AppTheme.success,
                  onTap: () async {
                    await ApiService.markTaken(dose['id']);
                    onRefresh();
                  },
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.close_rounded,
                  color: AppTheme.error,
                  onTap: () async {
                    await ApiService.markSkipped(dose['id']);
                    onRefresh();
                  },
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                dose['status'].toString().toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
