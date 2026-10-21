import 'package:flutter/material.dart';

/// Geographical location representing user's or selected city's coordinates.
class GeoLocation {
  final String name;
  final String stateOrCountry;
  final double latitude;
  final double longitude;
  final double timezoneOffsetHours;
  final double elevationMeters;

  const GeoLocation({
    required this.name,
    required this.stateOrCountry,
    required this.latitude,
    required this.longitude,
    required this.timezoneOffsetHours,
    this.elevationMeters = 0.0,
  });

  /// Predefined sacred and major reference locations.
  static const List<GeoLocation> sacredCities = [
    GeoLocation(
      name: 'Varanasi (Kashi)',
      stateOrCountry: 'Uttar Pradesh, Bharat',
      latitude: 25.3176,
      longitude: 82.9739,
      timezoneOffsetHours: 5.5,
      elevationMeters: 80.0,
    ),
    GeoLocation(
      name: 'Rishikesh (Devabhumi)',
      stateOrCountry: 'Uttarakhand, Bharat',
      latitude: 30.0869,
      longitude: 78.2676,
      timezoneOffsetHours: 5.5,
      elevationMeters: 340.0,
    ),
    GeoLocation(
      name: 'Ujjain (Mahakal)',
      stateOrCountry: 'Madhya Pradesh, Bharat',
      latitude: 23.1765,
      longitude: 75.7885,
      timezoneOffsetHours: 5.5,
      elevationMeters: 494.0,
    ),
    GeoLocation(
      name: 'Haridwar',
      stateOrCountry: 'Uttarakhand, Bharat',
      latitude: 29.9457,
      longitude: 78.1642,
      timezoneOffsetHours: 5.5,
      elevationMeters: 314.0,
    ),
    GeoLocation(
      name: 'Tirupati',
      stateOrCountry: 'Andhra Pradesh, Bharat',
      latitude: 13.6288,
      longitude: 79.4192,
      timezoneOffsetHours: 5.5,
      elevationMeters: 182.0,
    ),
    GeoLocation(
      name: 'Pune',
      stateOrCountry: 'Maharashtra, Bharat',
      latitude: 18.5204,
      longitude: 73.8567,
      timezoneOffsetHours: 5.5,
      elevationMeters: 560.0,
    ),
    GeoLocation(
      name: 'New Delhi',
      stateOrCountry: 'Delhi, Bharat',
      latitude: 28.6139,
      longitude: 77.2090,
      timezoneOffsetHours: 5.5,
      elevationMeters: 216.0,
    ),
    GeoLocation(
      name: 'Bengaluru',
      stateOrCountry: 'Karnataka, Bharat',
      latitude: 12.9716,
      longitude: 77.5946,
      timezoneOffsetHours: 5.5,
      elevationMeters: 920.0,
    ),
    GeoLocation(
      name: 'Mumbai',
      stateOrCountry: 'Maharashtra, Bharat',
      latitude: 19.0760,
      longitude: 72.8777,
      timezoneOffsetHours: 5.5,
      elevationMeters: 14.0,
    ),
    GeoLocation(
      name: 'Chennai',
      stateOrCountry: 'Tamil Nadu, Bharat',
      latitude: 13.0827,
      longitude: 80.2707,
      timezoneOffsetHours: 5.5,
      elevationMeters: 6.0,
    ),
    GeoLocation(
      name: 'Kolkata',
      stateOrCountry: 'West Bengal, Bharat',
      latitude: 22.5726,
      longitude: 88.3639,
      timezoneOffsetHours: 5.5,
      elevationMeters: 9.0,
    ),
    GeoLocation(
      name: 'Kathmandu (Pashupatinath)',
      stateOrCountry: 'Nepal',
      latitude: 27.7172,
      longitude: 85.3240,
      timezoneOffsetHours: 5.75,
      elevationMeters: 1400.0,
    ),
    GeoLocation(
      name: 'London',
      stateOrCountry: 'United Kingdom',
      latitude: 51.5074,
      longitude: -0.1278,
      timezoneOffsetHours: 0.0,
      elevationMeters: 11.0,
    ),
    GeoLocation(
      name: 'New York',
      stateOrCountry: 'USA',
      latitude: 40.7128,
      longitude: -74.0060,
      timezoneOffsetHours: -5.0,
      elevationMeters: 10.0,
    ),
    GeoLocation(
      name: 'San Francisco',
      stateOrCountry: 'USA',
      latitude: 37.7749,
      longitude: -122.4194,
      timezoneOffsetHours: -8.0,
      elevationMeters: 16.0,
    ),
    GeoLocation(
      name: 'Tokyo',
      stateOrCountry: 'Japan',
      latitude: 35.6762,
      longitude: 139.6503,
      timezoneOffsetHours: 9.0,
      elevationMeters: 40.0,
    ),
    GeoLocation(
      name: 'Sydney',
      stateOrCountry: 'Australia',
      latitude: -33.8688,
      longitude: 151.2093,
      timezoneOffsetHours: 10.0,
      elevationMeters: 19.0,
    ),
  ];

