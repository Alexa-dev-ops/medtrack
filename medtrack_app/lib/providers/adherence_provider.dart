// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:medtrack_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdherenceProvider extends ChangeNotifier {
  List<dynamic> _todayLogs = [];
  List<dynamic> _stats = [];
  bool _isLoading = false;

  List<dynamic> get todayLogs => _todayLogs;
  List<dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  // This one function refreshes EVERYTHING
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch both simultaneously for speed
      final results = await Future.wait([
        ApiService.getAdherence(),
        ApiService.getAdherenceStats(),
      ]);

      _todayLogs = results[0];
      _stats = results[1];
    } catch (e) {
      print("Update Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // This tells all screens to rebuild!
    }
  }

  Future<void> markAsTaken(int id) async {
    await ApiService.markTaken(id);
    await refreshData(); // Auto-refresh stats after taking a pill
  }
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 

    _todayLogs = [];
    _stats = [];

    notifyListeners(); // Tells the UI everything is reset
  }
}

