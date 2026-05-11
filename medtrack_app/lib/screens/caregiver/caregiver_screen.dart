import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  List<dynamic> _patients = [];
  bool _loading = true;
  String _myCode = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await ApiService.getMe();
      final patients = await ApiService.getPatients();
      setState(() {
        _patients = patients;
        _myCode = me['caregiver_code'] ?? '';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _viewPatient(Map patient) async {
    final logs = await ApiService.getPatientAdherence(patient['id']);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "${patient['name']}'s Today Schedule",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No medications scheduled today',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: logs.length,
                      itemBuilder: (_, i) {
                        final l = logs[i];
                        final color = l['status'] == 'taken'
                            ? AppTheme.success
                            : l['status'] == 'skipped'
                                ? AppTheme.error
                                : AppTheme.warning;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color..withValues(alpha: 0.1),
                            child:
                                Icon(Icons.medication, color: color, size: 20),
                          ),
                          title: Text(l['medication_name']),
                          subtitle:
                              Text('${l['dosage']} · ${l['scheduled_time']}'),
                          trailing: Chip(
                            label: Text(
                              l['status'].toString().toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white),
                            ),
                            backgroundColor: color,
                            padding: EdgeInsets.zero,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Patients')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Caregiver code card
                  Card(
                    color: AppTheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Caregiver Code',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _myCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon:
                                    const Icon(Icons.copy, color: Colors.white),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: _myCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Code copied to clipboard!')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Text(
                            'Share this code with your patient to link accounts',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Linked Patients',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (_patients.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No patients linked yet.\nShare your code with a patient to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._patients.map((p) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primary..withValues(alpha: 0.1),
                              child: Text(
                                p['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              p['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(p['email']),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility_outlined,
                                  color: AppTheme.primary),
                              onPressed: () => _viewPatient(p),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