  static GeoLocation get defaultLocation => sacredCities[0]; // Varanasi

  Map<String, dynamic> toJson() => {
        'name': name,
        'stateOrCountry': stateOrCountry,
        'latitude': latitude,
        'longitude': longitude,
        'timezoneOffsetHours': timezoneOffsetHours,
        'elevationMeters': elevationMeters,
      };

  factory GeoLocation.fromJson(Map<String, dynamic> json) => GeoLocation(
        name: json['name'] as String,
        stateOrCountry: json['stateOrCountry'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezoneOffsetHours: (json['timezoneOffsetHours'] as num).toDouble(),
        elevationMeters: (json['elevationMeters'] as num?)?.toDouble() ?? 0.0,
      );
}

enum Paksha {
  shukla,
  krishna,
}

/// 1. Tithi (Lunar Day)
class TithiInfo {
  final int number; // 1 to 30
  final String name; // e.g., 'Ekadashi'
  final String sanskritName; // 'एकादशी'
  final Paksha paksha;
  final String deity;
  final bool isEkadashi;
  final bool isPurnima;
  final bool isAmavasya;
  final bool isPradosha;
  final String spiritualSignificance;

  const TithiInfo({
    required this.number,
    required this.name,
    required this.sanskritName,
    required this.paksha,
    required this.deity,
    this.isEkadashi = false,
    this.isPurnima = false,
    this.isAmavasya = false,
    this.isPradosha = false,
    required this.spiritualSignificance,
  });

  String get pakshaName =>
      paksha == Paksha.shukla ? 'Shukla Paksha' : 'Krishna Paksha';
  String get pakshaSanskrit =>
      paksha == Paksha.shukla ? 'शुक्ल पक्ष' : 'कृष्ण पक्ष';

  String get fullTitle => '$name ($pakshaName)';
  String get fullSanskritTitle => '$sanskritName ($pakshaSanskrit)';
}

/// 2. Vara (Day of the Week)
class VaraInfo {
  final int weekdayNumber; // 1 = Monday to 7 = Sunday
  final String sanskritName; // e.g., Ravivara, Somavara
  final String englishDay; // Sunday, Monday, etc.
  final String rulingGraha; // Surya, Chandra, Mangala, etc.
  final String element; // Agni, Jala, Prithvi, Vayu, Akasha
  final String energeticQuality;

  const VaraInfo({
    required this.weekdayNumber,
    required this.sanskritName,
    required this.englishDay,
    required this.rulingGraha,
    required this.element,
    required this.energeticQuality,
  });
}

/// 3. Nakshatra (Lunar Mansion)
class NakshatraInfo {
  final int number; // 1 to 27
  final String name; // Ashwini, Bharani, etc.
  final String sanskritName;
  final int pada; // 1 to 4
  final String rulingGraha;
  final String deity;
  final String guna; // Sattva, Rajas, Tamas
  final String yogicGuidance;

