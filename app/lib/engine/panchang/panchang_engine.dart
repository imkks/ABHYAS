import 'dart:math';
import 'solar_calculator.dart';
import 'panchang_models.dart';

/// Pure Dart authentic Vedic Panchang Engine.
/// Computes the 5 Limbs (Tithi, Vara, Nakshatra, Yoga, Karana),
/// Solar/Lunar events, Sacred Muhurtas, Rahu/Yama/Gulika Kaal,
/// Day/Night Choghadiya, and Svara Yoga Sadhana alignments.
class PanchangEngine {
  static const double _deg2rad = pi / 180.0;

  // --- 1. TITHI DATA ---
  static const List<Map<String, String>> _tithiNames = [
    {'name': 'Pratipada', 'sanskrit': 'प्रतिपदा', 'deity': 'Agni'},
    {'name': 'Dwitiya', 'sanskrit': 'द्वितीया', 'deity': 'Brahma'},
    {'name': 'Tritiya', 'sanskrit': 'तृतीया', 'deity': 'Gauri'},
    {'name': 'Chaturthi', 'sanskrit': 'चतुर्थी', 'deity': 'Ganesha'},
    {'name': 'Panchami', 'sanskrit': 'पञ्चमी', 'deity': 'Naga'},
    {'name': 'Shashthi', 'sanskrit': 'षष्ठी', 'deity': 'Kartikeya'},
    {'name': 'Saptami', 'sanskrit': 'सप्तमी', 'deity': 'Surya'},
    {'name': 'Ashtami', 'sanskrit': 'अष्टमी', 'deity': 'Shiva / Durga'},
    {'name': 'Navami', 'sanskrit': 'नवमी', 'deity': 'Durga / Rama'},
    {'name': 'Dashami', 'sanskrit': 'दशमी', 'deity': 'Yama / Digpalas'},
    {'name': 'Ekadashi', 'sanskrit': 'एकादशी', 'deity': 'Vishnu'},
    {'name': 'Dwadashi', 'sanskrit': 'द्वादशी', 'deity': 'Vishnu'},
    {'name': 'Trayodashi', 'sanskrit': 'त्रयोदशी', 'deity': 'Kamadeva / Shiva'},
    {'name': 'Chaturdashi', 'sanskrit': 'चतुर्दशी', 'deity': 'Shiva (Rudra)'},
    {'name': 'Purnima', 'sanskrit': 'पूर्णिमा', 'deity': 'Chandra'}, // 15
    // Krishna paksha
    {'name': 'Pratipada', 'sanskrit': 'प्रतिपदा', 'deity': 'Agni'},
    {'name': 'Dwitiya', 'sanskrit': 'द्वितीया', 'deity': 'Brahma'},
    {'name': 'Tritiya', 'sanskrit': 'तृतीया', 'deity': 'Gauri'},
    {'name': 'Chaturthi', 'sanskrit': 'चतुर्थी', 'deity': 'Ganesha (Sankashti)'},
    {'name': 'Panchami', 'sanskrit': 'पञ्चमी', 'deity': 'Naga'},
    {'name': 'Shashthi', 'sanskrit': 'षष्ठी', 'deity': 'Kartikeya'},
    {'name': 'Saptami', 'sanskrit': 'सप्तमी', 'deity': 'Surya'},
    {'name': 'Ashtami', 'sanskrit': 'अष्टमी', 'deity': 'Shiva (Kala Bhairava)'},
    {'name': 'Navami', 'sanskrit': 'नवमी', 'deity': 'Durga'},
    {'name': 'Dashami', 'sanskrit': 'दशमी', 'deity': 'Yama'},
    {'name': 'Ekadashi', 'sanskrit': 'एकादशी', 'deity': 'Vishnu'},
    {'name': 'Dwadashi', 'sanskrit': 'द्वादशी', 'deity': 'Vishnu'},
    {'name': 'Trayodashi', 'sanskrit': 'त्रयोदशी', 'deity': 'Shiva (Pradosha)'},
    {'name': 'Chaturdashi', 'sanskrit': 'चतुर्दशी', 'deity': 'Shiva (Masa Shivaratri)'},
    {'name': 'Amavasya', 'sanskrit': 'अमावास्या', 'deity': 'Pitrus'}, // 30
  ];

  // --- 2. VARA DATA ---
  static const List<Map<String, String>> _varaDetails = [
    {
      'sanskrit': 'Somavara',
      'english': 'Monday',
      'graha': 'Chandra (Moon)',
      'element': 'Jala (Water)',
      'energy': 'Receptive, cooling, devotional, mental peace'
    },
    {
      'sanskrit': 'Mangalavara',
      'english': 'Tuesday',
      'graha': 'Mangala (Mars)',
      'element': 'Agni (Fire)',
      'energy': 'Dynamic, vital, courage, tapas energy'
    },
    {
      'sanskrit': 'Budhavara',
      'english': 'Wednesday',
      'graha': 'Budha (Mercury)',
      'element': 'Prithvi (Earth)',
      'energy': 'Intellect, analytical, communication, steady discernment'
    },
    {
      'sanskrit': 'Guruvara',
      'english': 'Thursday',
      'graha': 'Brihaspati (Jupiter)',
      'element': 'Akasha (Ether)',
      'energy': 'Wisdom, expansion, spiritual teachings, guru kripa'
    },
    {
      'sanskrit': 'Shukravara',
      'english': 'Friday',
      'graha': 'Shukra (Venus)',
      'element': 'Jala (Water)',
      'energy': 'Harmonizing, artistic, heart-centered, ojas building'
    },
    {
      'sanskrit': 'Shanivara',
      'english': 'Saturday',
      'graha': 'Shani (Saturn)',
      'element': 'Vayu (Air)',
      'energy': 'Discipline, endurance, ascetic stillness, detachment'
    },
    {
      'sanskrit': 'Ravivara',
      'english': 'Sunday',
      'graha': 'Surya (Sun)',
      'element': 'Agni (Fire)',
      'energy': 'Solar vitality, leadership, soul power, prana empowerment'
    },
  ];

