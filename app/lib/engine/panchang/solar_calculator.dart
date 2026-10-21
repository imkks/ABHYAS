import 'dart:math';

/// High-precision offline solar calculation engine based on NOAA and
/// Jean Meeus astronomical algorithms.
class SolarCalculator {
  static const double _deg2rad = pi / 180.0;
  static const double _rad2deg = 180.0 / pi;

  /// Standard solar zenith angle for sunrise/sunset (90° 50' = 90.833°)
  /// includes atmospheric refraction (34') and solar disc semi-diameter (16').
  static const double standardZenith = 90.8333;

  /// Civil twilight zenith angle (96.0°)
  static const double civilZenith = 96.0;

  /// Nautical twilight zenith angle (102.0°)
  static const double nauticalZenith = 102.0;

  /// Astronomical twilight zenith angle (108.0°)
  static const double astronomicalZenith = 108.0;

  /// Calculates Julian Day from a UTC DateTime.
  static double getJulianDay(DateTime utcDate) {
    int year = utcDate.year;
    int month = utcDate.month;
    int day = utcDate.day;
    double hour = utcDate.hour +
        (utcDate.minute / 60.0) +
        (utcDate.second / 3600.0) +
        (utcDate.millisecond / 3600000.0);

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    int a = year ~/ 100;
    int b = 2 - a + (a ~/ 4);

    double jd = (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5 +
        (hour / 24.0);

    return jd;
  }

  /// Calculates Julian Century from Julian Day.
  static double getJulianCentury(double jd) {
    return (jd - 2451545.0) / 36525.0;
  }

  /// Normalizes angle to [0, 360) degrees.
  static double normalizeDegrees(double deg) {
    double res = deg % 360.0;
    if (res < 0) res += 360.0;
    return res;
  }

  /// Solar position parameters at Julian Day.
  static SolarCoordinates calculateSolarCoordinates(double jd) {
    final t = getJulianCentury(jd);

    // Geometric Mean Longitude of Sun (degrees)
    double l0 = 280.46646 + t * (36000.76983 + t * 0.0003032);
    l0 = normalizeDegrees(l0);

    // Mean Anomaly of Sun (degrees)
    double m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    m = normalizeDegrees(m);
    final mRad = m * _deg2rad;

    // Eccentricity of Earth's orbit
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

    // Sun Equation of Center (degrees)
    final c = sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        sin(2 * mRad) * (0.019993 - 0.000101 * t) +
        sin(3 * mRad) * 0.000289;

    // Sun True Longitude & Apparent Longitude
    final trueLongitude = normalizeDegrees(l0 + c);
    final omega = 125.04 - 1934.136 * t;
    final lambda = normalizeDegrees(
        trueLongitude - 0.00569 - 0.00478 * sin(omega * _deg2rad));

    // Mean Obliquity of Ecliptic (degrees)
    final eps0 = 23.0 +
        (26.0 +
                (21.448 -
                    t * (46.815 + t * (0.00059 - t * 0.001813))) /
                    60.0) /
            60.0;
    final epsilon = eps0 + 0.00256 * cos(omega * _deg2rad);

    final epsRad = epsilon * _deg2rad;
    final lambdaRad = lambda * _deg2rad;

    // Sun Declination
    final sinDecl = sin(epsRad) * sin(lambdaRad);
    final declinationRad = asin(sinDecl);
    final declinationDeg = declinationRad * _rad2deg;

    // Equation of Time (minutes of time)
    final y = tan(epsRad / 2.0) * tan(epsRad / 2.0);
    final l0Rad = l0 * _deg2rad;
    final eotRad = y * sin(2.0 * l0Rad) -
        2.0 * e * sin(mRad) +
        4.0 * e * y * sin(mRad) * cos(2.0 * l0Rad) -
        0.5 * y * y * sin(4.0 * l0Rad) -
        1.25 * e * e * sin(2.0 * mRad);
    final equationOfTimeMinutes = 4.0 * eotRad * _rad2deg;

    return SolarCoordinates(
      declinationDegrees: declinationDeg,
      equationOfTimeMinutes: equationOfTimeMinutes,
      trueLongitudeDegrees: trueLongitude,
      apparentLongitudeDegrees: lambda,
    );
  }

  /// Computes Sunrise, Sunset, and Solar Noon for a given calendar date and location.
  /// Resulting DateTime values are in the local timezone of the given date.
  static SolarDayResult calculateTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required double timezoneOffsetHours,
    double zenith = standardZenith,
  }) {
    // Reference date at UTC midnight of the target local date
    final localMidnightUtc = DateTime.utc(date.year, date.month, date.day);
    final jdNoon = getJulianDay(localMidnightUtc.add(const Duration(hours: 12)));

    // Approximate noon calculation
    final coordsApprox = calculateSolarCoordinates(jdNoon);
    final solarNoonUtcMinutes =
        720.0 - (4.0 * longitude) - coordsApprox.equationOfTimeMinutes;

    // Re-evaluate coordinates closer to actual solar noon for higher precision
    final jdExactNoon = jdNoon + (solarNoonUtcMinutes - 720.0) / 1440.0;
    final coords = calculateSolarCoordinates(jdExactNoon);

    final exactNoonUtcMinutes =
        720.0 - (4.0 * longitude) - coords.equationOfTimeMinutes;

    final latRad = latitude * _deg2rad;
    final declRad = coords.declinationDegrees * _deg2rad;
    final zenithRad = zenith * _deg2rad;

    // Hour angle H0: cos(H0) = (cos(zenith) - sin(lat)*sin(decl)) / (cos(lat)*cos(decl))
    final cosH0 = (cos(zenithRad) - sin(latRad) * sin(declRad)) /
        (cos(latRad) * cos(declRad));

    bool isPolarDay = false;
    bool isPolarNight = false;
    double? sunriseUtcMinutes;
    double? sunsetUtcMinutes;

    if (cosH0 > 1.0) {
      // Sun never rises (Polar night)
      isPolarNight = true;
    } else if (cosH0 < -1.0) {
      // Sun never sets (Polar day)
      isPolarDay = true;
    } else {
      final hourAngleDeg = acos(cosH0) * _rad2deg;
      final hourAngleMinutes = hourAngleDeg * 4.0;
      sunriseUtcMinutes = exactNoonUtcMinutes - hourAngleMinutes;
      sunsetUtcMinutes = exactNoonUtcMinutes + hourAngleMinutes;
    }

    DateTime minutesToLocalDate(double utcMinutes) {
      final totalLocalMinutes = (utcMinutes + (timezoneOffsetHours * 60.0)).round();
      return DateTime(
        date.year,
        date.month,
        date.day,
        0,
        0,
        0,
      ).add(Duration(minutes: totalLocalMinutes));
    }

    final solarNoonLocal = minutesToLocalDate(exactNoonUtcMinutes);
    DateTime? sunriseLocal =
        sunriseUtcMinutes != null ? minutesToLocalDate(sunriseUtcMinutes) : null;
    DateTime? sunsetLocal =
        sunsetUtcMinutes != null ? minutesToLocalDate(sunsetUtcMinutes) : null;

    // Fallbacks for extreme latitudes if polar day or night occurs
    if (isPolarDay) {
      sunriseLocal = DateTime(date.year, date.month, date.day, 0, 0);
      sunsetLocal = DateTime(date.year, date.month, date.day, 23, 59, 59);
    } else if (isPolarNight) {
      sunriseLocal = DateTime(date.year, date.month, date.day, 12, 0);
      sunsetLocal = DateTime(date.year, date.month, date.day, 12, 0);
    }

    final dayLength = sunsetLocal!.difference(sunriseLocal!);

    return SolarDayResult(
      date: DateTime(date.year, date.month, date.day),
      sunrise: sunriseLocal,
      sunset: sunsetLocal,
      solarNoon: solarNoonLocal,
      daylightDuration: dayLength,
      coords: coords,
      isPolarDay: isPolarDay,
      isPolarNight: isPolarNight,
    );
  }
}

class SolarCoordinates {
  final double declinationDegrees;
  final double equationOfTimeMinutes;
  final double trueLongitudeDegrees;
  final double apparentLongitudeDegrees;

  const SolarCoordinates({
    required this.declinationDegrees,
    required this.equationOfTimeMinutes,
    required this.trueLongitudeDegrees,
    required this.apparentLongitudeDegrees,
  });
}

class SolarDayResult {
  final DateTime date;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime solarNoon;
  final Duration daylightDuration;
  final SolarCoordinates coords;
  final bool isPolarDay;
  final bool isPolarNight;

  const SolarDayResult({
    required this.date,
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.daylightDuration,
    required this.coords,
    this.isPolarDay = false,
    this.isPolarNight = false,
  });

  Duration get nightDuration =>
      const Duration(hours: 24) - daylightDuration;
}
