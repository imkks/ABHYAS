import 'package:flutter_test/flutter_test.dart';
import 'package:abhyas/engine/panchang/solar_calculator.dart';
import 'package:abhyas/engine/panchang/panchang_models.dart';
import 'package:abhyas/engine/panchang/panchang_engine.dart';
import 'package:abhyas/engine/panchang/panchang_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhyas/core/location_service.dart';

void main() {
  group('SolarCalculator Astronomical Engine Tests', () {
    test('Julian Day calculation matches astronomical epoch J2000.0', () {
      final epoch = DateTime.utc(2000, 1, 1, 12, 0, 0);
      final jd = SolarCalculator.getJulianDay(epoch);
      expect(jd, closeTo(2451545.0, 0.0001));
    });

    test('Solar calculation for Varanasi produces valid astronomical sequence', () {
      final varanasi = GeoLocation.sacredCities[0];
      final date = DateTime(2026, 3, 21); // Equinox
      final solar = SolarCalculator.calculateTimes(
        date: date,
        latitude: varanasi.latitude,
        longitude: varanasi.longitude,
        timezoneOffsetHours: varanasi.timezoneOffsetHours,
      );

      // Sunrise must be before Solar Noon, and Solar Noon before Sunset
      expect(solar.sunrise.isBefore(solar.solarNoon), isTrue);
      expect(solar.solarNoon.isBefore(solar.sunset), isTrue);

      // Equinox daylight in Varanasi is ~12 hours (within 15 min due to refraction/lat)
      expect(solar.daylightDuration.inMinutes, closeTo(720, 25));

      // Day + Night equals 24 hours
      final totalDayNight = solar.daylightDuration + solar.nightDuration;
      expect(totalDayNight.inMinutes, equals(1440));
    });

    test('Solar calculation works across solstices and multiple sacred latitudes', () {
      final cities = [
        GeoLocation.sacredCities[0], // Varanasi
        GeoLocation.sacredCities[1], // Rishikesh
        GeoLocation.sacredCities[2], // Ujjain
        GeoLocation.sacredCities[11], // Kathmandu
      ];

      final dates = [
        DateTime(2026, 6, 21), // Summer Solstice
        DateTime(2026, 12, 21), // Winter Solstice
      ];

      for (var city in cities) {
        for (var date in dates) {
          final res = SolarCalculator.calculateTimes(
            date: date,
            latitude: city.latitude,
            longitude: city.longitude,
            timezoneOffsetHours: city.timezoneOffsetHours,
          );

          expect(res.sunrise.isBefore(res.sunset), isTrue);
          expect(res.daylightDuration.inMinutes, greaterThan(600)); // > 10 hours
          expect(res.daylightDuration.inMinutes, lessThan(900)); // < 15 hours
        }
      }
    });
  });

  group('PanchangEngine 5 Limbs (Pancha-Anga) Tests', () {
    final location = GeoLocation.sacredCities[0]; // Varanasi

    test('Tithi calculations adhere to classical 30-tithi scheme', () {
      // Test 30 consecutive days to cover a full lunar cycle
      final start = DateTime(2026, 1, 1);
      final observedTithis = <int>{};

      for (int i = 0; i < 35; i++) {
        final date = start.add(Duration(days: i));
        final panchang = PanchangEngine.calculateDailyPanchang(
          date: date,
          location: location,
        );

        final tithi = panchang.tithi;
        expect(tithi.number, inInclusiveRange(1, 30));
        expect(tithi.name.isNotEmpty, isTrue);
        expect(tithi.sanskritName.isNotEmpty, isTrue);
        expect(tithi.deity.isNotEmpty, isTrue);

        if (tithi.number <= 15) {
          expect(tithi.paksha, equals(Paksha.shukla));
        } else {
          expect(tithi.paksha, equals(Paksha.krishna));
        }

        if (tithi.number == 11 || tithi.number == 26) {
          expect(tithi.isEkadashi, isTrue);
        }
        if (tithi.number == 15) {
          expect(tithi.isPurnima, isTrue);
        }
        if (tithi.number == 30) {
          expect(tithi.isAmavasya, isTrue);
        }

        observedTithis.add(tithi.number);
      }

      // Over 35 days, we should have seen at least 25 distinct tithis
      expect(observedTithis.length, greaterThan(25));
    });

    test('Vara calculation maps correctly to 7 weekdays and Sanskrit names', () {
      final daysOfWeek = [
        DateTime(2026, 10, 19), // Monday
        DateTime(2026, 10, 20), // Tuesday
        DateTime(2026, 10, 21), // Wednesday
        DateTime(2026, 10, 22), // Thursday
        DateTime(2026, 10, 23), // Friday
        DateTime(2026, 10, 24), // Saturday
        DateTime(2026, 10, 25), // Sunday
      ];

      final expectedSanskrit = [
        'Somavara',
        'Mangalavara',
        'Budhavara',
        'Guruvara',
        'Shukravara',
        'Shanivara',
        'Ravivara',
      ];

      for (int i = 0; i < 7; i++) {
        final p = PanchangEngine.calculateDailyPanchang(
          date: daysOfWeek[i],
          location: location,
        );
        expect(p.vara.sanskritName, equals(expectedSanskrit[i]));
        expect(p.vara.weekdayNumber, equals(i + 1));
        expect(p.vara.rulingGraha.isNotEmpty, isTrue);
        expect(p.vara.element.isNotEmpty, isTrue);
      }
    });

    test('Nakshatra, Yoga, and Karana stay strictly within canonical ranges', () {
      for (int i = 0; i < 30; i++) {
        final date = DateTime(2026, 5, 1).add(Duration(days: i));
        final p = PanchangEngine.calculateDailyPanchang(
          date: date,
          location: location,
        );

        // Nakshatra: 1..27, Pada: 1..4
        expect(p.nakshatra.number, inInclusiveRange(1, 27));
        expect(p.nakshatra.pada, inInclusiveRange(1, 4));
        expect(p.nakshatra.name.isNotEmpty, isTrue);
        expect(p.nakshatra.guna, isIn(['Sattva', 'Rajas', 'Tamas']));

        // Yoga: 1..27
        expect(p.yoga.number, inInclusiveRange(1, 27));
        expect(p.yoga.name.isNotEmpty, isTrue);

        // Karana: 1..11
        expect(p.karana.cyclicNumber, inInclusiveRange(1, 11));
        expect(p.karana.name.isNotEmpty, isTrue);
      }
    });
  });

  group('Sacred Muhurtas & Kaala Windows Tests', () {
    final location = GeoLocation.sacredCities[0]; // Varanasi
    final testDate = DateTime(2026, 10, 20);
    late DailyPanchang panchang;

    setUp(() {
      panchang = PanchangEngine.calculateDailyPanchang(
        date: testDate,
        location: location,
      );
    });

    test('Brahma Muhurta adheres precisely to 14th night muhurta rule', () {
      final brahma = panchang.brahmaMuhurta;
      final sunrise = panchang.sunrise;

      // Must end before sunrise
      expect(brahma.endTime.isBefore(sunrise), isTrue);
      // Must start before it ends
      expect(brahma.startTime.isBefore(brahma.endTime), isTrue);

      // Duration must be approximately 48 minutes (between 40 and 56 min based on night scaling)
      final durationMinutes = brahma.endTime.difference(brahma.startTime).inMinutes;
      expect(durationMinutes, closeTo(48, 8));

      // End time is exactly 1 night muhurta before sunrise
      final gapToEnd = sunrise.difference(brahma.endTime).inMinutes;
      expect(gapToEnd, closeTo(48, 8));

      // Start time is exactly 2 night muhurtas before sunrise
      final gapToStart = sunrise.difference(brahma.startTime).inMinutes;
      expect(gapToStart, closeTo(96, 16));
    });

    test('Sandhya Kaalas and Abhijit Muhurta boundaries are consistent', () {
      // Pratah Sandhya spans around sunrise
      expect(panchang.pratahSandhya.startTime.isBefore(panchang.sunrise), isTrue);
      expect(panchang.pratahSandhya.endTime.isAfter(panchang.sunrise), isTrue);

      // Sayam Sandhya spans around sunset
      expect(panchang.sayamSandhya.startTime.isBefore(panchang.sunset), isTrue);
      expect(panchang.sayamSandhya.endTime.isAfter(panchang.sunset), isTrue);

      // Abhijit Muhurta is centered around solar noon
      expect(panchang.abhijitMuhurta.startTime.isBefore(panchang.solarNoon), isTrue);
      expect(panchang.abhijitMuhurta.endTime.isAfter(panchang.solarNoon), isTrue);
    });

    test('Rahu Kalam, Yama Gandam, and Gulika Kalam follow 8-part daytime partition', () {
      final days = [
        DateTime(2026, 10, 19), // Mon
        DateTime(2026, 10, 20), // Tue
        DateTime(2026, 10, 21), // Wed
        DateTime(2026, 10, 22), // Thu
        DateTime(2026, 10, 23), // Fri
        DateTime(2026, 10, 24), // Sat
        DateTime(2026, 10, 25), // Sun
      ];

      for (var d in days) {
        final p = PanchangEngine.calculateDailyPanchang(date: d, location: location);
        final kalas = [p.rahuKalam, p.yamaGandam, p.gulikaKalam];

        for (var k in kalas) {
          expect(k.startTime.isAfter(p.sunrise) || k.startTime.isAtSameMomentAs(p.sunrise), isTrue);
          expect(k.endTime.isBefore(p.sunset) || k.endTime.isAtSameMomentAs(p.sunset), isTrue);
          expect(k.startTime.isBefore(k.endTime), isTrue);

          // 1/8th of daylight is ~90 minutes
          final duration = k.endTime.difference(k.startTime).inMinutes;
          expect(duration, closeTo(90, 15));
        }
      }
    });

    test('Choghadiya contains 8 contiguous day segments and 8 contiguous night segments', () {
      expect(panchang.dayChoghadiya.length, equals(8));
      expect(panchang.nightChoghadiya.length, equals(8));

      // Day Choghadiya starts at sunrise and ends at sunset
      expect(panchang.dayChoghadiya.first.startTime.difference(panchang.sunrise).inMinutes.abs(), lessThanOrEqualTo(1));
      expect(panchang.dayChoghadiya.last.endTime.difference(panchang.sunset).inMinutes.abs(), lessThanOrEqualTo(1));

      // Night Choghadiya starts at sunset
      expect(panchang.nightChoghadiya.first.startTime.difference(panchang.sunset).inMinutes.abs(), lessThanOrEqualTo(1));

      // Contiguity: each period connects to the next
      for (int i = 0; i < 7; i++) {
        expect(panchang.dayChoghadiya[i].endTime, equals(panchang.dayChoghadiya[i + 1].startTime));
        expect(panchang.nightChoghadiya[i].endTime, equals(panchang.nightChoghadiya[i + 1].startTime));
      }
    });

    test('Svara Yoga recommendation provides matching pranayama for active Nadi', () {
      final svara = panchang.svaraRecommendation;
      expect(svara.dominantElement.isNotEmpty, isTrue);
      expect(svara.recommendedPranayamas.isNotEmpty, isTrue);
      expect(svara.guidance.isNotEmpty, isTrue);

      if (svara.idealNadi == ActiveNadi.ida) {
        expect(svara.recommendedPranayamas, contains('Nadi Shodhana'));
      } else {
        expect(svara.recommendedPranayamas, contains('Kapalbhati'));
      }
    });
  });

  group('PanchangService State & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('PanchangService is singleton and caches repeated calculations', () {
      final service1 = PanchangService();
      final service2 = PanchangService();
      expect(identical(service1, service2), isTrue);

      final date = DateTime(2026, 8, 15);
      final p1 = service1.getPanchangFor(date);
      final p2 = service2.getPanchangFor(date);

      // Caching check: identical instance returned
      expect(identical(p1, p2), isTrue);
    });

    test('PanchangService location updates clear cache and notify listeners', () {
      final service = PanchangService();
      final initialCity = service.currentLocation;
      final newCity = GeoLocation.sacredCities[1]; // Rishikesh

      bool notified = false;
      void listener() {
        notified = true;
      }

      service.addListener(listener);
      service.setLocation(newCity);

      expect(service.currentLocation.name, equals(newCity.name));
      expect(notified, isTrue);

      // Revert to initial city
      service.setLocation(initialCity);
      service.removeListener(listener);
    });

    test('Brahma Muhurta countdown returns formatted string correctly', () {
      final service = PanchangService();
      final now = DateTime.now();
      final status = service.getBrahmaMuhurtaStatus(now);

      expect(status.countdownString.isNotEmpty, isTrue);
      expect(status.period.name, equals('Brahma Muhurta'));
    });

    test('Custom arbitrary coordinates compute accurate Panchang and format correctly', () {
      final kailash = GeoLocation.custom(
        latitude: 31.0667,
        longitude: 81.3119,
        name: 'Mount Kailash',
        timezoneOffsetHours: 5.75,
      );

      expect(kailash.isCustom, isTrue);
      expect(kailash.formattedCoordinates, equals('31.07° N, 81.31° E'));

      final date = DateTime(2026, 7, 15);
      final p = PanchangEngine.calculateDailyPanchang(date: date, location: kailash);

      expect(p.location.name, equals('Mount Kailash'));
      expect(p.sunrise.isBefore(p.sunset), isTrue);
      expect(p.brahmaMuhurta.endTime.isBefore(p.sunrise), isTrue);
      expect(p.tithi.number, inInclusiveRange(1, 30));
    });

    test('Southern hemisphere coordinates calculate inverted seasonal daylight', () {
      final sydney = GeoLocation.custom(
        latitude: -33.8688,
        longitude: 151.2093,
        name: 'Sydney Custom',
        timezoneOffsetHours: 10.0,
      );

      expect(sydney.formattedCoordinates, equals('33.87° S, 151.21° E'));

      // In Sydney, June 21 is Winter Solstice (shorter daylight < 10h)
      // and December 21 is Summer Solstice (longer daylight > 14h)
      final winter = PanchangEngine.calculateDailyPanchang(
        date: DateTime(2026, 6, 21),
        location: sydney,
      );
      final summer = PanchangEngine.calculateDailyPanchang(
        date: DateTime(2026, 12, 21),
        location: sydney,
      );

      expect(winter.daylightDuration.inMinutes, lessThan(600)); // < 10h
      expect(summer.daylightDuration.inMinutes, greaterThan(840)); // > 14h
    });

    test('GeoLocation JSON serialization roundtrip preserves custom coordinates', () {
      final original = GeoLocation.custom(
        latitude: 18.5204,
        longitude: 73.8567,
        name: 'Pune Studio',
        timezoneOffsetHours: 5.5,
        elevationMeters: 560.0,
      );

      final jsonMap = original.toJson();
      final restored = GeoLocation.fromJson(jsonMap);

      expect(restored.name, equals(original.name));
      expect(restored.latitude, equals(original.latitude));
      expect(restored.longitude, equals(original.longitude));
      expect(restored.timezoneOffsetHours, equals(original.timezoneOffsetHours));
      expect(restored.elevationMeters, equals(original.elevationMeters));
      expect(restored.formattedCoordinates, equals(original.formattedCoordinates));
    });

    test('LocationFetchResult models granted and denied states cleanly', () {
      final loc = GeoLocation.custom(
        latitude: 25.3176,
        longitude: 82.9739,
        name: 'Device Location (GPS)',
      );

      final successResult = LocationFetchResult.success(loc);
      expect(successResult.success, isTrue);
      expect(successResult.state, equals(LocationPermissionState.granted));
      expect(successResult.location?.name, equals('Device Location (GPS)'));

      final deniedResult = LocationFetchResult.failure(
        LocationPermissionState.denied,
        'Permission denied by user',
      );
      expect(deniedResult.success, isFalse);
      expect(deniedResult.state, equals(LocationPermissionState.denied));
      expect(deniedResult.errorMessage, contains('Permission denied'));

      final disabledResult = LocationFetchResult.failure(
        LocationPermissionState.serviceDisabled,
        'GPS disabled',
      );
      expect(disabledResult.state, equals(LocationPermissionState.serviceDisabled));
    });
  });
}