  // --- 3. NAKSHATRA DATA (27) ---
  static const List<Map<String, String>> _nakshatras = [
    {'name': 'Ashwini', 'sanskrit': 'अश्विनी', 'graha': 'Ketu', 'deity': 'Ashvini Kumaras', 'guna': 'Sattva', 'guidance': 'Swift prana movement; excellent for starting healing practices.'},
    {'name': 'Bharani', 'sanskrit': 'भरणी', 'graha': 'Shukra', 'deity': 'Yama', 'guna': 'Rajas', 'guidance': 'Deep restraint, kumbhaka focus; self-transformation.'},
    {'name': 'Krittika', 'sanskrit': 'कृत्तिका', 'graha': 'Surya', 'deity': 'Agni', 'guna': 'Rajas', 'guidance': 'Purifying fire; ideal for Kapalbhati and Agnisara.'},
    {'name': 'Rohini', 'sanskrit': 'रोहिणी', 'graha': 'Chandra', 'deity': 'Brahma (Prajapati)', 'guna': 'Rajas', 'guidance': 'Nourishing, creative; gentle Nadi Shodhana and heart meditation.'},
    {'name': 'Mrigashirsha', 'sanskrit': 'मृगशीर्षा', 'graha': 'Mangala', 'deity': 'Soma', 'guna': 'Tamas', 'guidance': 'Searching awareness; steady concentration (Dharana).'},
    {'name': 'Ardra', 'sanskrit': 'आर्द्रा', 'graha': 'Rahu', 'deity': 'Rudra', 'guna': 'Tamas', 'guidance': 'Emotional release and surrender; deep Om chanting.'},
    {'name': 'Punarvasu', 'sanskrit': 'पुनर्वसु', 'graha': 'Guru', 'deity': 'Aditi', 'guna': 'Sattva', 'guidance': 'Renewal of vitality, restoration; full yogic breath.'},
    {'name': 'Pushya', 'sanskrit': 'पुष्य', 'graha': 'Shani', 'deity': 'Brihaspati', 'guna': 'Tamas', 'guidance': 'Supreme spiritual auspiciousness; perfect for all sadhana.'},
    {'name': 'Ashlesha', 'sanskrit': 'आश्लेषा', 'graha': 'Budha', 'deity': 'Sarpas (Nagas)', 'guna': 'Sattva', 'guidance': 'Kundalini awakening energy; bandhas and inner focus.'},
    {'name': 'Magha', 'sanskrit': 'मघा', 'graha': 'Ketu', 'deity': 'Pitrus', 'guna': 'Tamas', 'guidance': 'Ancestral reverence, humility; quiet seated meditation.'},
    {'name': 'Purva Phalguni', 'sanskrit': 'पूर्व फाल्गुनी', 'graha': 'Shukra', 'deity': 'Bhaga', 'guna': 'Rajas', 'guidance': 'Harmonizing heart space; Bhramari and Anahata dhyana.'},
    {'name': 'Uttara Phalguni', 'sanskrit': 'उत्तर फाल्गुनी', 'graha': 'Surya', 'deity': 'Aryaman', 'guna': 'Rajas', 'guidance': 'Noble purpose, sustained willpower in pranayama holds.'},
    {'name': 'Hasta', 'sanskrit': 'हस्त', 'graha': 'Chandra', 'deity': 'Savitar', 'guna': 'Rajas', 'guidance': 'Mudra practice; hand gestures and energy channel sealing.'},
    {'name': 'Chitra', 'sanskrit': 'चित्रा', 'graha': 'Mangala', 'deity': 'Vishwakarma', 'guna': 'Tamas', 'guidance': 'Internal visualization, beauty in geometric breath ratios.'},
    {'name': 'Swati', 'sanskrit': 'स्वाती', 'graha': 'Rahu', 'deity': 'Vayu', 'guna': 'Tamas', 'guidance': 'Mastery over Vayu (wind); profound pranayama sensitivity.'},
    {'name': 'Vishakha', 'sanskrit': 'विशाखा', 'graha': 'Guru', 'deity': 'Indragni', 'guna': 'Sattva', 'guidance': 'Focused determination; goal-oriented meditative absorption.'},
    {'name': 'Anuradha', 'sanskrit': 'अनुराधा', 'graha': 'Shani', 'deity': 'Mitra', 'guna': 'Tamas', 'guidance': 'Devotion (Bhakti), friendly harmony with prana flows.'},
    {'name': 'Jyeshtha', 'sanskrit': 'ज्येष्ठा', 'graha': 'Budha', 'deity': 'Indra', 'guna': 'Sattva', 'guidance': 'Ascendance of consciousness, courage in long breath holds.'},
    {'name': 'Mula', 'sanskrit': 'मूल', 'graha': 'Ketu', 'deity': 'Nirriti', 'guna': 'Tamas', 'guidance': 'Mula Bandha, rooting to the core source; dissolution of ego.'},
    {'name': 'Purva Ashadha', 'sanskrit': 'पूर्वाषाढा', 'graha': 'Shukra', 'deity': 'Apas', 'guna': 'Rajas', 'guidance': 'Fluid breath currents; soothing Sheetali and Sheetkari.'},
    {'name': 'Uttara Ashadha', 'sanskrit': 'उत्तराषाढा', 'graha': 'Surya', 'deity': 'Vishwadevas', 'guna': 'Rajas', 'guidance': 'Undefeated steadfastness; disciplined full morning cycle.'},
    {'name': 'Shravana', 'sanskrit': 'श्रवण', 'graha': 'Chandra', 'deity': 'Vishnu', 'guna': 'Rajas', 'guidance': 'Inner listening (Nada Yoga); listening to inner sound vibration.'},
    {'name': 'Dhanishta', 'sanskrit': 'धनिष्ठा', 'graha': 'Mangala', 'deity': 'Ashta Vasus', 'guna': 'Tamas', 'guidance': 'Rhythmic resonance, metronome breathing cycles.'},
    {'name': 'Shatabhisha', 'sanskrit': 'शतभिषा', 'graha': 'Rahu', 'deity': 'Varuna', 'guna': 'Tamas', 'guidance': 'Deep cellular healing, pranic purification (Prana Vidya).'},
    {'name': 'Purva Bhadrapada', 'sanskrit': 'पूर्वभाद्रपदा', 'graha': 'Guru', 'deity': 'Aja Ekapada', 'guna': 'Sattva', 'guidance': 'Fiery spiritual aspiration; tapas and rigorous kumbhaka.'},
    {'name': 'Uttara Bhadrapada', 'sanskrit': 'उत्तरभाद्रपदा', 'graha': 'Shani', 'deity': 'Ahirbudhnya', 'guna': 'Tamas', 'guidance': 'Oceanic stillness, serene Yoga Nidra and Samadhi dhyana.'},
    {'name': 'Revati', 'sanskrit': 'रेवती', 'graha': 'Budha', 'deity': 'Pushan', 'guna': 'Sattva', 'guidance': 'Transcendent journey, gentle surrender to the Supreme Divine.'},
  ];