  const NakshatraInfo({
    required this.number,
    required this.name,
    required this.sanskritName,
    required this.pada,
    required this.rulingGraha,
    required this.deity,
    required this.guna,
    required this.yogicGuidance,
  });
}

/// 4. Yoga (Luni-Solar Angle Combination)
class YogaInfo {
  final int number; // 1 to 27
  final String name; // Vishkambha, Priti, etc.
  final String sanskritName;
  final bool isAuspicious;
  final String meaning;

  const YogaInfo({
    required this.number,
    required this.name,
    required this.sanskritName,
    required this.isAuspicious,
    required this.meaning,
  });
}

/// 5. Karana (Half Tithi)
class KaranaInfo {
  final int cyclicNumber; // 1 to 11
  final String name; // Bava, Balava, Kaulava, etc.
  final String sanskritName;
  final bool isMovable;
  final String quality;

  const KaranaInfo({
    required this.cyclicNumber,
    required this.name,
    required this.sanskritName,
    required this.isMovable,
    required this.quality,
  });
}

enum MuhurtaType {
  auspicious,
  inauspicious,
  neutral,
  spiritualPeak,
}

/// Sacred or significant time window of the day.
class MuhurtaPeriod {
  final String name;
  final String sanskritName;
  final DateTime startTime;
  final DateTime endTime;
  final MuhurtaType type;
  final String description;
  final String yogicPractice;

  const MuhurtaPeriod({
    required this.name,
    required this.sanskritName,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.description,
    required this.yogicPractice,
  });

  bool isCurrent(DateTime now) =>
      now.isAfter(startTime) && now.isBefore(endTime);

  Duration duration(DateTime now) => endTime.difference(startTime);

  Duration timeUntilStart(DateTime now) => startTime.difference(now);
}

enum ChoghadiyaNature {
  amrit, // Immortal / Supreme
  shubh, // Auspicious
  labh, // Profitable
  char, // Neutral / Movement
  rog, // Disease / Inauspicious
  kaal, // Destruction / Inauspicious
  udveg, // Anxiety / Inauspicious
}

class ChoghadiyaPeriod {
  final String name;
  final String sanskritName;
  final String rulerGraha;
  final ChoghadiyaNature nature;
  final bool isDaytime;
  final DateTime startTime;
  final DateTime endTime;

  const ChoghadiyaPeriod({
    required this.name,
    required this.sanskritName,
    required this.rulerGraha,
    required this.nature,
    required this.isDaytime,
    required this.startTime,
    required this.endTime,
  });

  bool isCurrent(DateTime now) =>
      now.isAfter(startTime) && now.isBefore(endTime);

  bool get isAuspicious =>
      nature == ChoghadiyaNature.amrit ||
      nature == ChoghadiyaNature.shubh ||
      nature == ChoghadiyaNature.labh;

  Color get color {
    switch (nature) {
      case ChoghadiyaNature.amrit:
        return const Color(0xFFE89A47); // Saffron
      case ChoghadiyaNature.shubh:
        return const Color(0xFF86A882); // Leaf green
      case ChoghadiyaNature.labh:
        return const Color(0xFF7FA3C0); // Sky blue
      case ChoghadiyaNature.char:
        return const Color(0xFFA68BC4); // Lavender/Hold
      case ChoghadiyaNature.udveg:
        return const Color(0xFFD77E66); // Clay
      case ChoghadiyaNature.rog:
      case ChoghadiyaNature.kaal:
        return const Color(0xFFCF6679); // Coral Red
    }
  }

