// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:medtrack_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdherenceProvider extends ChangeNotifier {
  List<dynamic> _todayDoses = [];
  List<dynamic> _stats = [];
  bool _isLoading = false;

  List<dynamic> get todayDoses => _todayDoses;
  List<dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Since ApiService already enforces a List return type,
      // we can assign them directly! Keeping them separate prevents
      // the Future.wait type inference crash.
      _todayDoses = await ApiService.getAdherence();
      _stats = await ApiService.getAdherenceStats();
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

    _todayDoses = [];
    _stats = [];

    notifyListeners(); // Tells the UI everything is reset
  }
}