  // --- 4. YOGA DATA (27) ---
  static const List<Map<String, dynamic>> _yogas = [
    {'name': 'Vishkambha', 'sanskrit': 'विष्कम्भ', 'auspicious': false, 'meaning': 'Obstacle (focus on patient breath)'},
    {'name': 'Priti', 'sanskrit': 'प्रीति', 'auspicious': true, 'meaning': 'Affection and joy'},
    {'name': 'Ayushman', 'sanskrit': 'आयुष्मान्', 'auspicious': true, 'meaning': 'Longevity and vitality'},
    {'name': 'Saubhagya', 'sanskrit': 'सौभाग्य', 'auspicious': true, 'meaning': 'Good fortune and well-being'},
    {'name': 'Shobhana', 'sanskrit': 'शोभन', 'auspicious': true, 'meaning': 'Brilliance and clarity'},
    {'name': 'Atiganda', 'sanskrit': 'अतिगण्ड', 'auspicious': false, 'meaning': 'Severe hurdles (caution in breath holds)'},
    {'name': 'Sukarma', 'sanskrit': 'सुकर्मा', 'auspicious': true, 'meaning': 'Noble actions and merit'},
    {'name': 'Dhriti', 'sanskrit': 'धृति', 'auspicious': true, 'meaning': 'Steadfastness and endurance'},
    {'name': 'Shula', 'sanskrit': 'शूल', 'auspicious': false, 'meaning': 'Sharp trial (stick to gentle pranayama)'},
    {'name': 'Ganda', 'sanskrit': 'गण्ड', 'auspicious': false, 'meaning': 'Knot (focus on releasing Granthis)'},
    {'name': 'Vriddhi', 'sanskrit': 'वृद्धि', 'auspicious': true, 'meaning': 'Growth and spiritual expansion'},
    {'name': 'Dhruva', 'sanskrit': 'ध्रुव', 'auspicious': true, 'meaning': 'Unyielding stability (polar star)'},
    {'name': 'Vyaghata', 'sanskrit': 'व्याघात', 'auspicious': false, 'meaning': 'Striking impact (maintain calmness)'},
    {'name': 'Harshana', 'sanskrit': 'हर्षण', 'auspicious': true, 'meaning': 'Delight and inner exhilaration'},
    {'name': 'Vajra', 'sanskrit': 'वज्र', 'auspicious': false, 'meaning': 'Diamond/Thunderbolt (solid foundation)'},
    {'name': 'Asiddhi', 'sanskrit': 'सिद्धि', 'auspicious': true, 'meaning': 'Spiritual accomplishment (Siddhi)'},
    {'name': 'Vyatipata', 'sanskrit': 'व्यतीपात', 'auspicious': false, 'meaning': 'Turbulence (introspective dhyana)'},
    {'name': 'Variyan', 'sanskrit': 'वरीयान्', 'auspicious': true, 'meaning': 'Preeminence and ease'},
    {'name': 'Parigha', 'sanskrit': 'परिघ', 'auspicious': false, 'meaning': 'Iron bar (overcome inner resistance)'},
    {'name': 'Shiva', 'sanskrit': 'शिव', 'auspicious': true, 'meaning': 'Auspiciousness and transcendence'},
    {'name': 'Siddha', 'sanskrit': 'सिद्ध', 'auspicious': true, 'meaning': 'Perfection and mastery'},
    {'name': 'Sadhya', 'sanskrit': 'साध्य', 'auspicious': true, 'meaning': 'Attainable and disciplined'},
    {'name': 'Shubha', 'sanskrit': 'शुभ', 'auspicious': true, 'meaning': 'Pure and blessed'},
    {'name': 'Shukla', 'sanskrit': 'शुक्ल', 'auspicious': true, 'meaning': 'Bright, radiant, sattvic'},
    {'name': 'Brahma', 'sanskrit': 'ब्रह्म', 'auspicious': true, 'meaning': 'Cosmic knowledge and peace'},
    {'name': 'Indra', 'sanskrit': 'इन्द्र', 'auspicious': true, 'meaning': 'Sovereignty over the senses'},
    {'name': 'Vaidhriti', 'sanskrit': 'वैधृति', 'auspicious': false, 'meaning': 'Discordant (chant Om and surrender)'},
  ];