  String get natureLabel {
    switch (nature) {
      case ChoghadiyaNature.amrit:
        return 'Amrit (Supreme)';
      case ChoghadiyaNature.shubh:
        return 'Shubh (Auspicious)';
      case ChoghadiyaNature.labh:
        return 'Labh (Beneficial)';
      case ChoghadiyaNature.char:
        return 'Char (Neutral)';
      case ChoghadiyaNature.udveg:
        return 'Udveg (Restless)';
      case ChoghadiyaNature.rog:
        return 'Rog (Adverse)';
      case ChoghadiyaNature.kaal:
        return 'Kaal (Restraint)';
    }
  }
}

enum ActiveNadi {
  ida, // Lunar (left nostril)
  pingala, // Solar (right nostril)
  sushumna, // Central channel
}

/// Svara Yoga practice guidance based on Shiva Svarodaya.
class SvaraRecommendation {
  final ActiveNadi idealNadi;
  final String dominantElement;
  final List<String> recommendedPranayamas;
  final String guidance;

  const SvaraRecommendation({
    required this.idealNadi,
    required this.dominantElement,
    required this.recommendedPranayamas,
    required this.guidance,
  });

  String get nadiName {
    switch (idealNadi) {
      case ActiveNadi.ida:
        return 'Ida Nadi (Chandra / Left)';
      case ActiveNadi.pingala:
        return 'Pingala Nadi (Surya / Right)';
      case ActiveNadi.sushumna:
        return 'Sushumna Nadi (Central / Both)';
    }
  }
}

/// Aggregated Panchang for a single calendar day at a specific location.
class DailyPanchang {
  final DateTime date;
  final GeoLocation location;
  final TithiInfo tithi;
  final VaraInfo vara;
  final NakshatraInfo nakshatra;
  final YogaInfo yoga;
  final KaranaInfo karana;

  // Astronomical Times
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime solarNoon;
  final Duration daylightDuration;
  final Duration nightDuration;

  // Key Muhurtas
  final MuhurtaPeriod brahmaMuhurta;
  final MuhurtaPeriod abhijitMuhurta;
  final MuhurtaPeriod pratahSandhya;
  final MuhurtaPeriod madhyahnaSandhya;
  final MuhurtaPeriod sayamSandhya;

  // Inauspicious Kala windows
  final MuhurtaPeriod rahuKalam;
  final MuhurtaPeriod yamaGandam;
  final MuhurtaPeriod gulikaKalam;

  // Choghadiya
  final List<ChoghadiyaPeriod> dayChoghadiya;
  final List<ChoghadiyaPeriod> nightChoghadiya;

  // Svara Yoga & Practice
  final SvaraRecommendation svaraRecommendation;

  const DailyPanchang({
    required this.date,
    required this.location,
    required this.tithi,
    required this.vara,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.daylightDuration,
    required this.nightDuration,
    required this.brahmaMuhurta,
    required this.abhijitMuhurta,
    required this.pratahSandhya,
    required this.madhyahnaSandhya,
    required this.sayamSandhya,
    required this.rahuKalam,
    required this.yamaGandam,
    required this.gulikaKalam,
    required this.dayChoghadiya,
    required this.nightChoghadiya,
    required this.svaraRecommendation,
  });

  /// Check which key muhurta is active currently.
  MuhurtaPeriod? getCurrentMuhurta(DateTime now) {
    final list = [
      brahmaMuhurta,
      pratahSandhya,
      abhijitMuhurta,
      madhyahnaSandhya,
      sayamSandhya,
      rahuKalam,
      yamaGandam,
      gulikaKalam,
    ];
    for (var m in list) {
      if (m.isCurrent(now)) return m;
    }
    return null;
  }

  /// Check which Choghadiya is active currently.
  ChoghadiyaPeriod? getCurrentChoghadiya(DateTime now) {
    for (var c in dayChoghadiya) {
      if (c.isCurrent(now)) return c;
    }
    for (var c in nightChoghadiya) {
      if (c.isCurrent(now)) return c;
    }
    return null;
  }
}
