import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'panchang_models.dart';
import 'panchang_engine.dart';

class BrahmaMuhurtaStatus {
  final bool isActive;
  final Duration timeRemainingOrUntil;
  final MuhurtaPeriod period;

  const BrahmaMuhurtaStatus({
    required this.isActive,
    required this.timeRemainingOrUntil,
    required this.period,
  });

  String get countdownString {
    final hours = timeRemainingOrUntil.inHours;
    final minutes = timeRemainingOrUntil.inMinutes.remainder(60);
    if (isActive) {
      return 'Active now · ends in ${hours > 0 ? '$hours h ' : ''}$minutes min';
    } else {
      if (hours > 0) {
        return 'in $hours h $minutes min';
      } else {
        return 'in $minutes min';
      }
    }
  }
}

/// Service managing Panchang state, caching, location persistence,
/// and live countdown formatting.
class PanchangService extends ChangeNotifier {
  static final PanchangService _instance = PanchangService._internal();
  factory PanchangService() => _instance;
  PanchangService._internal() {
    _loadSavedLocation();
  }

  static const String _locationPrefKey = 'panchang_saved_location';

  GeoLocation _currentLocation = GeoLocation.defaultLocation;
  final Map<String, DailyPanchang> _cache = {};
  bool _initialized = false;

  GeoLocation get currentLocation => _currentLocation;
  bool get isInitialized => _initialized;

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_locationPrefKey);
      if (savedJson != null) {
        final map = json.decode(savedJson) as Map<String, dynamic>;
        _currentLocation = GeoLocation.fromJson(map);
        _cache.clear();
      }
    } catch (_) {
      // Graceful fallback to default location if storage is inaccessible
    }
    _initialized = true;
    notifyListeners();
  }

  void setLocation(GeoLocation newLocation) {
    if (_currentLocation.name != newLocation.name ||
        _currentLocation.latitude != newLocation.latitude ||
        _currentLocation.longitude != newLocation.longitude) {
      _currentLocation = newLocation;
      _cache.clear();
      notifyListeners();
      _saveLocationToPrefs(newLocation);
    }
  }

  Future<void> _saveLocationToPrefs(GeoLocation loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _locationPrefKey, json.encode(loc.toJson()));
    } catch (_) {}
  }

  /// Sets a custom location from exact latitude and longitude coordinates.
  void setCustomCoordinates({
    required double latitude,
    required double longitude,
    String? name,
    double? timezoneOffsetHours,
    double elevationMeters = 0.0,
  }) {
    final customLoc = GeoLocation.custom(
      latitude: latitude,
      longitude: longitude,
      name: name,
      timezoneOffsetHours: timezoneOffsetHours,
      elevationMeters: elevationMeters,
    );
    setLocation(customLoc);
  }

  String _cacheKey(DateTime date, GeoLocation loc) {
    return '${date.year}-${date.month}-${date.day}_${loc.latitude}_${loc.longitude}';
  }

  DailyPanchang getPanchangFor(DateTime date, [GeoLocation? location]) {
    final loc = location ?? _currentLocation;
    final key = _cacheKey(date, loc);
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final calculated = PanchangEngine.calculateDailyPanchang(
      date: date,
      location: loc,
    );
    _cache[key] = calculated;
    return calculated;
  }

  DailyPanchang getTodayPanchang([GeoLocation? location]) {
    return getPanchangFor(DateTime.now(), location);
  }

  /// Calculates Brahma Muhurta status relative to current timestamp.
  BrahmaMuhurtaStatus getBrahmaMuhurtaStatus([DateTime? nowTime, GeoLocation? location]) {
    final now = nowTime ?? DateTime.now();
    final todayPanchang = getTodayPanchang(location);
    final brahma = todayPanchang.brahmaMuhurta;

    if (now.isAfter(brahma.startTime) && now.isBefore(brahma.endTime)) {
      // Active right now!
      final remaining = brahma.endTime.difference(now);
      return BrahmaMuhurtaStatus(
        isActive: true,
        timeRemainingOrUntil: remaining,
        period: brahma,
      );
    }

    if (now.isBefore(brahma.startTime)) {
      // Upcoming today
      final until = brahma.startTime.difference(now);
      return BrahmaMuhurtaStatus(
        isActive: false,
        timeRemainingOrUntil: until,
        period: brahma,
      );
    }

    // Has already passed today; compute for tomorrow's dawn
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowPanchang = getPanchangFor(tomorrow, location);
    final tomorrowBrahma = tomorrowPanchang.brahmaMuhurta;
    final untilTomorrow = tomorrowBrahma.startTime.difference(now);

    return BrahmaMuhurtaStatus(
      isActive: false,
      timeRemainingOrUntil: untilTomorrow,
      period: tomorrowBrahma,
    );
  }

  static String formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final standardHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$standardHour:$minute $period';
  }

  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