  // --- 5. KARANA DATA (11) ---
  static const List<Map<String, dynamic>> _karanas = [
    {'name': 'Bava', 'sanskrit': 'बव', 'movable': true, 'quality': 'Nourishing and active'},
    {'name': 'Balava', 'sanskrit': 'बालव', 'movable': true, 'quality': 'Youthful vigor and practice'},
    {'name': 'Kaulava', 'sanskrit': 'कौलव', 'movable': true, 'quality': 'Devotion and family harmony'},
    {'name': 'Taitila', 'sanskrit': 'तैतिल', 'movable': true, 'quality': 'Honor, service, duty'},
    {'name': 'Gara', 'sanskrit': 'गर', 'movable': true, 'quality': 'Firm resolve, steady effort'},
    {'name': 'Vanija', 'sanskrit': 'वणिज', 'movable': true, 'quality': 'Transaction, balance of breath'},
    {'name': 'Vishti (Bhadra)', 'sanskrit': 'विष्टि (भद्रा)', 'movable': true, 'quality': 'Fierce; ideal for deep internal sadhana, not outer transactions'},
    {'name': 'Shakuni', 'sanskrit': 'शकुनि', 'movable': false, 'quality': 'Discerning instinct; stillness'},
    {'name': 'Chatushpada', 'sanskrit': 'चतुष्पद', 'movable': false, 'quality': 'Firm quadrupod foundation; asana stability'},
    {'name': 'Naga', 'sanskrit': 'नाग', 'movable': false, 'quality': 'Serpent power; deep internal kundalini awareness'},
    {'name': 'Kintughna', 'sanskrit': 'किंस्तुघ्न', 'movable': false, 'quality': 'Overcoming sorrow, auspicious beginning'},
  ];

  /// Computes Moon's tropical longitude based on Jean Meeus astronomical algorithms.
  static double _calculateMoonLongitude(double jd) {
    final t = SolarCalculator.getJulianCentury(jd);

    // Moon's Mean Longitude (degrees)
    double lp = 218.3164477 +
        481267.88123421 * t -
        0.0015786 * t * t +
        t * t * t / 538841.0;
    lp = SolarCalculator.normalizeDegrees(lp);

    // Mean elongation of the Moon
    double d = 297.8501921 +
        445267.1114034 * t -
        0.0018819 * t * t +
        t * t * t / 545868.0;
    d = SolarCalculator.normalizeDegrees(d);

    // Sun's Mean Anomaly
    double m = 357.5291092 +
        35999.0502909 * t -
        0.0001536 * t * t;
    m = SolarCalculator.normalizeDegrees(m);

    // Moon's Mean Anomaly
    double mp = 134.9633964 +
        477198.8675055 * t +
        0.0087414 * t * t +
        t * t * t / 69699.0;
    mp = SolarCalculator.normalizeDegrees(mp);

    // Moon's Argument of Latitude
    double f = 93.2720950 +
        483202.0175233 * t -
        0.0036539 * t * t;
    f = SolarCalculator.normalizeDegrees(f);

    // Periodic terms (degrees)
    final dRad = d * _deg2rad;
    final mRad = m * _deg2rad;
    final mpRad = mp * _deg2rad;
    final fRad = f * _deg2rad;

    double perturbation = 6.288774 * sin(mpRad) +
        1.274027 * sin(2 * dRad - mpRad) +
        0.658314 * sin(2 * dRad) +
        0.213618 * sin(2 * mpRad) -
        0.185116 * sin(mRad) -
        0.114332 * sin(2 * fRad) +
        0.058793 * sin(2 * dRad - 2 * mpRad) +
        0.057066 * sin(2 * dRad - mRad - mpRad) +
        0.053322 * sin(2 * dRad + mpRad) +
        0.045758 * sin(2 * dRad - mRad);

    return SolarCalculator.normalizeDegrees(lp + perturbation);
  }

  /// Calculates Lahiri Ayanamsha for converting tropical to sidereal positions.
  static double _calculateLahiriAyanamsha(DateTime date) {
    // Reference: ~23.85° at Epoch 2000.0, precession rate ~50.29 arcseconds/year
    final yearFraction = date.year + (date.month - 1) / 12.0 + date.day / 365.25;
    return 23.854 + (yearFraction - 2000.0) * (50.29 / 3600.0);
  }

