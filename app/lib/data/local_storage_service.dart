import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _checkinsKey = 'session_checkins';

  Future<void> saveCheckin(Map<String, dynamic> checkinData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> checkins = prefs.getStringList(_checkinsKey) ?? [];

    checkins.add(json.encode(checkinData));
    await prefs.setStringList(_checkinsKey, checkins);
  }

  Future<List<Map<String, dynamic>>> getCheckins() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> checkins = prefs.getStringList(_checkinsKey) ?? [];

    return checkins.map((str) => json.decode(str) as Map<String, dynamic>).toList();
  }
}
