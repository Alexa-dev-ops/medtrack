import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'tablet';
  String _frequency = 'Once daily';
  final List<String> _times = ['08:00'];
  DateTime _startDate = DateTime.now();
  bool _loading = false;

  final _types = ['tablet', 'syrup', 'injection', 'capsule'];
  final _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every 8 hours',
    'As needed',
  ];

  void _addTime() async {
    final t =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      setState(() => _times.add(
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          ));
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _dosageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and dosage are required')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.addMedication({
        'name': _nameCtrl.text.trim(),
        'dosage': _dosageCtrl.text.trim(),
        'type': _type,
        'frequency': _frequency,
        'times': _times,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'notes': _notesCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Medication Name*',
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 500mg)*',
                prefixIcon: Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Medication Type',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types
                  .map((t) => ChoiceChip(
                        label: Text(t[0].toUpperCase() + t.substring(1)),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: _type == t
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: _frequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reminder Times',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                TextButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Time'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: _times
                  .map((t) => Chip(
                        label: Text(t),
                        onDeleted: _times.length > 1
                            ? () => setState(() => _times.remove(t))
                            : null,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.calendar_today, color: AppTheme.primary),
              title: const Text('Start Date'),
              subtitle: Text(_startDate.toIso8601String().split('T')[0]),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Medication'),
            ),
          ],
        ),
      ),
    );
  }
}