  /// Calculates the complete Panchang for a given calendar date and location.
  static DailyPanchang calculateDailyPanchang({
    required DateTime date,
    required GeoLocation location,
  }) {
    // 1. Solar Astronomical calculation
    final solar = SolarCalculator.calculateTimes(
      date: date,
      latitude: location.latitude,
      longitude: location.longitude,
      timezoneOffsetHours: location.timezoneOffsetHours,
    );

    // Julian day at Sunrise
    final localSunriseUtc = solar.sunrise.toUtc();
    final jdSunrise = SolarCalculator.getJulianDay(localSunriseUtc);

    // Coordinates of Sun and Moon at Sunrise
    final sunCoords = SolarCalculator.calculateSolarCoordinates(jdSunrise);
    final sunTropical = sunCoords.trueLongitudeDegrees;
    final moonTropical = _calculateMoonLongitude(jdSunrise);

    final ayanamsha = _calculateLahiriAyanamsha(date);

    // Sidereal positions (Nirayana)
    final sunSidereal = SolarCalculator.normalizeDegrees(sunTropical - ayanamsha);
    final moonSidereal = SolarCalculator.normalizeDegrees(moonTropical - ayanamsha);

    // --- A. TITHI CALCULATION ---
    // Elongation: (Moon - Sun)
    final elongation = SolarCalculator.normalizeDegrees(moonTropical - sunTropical);
    int tithiIndex = (elongation / 12.0).floor() + 1;
    if (tithiIndex < 1) tithiIndex = 1;
    if (tithiIndex > 30) tithiIndex = 30;

    final tithiData = _tithiNames[tithiIndex - 1];
    final paksha = tithiIndex <= 15 ? Paksha.shukla : Paksha.krishna;
    final isEkadashi = (tithiIndex == 11 || tithiIndex == 26);
    final isPurnima = (tithiIndex == 15);
    final isAmavasya = (tithiIndex == 30);
    final isPradosha = (tithiIndex == 13 || tithiIndex == 28);

    String significance = 'Daily sadhana practice.';
    if (isEkadashi) {
      significance = 'Ekadashi: Auspicious for fasting, light diet, and inward meditation.';
    } else if (isPurnima) {
      significance = 'Purnima: Full moon peak energy; ideal for Trataka, OM chanting, and deep Dhyana.';
    } else if (isAmavasya) {
      significance = 'Amavasya: New moon stillness; ideal for grounding, Yoga Nidra, and inner reflection.';
    } else if (isPradosha) {
      significance = 'Pradosha: Sunset twilight window dedicated to Lord Shiva; potent for pranayama.';
    }

    final tithi = TithiInfo(
      number: tithiIndex,
      name: tithiData['name']!,
      sanskritName: tithiData['sanskrit']!,
      paksha: paksha,
      deity: tithiData['deity']!,
      isEkadashi: isEkadashi,
      isPurnima: isPurnima,
      isAmavasya: isAmavasya,
      isPradosha: isPradosha,
      spiritualSignificance: significance,
    );

    // --- B. VARA CALCULATION ---
    // Dart: 1 = Mon ... 7 = Sun. Array is 0-indexed Mon-Sun.
    final weekday = date.weekday; // 1 to 7
    final varaMap = _varaDetails[weekday - 1];
    final vara = VaraInfo(
      weekdayNumber: weekday,
      sanskritName: varaMap['sanskrit']!,
      englishDay: varaMap['english']!,
      rulingGraha: varaMap['graha']!,
      element: varaMap['element']!,
      energeticQuality: varaMap['energy']!,
    );

    // --- C. NAKSHATRA CALCULATION ---
    int nakshatraIndex = (moonSidereal / (360.0 / 27.0)).floor() + 1;
    if (nakshatraIndex < 1) nakshatraIndex = 1;
    if (nakshatraIndex > 27) nakshatraIndex = 27;

    final pada = (((moonSidereal % (360.0 / 27.0)) / (360.0 / 108.0)).floor() + 1).clamp(1, 4);
    final nakData = _nakshatras[nakshatraIndex - 1];

    final nakshatra = NakshatraInfo(
      number: nakshatraIndex,
      name: nakData['name']!,
      sanskritName: nakData['sanskrit']!,
      pada: pada,
      rulingGraha: nakData['graha']!,
      deity: nakData['deity']!,
      guna: nakData['guna']!,
      yogicGuidance: nakData['guidance']!,
    );

    // --- D. YOGA CALCULATION ---
    final yogaDegree = SolarCalculator.normalizeDegrees(sunSidereal + moonSidereal);
    int yogaIndex = (yogaDegree / (360.0 / 27.0)).floor() + 1;
    if (yogaIndex < 1) yogaIndex = 1;
    if (yogaIndex > 27) yogaIndex = 27;

    final yogaData = _yogas[yogaIndex - 1];
    final yoga = YogaInfo(
      number: yogaIndex,
      name: yogaData['name'] as String,
      sanskritName: yogaData['sanskrit'] as String,
      isAuspicious: yogaData['auspicious'] as bool,
      meaning: yogaData['meaning'] as String,
    );

    // --- E. KARANA CALCULATION ---
    final halfTithi = (elongation / 6.0).floor() + 1; // 1 to 60
    KaranaInfo karana;
    if (halfTithi == 1) {
      // 1st half of Shukla Pratipada is Kintughna
      final k = _karanas[10];
      karana = KaranaInfo(cyclicNumber: 11, name: k['name'], sanskritName: k['sanskrit'], isMovable: k['movable'], quality: k['quality']);
    } else if (halfTithi >= 58) {
      // Fixed karanas at month end
      if (halfTithi == 58) {
        final k = _karanas[7]; // Shakuni
        karana = KaranaInfo(cyclicNumber: 8, name: k['name'], sanskritName: k['sanskrit'], isMovable: k['movable'], quality: k['quality']);
      } else if (halfTithi == 59) {
        final k = _karanas[8]; // Chatushpada
        karana = KaranaInfo(cyclicNumber: 9, name: k['name'], sanskritName: k['sanskrit'], isMovable: k['movable'], quality: k['quality']);
      } else {
        final k = _karanas[9]; // Naga
        karana = KaranaInfo(cyclicNumber: 10, name: k['name'], sanskritName: k['sanskrit'], isMovable: k['movable'], quality: k['quality']);
      }
    } else {
      // Movable Karanas 1..7 cyclic (Bava to Vishti)
      int charaIndex = (halfTithi - 2) % 7;
      final k = _karanas[charaIndex];
      karana = KaranaInfo(cyclicNumber: charaIndex + 1, name: k['name'], sanskritName: k['sanskrit'], isMovable: k['movable'], quality: k['quality']);
    }

    // --- F. MUHURTAS & KALA WINDOWS ---
    final daylightMs = solar.daylightDuration.inMilliseconds;
    final nightMs = solar.nightDuration.inMilliseconds;

    final dayMuhurtaMs = (daylightMs / 15.0).round();
    final nightMuhurtaMs = (nightMs / 15.0).round();

    // 1. Brahma Muhurta: 14th Muhurta of the night.
    // Starts 2 night muhurtas before sunrise, ends 1 night muhurta before sunrise.
    final brahmaStart = solar.sunrise.subtract(Duration(milliseconds: 2 * nightMuhurtaMs));
    final brahmaEnd = solar.sunrise.subtract(Duration(milliseconds: 1 * nightMuhurtaMs));
    final brahmaMuhurta = MuhurtaPeriod(
      name: 'Brahma Muhurta',
      sanskritName: 'ब्रह्म मुहूर्त',
      startTime: brahmaStart,
      endTime: brahmaEnd,
      type: MuhurtaType.spiritualPeak,
      description: 'The creator\'s hour. Peak sattva, ideal for Pranayama, Sushumna awakening, and deep Dhyana.',
      yogicPractice: 'Silent Japa, Nadi Shodhana, Dhyana, Patanjali Yoga Sutra contemplation',
    );

    // 2. Pratah Sandhya: Junction at dawn (sunrise)
    final pratahStart = solar.sunrise.subtract(const Duration(minutes: 24));
    final pratahEnd = solar.sunrise.add(const Duration(minutes: 24));
    final pratahSandhya = MuhurtaPeriod(
      name: 'Pratah Sandhya',
      sanskritName: 'प्रातः सन्ध्या',
      startTime: pratahStart,
      endTime: pratahEnd,
      type: MuhurtaType.auspicious,
      description: 'Dawn junction where Ida and Pingala merge into Sushumna.',
      yogicPractice: 'Gayatri Mantra, Surya Namaskar, Nadi Shodhana',
    );

    // 3. Abhijit Muhurta: 8th Muhurta of the day (centered on Solar Noon)
    final abhijitStart = solar.solarNoon.subtract(Duration(milliseconds: dayMuhurtaMs ~/ 2));
    final abhijitEnd = solar.solarNoon.add(Duration(milliseconds: dayMuhurtaMs ~/ 2));
    final abhijitMuhurta = MuhurtaPeriod(
      name: 'Abhijit Muhurta',
      sanskritName: 'अभिजित् मुहूर्त',
      startTime: abhijitStart,
      endTime: abhijitEnd,
      type: weekday == 3 ? MuhurtaType.neutral : MuhurtaType.auspicious, // On Wednesday, Abhijit is flawed
      description: weekday == 3
          ? 'On Wednesdays, Abhijit has Budhavara dosha; neutral for worldly pursuits, still pure for quiet contemplation.'
          : 'The victorious 8th Muhurta dispelling all inauspiciousness.',
      yogicPractice: 'Centering, breath awareness, mid-day prayer',
    );

    // 4. Madhyahna Sandhya: Noon junction
    final madhyahnaStart = solar.solarNoon.subtract(const Duration(minutes: 24));
    final madhyahnaEnd = solar.solarNoon.add(const Duration(minutes: 24));
    final madhyahnaSandhya = MuhurtaPeriod(
      name: 'Madhyahna Sandhya',
      sanskritName: 'मध्याह्न सन्ध्या',
      startTime: madhyahnaStart,
      endTime: madhyahnaEnd,
      type: MuhurtaType.auspicious,
      description: 'Midday solar zenith junction.',
      yogicPractice: 'Quiet reflection, digestive awareness (Samana Vayu)',
    );

    // 5. Sayam Sandhya: Dusk junction at sunset
    final sayamStart = solar.sunset.subtract(const Duration(minutes: 24));
    final sayamEnd = solar.sunset.add(const Duration(minutes: 24));
    final sayamSandhya = MuhurtaPeriod(
      name: 'Sayam Sandhya',
      sanskritName: 'सायं सन्ध्या',
      startTime: sayamStart,
      endTime: sayamEnd,
      type: MuhurtaType.auspicious,
      description: 'Dusk junction. Day meets night; calming of nervous system.',
      yogicPractice: 'Trataka, Bhramari, Shanti Path, Yoga Nidra',
    );

    // --- G. RAHU KALAM, YAMA GANDAM, GULIKA KALAM ---
    // Daylight divided into 8 equal parts
    final partMs = daylightMs / 8.0;

    // Segments mapping (1-indexed 1..8):
    // Weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
    final rahuSegments = {7: 8, 1: 2, 2: 7, 3: 5, 4: 6, 5: 4, 6: 3};
    final yamaSegments = {7: 5, 1: 4, 2: 3, 3: 2, 4: 1, 5: 7, 6: 6};
    final gulikaSegments = {7: 7, 1: 6, 2: 5, 3: 4, 4: 3, 5: 2, 6: 1};

    MuhurtaPeriod makeKalaPeriod(String name, String sanskrit, int seg, String desc) {
      final start = solar.sunrise.add(Duration(milliseconds: ((seg - 1) * partMs).round()));
      final end = solar.sunrise.add(Duration(milliseconds: (seg * partMs).round()));
      return MuhurtaPeriod(
        name: name,
        sanskritName: sanskrit,
        startTime: start,
        endTime: end,
        type: MuhurtaType.inauspicious,
        description: desc,
        yogicPractice: 'Avoid starting new worldly ventures; practice inner mantra japa and grounding.',
      );
    }

    final rahuKalam = makeKalaPeriod(
      'Rahu Kalam',
      'राहु काल',
      rahuSegments[weekday]!,
      'Inauspicious window governed by Rahu. Ideal for detachment and spiritual japa.',
    );

    final yamaGandam = makeKalaPeriod(
      'Yama Gandam',
      'यम गण्ड',
      yamaSegments[weekday]!,
      'Period governed by Yama. Inauspicious for commencement.',
    );

    final gulikaKalam = makeKalaPeriod(
      'Gulika Kalam',
      'गुलिक काल',
      gulikaSegments[weekday]!,
      'Period governed by Gulika (son of Saturn).',
    );

    // --- H. CHOGHADIYA CALCULATIONS ---
    final dayChoghadiya = _calculateDayChoghadiya(solar.sunrise, partMs, weekday);
    final nightPartMs = nightMs / 8.0;
    final nightChoghadiya = _calculateNightChoghadiya(solar.sunset, nightPartMs, weekday);

    // --- I. SVARA YOGA RECOMMENDATION (Shiva Svarodaya) ---
    final svara = _calculateSvaraRecommendation(tithiIndex, paksha);

    return DailyPanchang(
      date: date,
      location: location,
      tithi: tithi,
      vara: vara,
      nakshatra: nakshatra,
      yoga: yoga,
      karana: karana,
      sunrise: solar.sunrise,
      sunset: solar.sunset,
      solarNoon: solar.solarNoon,
      daylightDuration: solar.daylightDuration,
      nightDuration: solar.nightDuration,
      brahmaMuhurta: brahmaMuhurta,
      abhijitMuhurta: abhijitMuhurta,
      pratahSandhya: pratahSandhya,
      madhyahnaSandhya: madhyahnaSandhya,
      sayamSandhya: sayamSandhya,
      rahuKalam: rahuKalam,
      yamaGandam: yamaGandam,
      gulikaKalam: gulikaKalam,
      dayChoghadiya: dayChoghadiya,
      nightChoghadiya: nightChoghadiya,
      svaraRecommendation: svara,
    );
  }

