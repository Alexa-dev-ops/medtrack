import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdherenceScreen extends StatefulWidget {
  const AdherenceScreen({super.key});

  @override
  State<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  List<dynamic> _stats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await ApiService.getAdherenceStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _rateColor(double rate) {
    if (rate >= 0.8) return AppTheme.success;
    if (rate >= 0.5) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.softShadow(opacity: 0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('7-day adherence overview',
                    style: AppTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'How consistently doses were taken on time',
                  style: AppTheme.bodyMuted,
                ),
                const SizedBox(height: 20),
                if (_stats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              size: 30,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No data yet — add medications to\nstart tracking adherence.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._stats.map((s) {
                    final total = s['total'] as int;
                    final taken = s['taken'] as int;
                    final rate = total > 0 ? taken / total : 0.0;
                    final color = _rateColor(rate);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s['date'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${(rate * 100).toInt()}%',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: rate,
                              minHeight: 9,
                              backgroundColor: AppTheme.background,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$taken taken · ${s['skipped']} skipped · ${s['pending']} pending',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