  static List<ChoghadiyaPeriod> _calculateDayChoghadiya(
      DateTime sunrise, double partMs, int weekday) {
    // Weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
    final daySequences = {
      7: [ChoghadiyaNature.udveg, ChoghadiyaNature.char, ChoghadiyaNature.labh, ChoghadiyaNature.amrit, ChoghadiyaNature.kaal, ChoghadiyaNature.shubh, ChoghadiyaNature.rog, ChoghadiyaNature.udveg],
      1: [ChoghadiyaNature.amrit, ChoghadiyaNature.kaal, ChoghadiyaNature.shubh, ChoghadiyaNature.rog, ChoghadiyaNature.udveg, ChoghadiyaNature.char, ChoghadiyaNature.labh, ChoghadiyaNature.amrit],
      2: [ChoghadiyaNature.rog, ChoghadiyaNature.udveg, ChoghadiyaNature.char, ChoghadiyaNature.labh, ChoghadiyaNature.amrit, ChoghadiyaNature.kaal, ChoghadiyaNature.shubh, ChoghadiyaNature.rog],
      3: [ChoghadiyaNature.labh, ChoghadiyaNature.amrit, ChoghadiyaNature.kaal, ChoghadiyaNature.shubh, ChoghadiyaNature.rog, ChoghadiyaNature.udveg, ChoghadiyaNature.char, ChoghadiyaNature.labh],
      4: [ChoghadiyaNature.shubh, ChoghadiyaNature.rog, ChoghadiyaNature.udveg, ChoghadiyaNature.char, ChoghadiyaNature.labh, ChoghadiyaNature.amrit, ChoghadiyaNature.kaal, ChoghadiyaNature.shubh],
      5: [ChoghadiyaNature.char, ChoghadiyaNature.labh, ChoghadiyaNature.amrit, ChoghadiyaNature.kaal, ChoghadiyaNature.shubh, ChoghadiyaNature.rog, ChoghadiyaNature.udveg, ChoghadiyaNature.char],
      6: [ChoghadiyaNature.kaal, ChoghadiyaNature.shubh, ChoghadiyaNature.rog, ChoghadiyaNature.udveg, ChoghadiyaNature.char, ChoghadiyaNature.labh, ChoghadiyaNature.amrit, ChoghadiyaNature.kaal],
    };

    final seq = daySequences[weekday]!;
    final List<ChoghadiyaPeriod> list = [];

    for (int i = 0; i < 8; i++) {
      final start = sunrise.add(Duration(milliseconds: (i * partMs).round()));
      final end = sunrise.add(Duration(milliseconds: ((i + 1) * partMs).round()));
      final nature = seq[i];
      list.add(ChoghadiyaPeriod(
        name: _natureToName(nature),
        sanskritName: _natureToSanskrit(nature),
        rulerGraha: _natureToGraha(nature),
        nature: nature,
        isDaytime: true,
        startTime: start,
        endTime: end,
      ));
    }
    return list;
  }

  static List<ChoghadiyaPeriod> _calculateNightChoghadiya(
      DateTime sunset, double nightPartMs, int weekday) {
    final nightSequences = {
      7: [ChoghadiyaNature.shubh, ChoghadiyaNature.amrit, ChoghadiyaNature.char, ChoghadiyaNature.rog, ChoghadiyaNature.kaal, ChoghadiyaNature.labh, ChoghadiyaNature.udveg, ChoghadiyaNature.shubh],
      1: [ChoghadiyaNature.char, ChoghadiyaNature.rog, ChoghadiyaNature.kaal, ChoghadiyaNature.labh, ChoghadiyaNature.udveg, ChoghadiyaNature.shubh, ChoghadiyaNature.amrit, ChoghadiyaNature.char],
      2: [ChoghadiyaNature.kaal, ChoghadiyaNature.labh, ChoghadiyaNature.udveg, ChoghadiyaNature.shubh, ChoghadiyaNature.amrit, ChoghadiyaNature.char, ChoghadiyaNature.rog, ChoghadiyaNature.kaal],
      3: [ChoghadiyaNature.udveg, ChoghadiyaNature.shubh, ChoghadiyaNature.amrit, ChoghadiyaNature.char, ChoghadiyaNature.rog, ChoghadiyaNature.kaal, ChoghadiyaNature.labh, ChoghadiyaNature.udveg],
      4: [ChoghadiyaNature.amrit, ChoghadiyaNature.char, ChoghadiyaNature.rog, ChoghadiyaNature.kaal, ChoghadiyaNature.labh, ChoghadiyaNature.udveg, ChoghadiyaNature.shubh, ChoghadiyaNature.amrit],
      5: [ChoghadiyaNature.rog, ChoghadiyaNature.kaal, ChoghadiyaNature.labh, ChoghadiyaNature.udveg, ChoghadiyaNature.shubh, ChoghadiyaNature.amrit, ChoghadiyaNature.char, ChoghadiyaNature.rog],
      6: [ChoghadiyaNature.labh, ChoghadiyaNature.udveg, ChoghadiyaNature.shubh, ChoghadiyaNature.amrit, ChoghadiyaNature.char, ChoghadiyaNature.rog, ChoghadiyaNature.kaal, ChoghadiyaNature.labh],
    };

    final seq = nightSequences[weekday]!;
    final List<ChoghadiyaPeriod> list = [];

    for (int i = 0; i < 8; i++) {
      final start = sunset.add(Duration(milliseconds: (i * nightPartMs).round()));
      final end = sunset.add(Duration(milliseconds: ((i + 1) * nightPartMs).round()));
      final nature = seq[i];
      list.add(ChoghadiyaPeriod(
        name: _natureToName(nature),
        sanskritName: _natureToSanskrit(nature),
        rulerGraha: _natureToGraha(nature),
        nature: nature,
        isDaytime: false,
        startTime: start,
        endTime: end,
      ));
    }
    return list;
  }

  static String _natureToName(ChoghadiyaNature nature) {
    switch (nature) {
      case ChoghadiyaNature.amrit: return 'Amrit';
      case ChoghadiyaNature.shubh: return 'Shubh';
      case ChoghadiyaNature.labh: return 'Labh';
      case ChoghadiyaNature.char: return 'Char';
      case ChoghadiyaNature.rog: return 'Rog';
      case ChoghadiyaNature.kaal: return 'Kaal';
      case ChoghadiyaNature.udveg: return 'Udveg';
    }
  }

  static String _natureToSanskrit(ChoghadiyaNature nature) {
    switch (nature) {
      case ChoghadiyaNature.amrit: return 'अमृत';
      case ChoghadiyaNature.shubh: return 'शुभ';
      case ChoghadiyaNature.labh: return 'लाभ';
      case ChoghadiyaNature.char: return 'चर';
      case ChoghadiyaNature.rog: return 'रोग';
      case ChoghadiyaNature.kaal: return 'काल';
      case ChoghadiyaNature.udveg: return 'उद्वेग';
    }
  }

  static String _natureToGraha(ChoghadiyaNature nature) {
    switch (nature) {
      case ChoghadiyaNature.amrit: return 'Chandra (Moon)';
      case ChoghadiyaNature.shubh: return 'Brihaspati (Jupiter)';
      case ChoghadiyaNature.labh: return 'Budha (Mercury)';
      case ChoghadiyaNature.char: return 'Shukra (Venus)';
      case ChoghadiyaNature.rog: return 'Mangala (Mars)';
      case ChoghadiyaNature.kaal: return 'Shani (Saturn)';
      case ChoghadiyaNature.udveg: return 'Surya (Sun)';
    }
  }

  static SvaraRecommendation _calculateSvaraRecommendation(
      int tithiIndex, Paksha paksha) {
    // Shiva Svarodaya rules:
    // In Shukla Paksha:
    // Tithis 1, 2, 3, 7, 8, 9, 13, 14, 15: Chandra Svara (Ida / Left nostril) should open at sunrise.
    // Tithis 4, 5, 6, 10, 11, 12: Surya Svara (Pingala / Right nostril) should open at sunrise.
    // In Krishna Paksha:
    // Tithis 1, 2, 3, 7, 8, 9, 13, 14, 30: Surya Svara (Pingala) should open at sunrise.
    // Tithis 4, 5, 6, 10, 11, 12: Chandra Svara (Ida) should open at sunrise.

    final tithiInPaksha = paksha == Paksha.shukla ? tithiIndex : (tithiIndex - 15);
    final isGroupA = [1, 2, 3, 7, 8, 9, 13, 14, 15].contains(tithiInPaksha);

    ActiveNadi idealNadi;
    if (paksha == Paksha.shukla) {
      idealNadi = isGroupA ? ActiveNadi.ida : ActiveNadi.pingala;
    } else {
      idealNadi = isGroupA ? ActiveNadi.pingala : ActiveNadi.ida;
    }

    if (idealNadi == ActiveNadi.ida) {
      return SvaraRecommendation(
        idealNadi: ActiveNadi.ida,
        dominantElement: 'Jala / Prithvi (Water/Earth)',
        recommendedPranayamas: [
          'Chandra Bhedana',
          'Nadi Shodhana',
          'Sheetali / Sheetkari',
          'Deep Dharana (Meditation)',
        ],
        guidance:
            'Chandra Nadi (Ida) activates lunar, cooling, parasympathetic currents. Ideal for soothing nervous system, establishing steady focus, and long dhyan.',
      );
    } else {
      return SvaraRecommendation(
        idealNadi: ActiveNadi.pingala,
        dominantElement: 'Agni / Vayu (Fire/Air)',
        recommendedPranayamas: [
          'Surya Bhedana',
          'Kapalbhati',
          'Bhastrika',
          'Uddiyana Kriya',
        ],
        guidance:
            'Surya Nadi (Pingala) activates solar, warming, sympathetic digestive currents. Ideal for building metabolic tapas, purifying nadis, and dynamic pranayama.',
      );
    }
  }
}
