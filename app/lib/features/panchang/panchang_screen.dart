import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/location_service.dart';
import '../../core/theme.dart';
import '../../engine/panchang/panchang_engine.dart';
import '../../engine/panchang/panchang_models.dart';
import '../../engine/panchang/panchang_service.dart';
import '../practice/cycle_composer_screen.dart';

class PanchangScreen extends StatefulWidget {
  final DateTime? initialDate;

  const PanchangScreen({Key? key, this.initialDate}) : super(key: key);

  @override
  _PanchangScreenState createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  final PanchangService _panchangService = PanchangService();
  late DateTime _selectedDate;
  bool _showDayChoghadiya = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _panchangService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _panchangService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AbhyasTheme.saffron,
              onPrimary: AbhyasTheme.darkBg,
              surface: AbhyasTheme.darkSurface,
              onSurface: AbhyasTheme.darkInk,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showCustomCoordinatesDialog() {
    final latController = TextEditingController(
      text: _panchangService.currentLocation.latitude.toStringAsFixed(4),
    );
    final lngController = TextEditingController(
      text: _panchangService.currentLocation.longitude.toStringAsFixed(4),
    );
    final nameController = TextEditingController(
      text: _panchangService.currentLocation.isCustom
          ? _panchangService.currentLocation.name
          : '',
    );
    final tzController = TextEditingController(
      text: _panchangService.currentLocation.timezoneOffsetHours.toString(),
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AbhyasTheme.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.edit_location_alt, color: AbhyasTheme.saffron),
              SizedBox(width: 10),
              Text(
                'Custom Coordinates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter exact geographic coordinates. Sunrise, Brahma Muhurta, and all 5 limbs of the Panchang will be computed for this exact point on Earth.',
                    style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude (-90.0° to +90.0°)',
                      hintText: 'e.g. 25.3176',
                      prefixIcon: Icon(Icons.north, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter latitude';
                      final num = double.tryParse(val.trim());
                      if (num == null || num < -90.0 || num > 90.0) {
                        return 'Latitude must be between -90 and 90';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude (-180.0° to +180.0°)',
                      hintText: 'e.g. 82.9739',
                      prefixIcon: Icon(Icons.east, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter longitude';
                      final num = double.tryParse(val.trim());
                      if (num == null || num < -180.0 || num > 180.0) {
                        return 'Longitude must be between -180 and 180';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Location Label (Optional)',
                      hintText: 'e.g. My Sadhana Space',
                      prefixIcon: Icon(Icons.label_outline, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tzController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Timezone Offset (Hours)',
                      hintText: 'e.g. 5.5 for IST, -5 for EST',
                      prefixIcon: Icon(Icons.access_time, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter timezone offset';
                      final num = double.tryParse(val.trim());
                      if (num == null || num < -12.0 || num > 14.0) {
                        return 'Offset must be between -12 and +14';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AbhyasTheme.darkInkSoft)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final lat = double.parse(latController.text.trim());
                  final lng = double.parse(lngController.text.trim());
                  final tz = double.parse(tzController.text.trim());
                  final label = nameController.text.trim();

                  await _panchangService.setCustomCoordinates(
                    latitude: lat,
                    longitude: lng,
                    name: label.isNotEmpty ? label : null,
                    timezoneOffsetHours: tz,
                  );

                  if (mounted) {
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                }
              },
              child: const Text('Apply & Calculate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _detectDeviceLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          color: AbhyasTheme.darkSurface,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AbhyasTheme.saffron),
                SizedBox(width: 16),
                Text('Acquiring GPS location...', style: TextStyle(color: AbhyasTheme.darkInk)),
              ],
            ),
          ),
        ),
      ),
    );

    final result = await DeviceLocationService().fetchCurrentLocation();

    if (mounted) {
      Navigator.pop(context); // dismiss loading dialog
    }

    if (result.success && result.location != null) {
      await _panchangService.setLocation(result.location!);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location set to GPS: ${result.location!.formattedCoordinates}',
            ),
            backgroundColor: AbhyasTheme.leaf,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Unable to acquire device location'),
            backgroundColor: AbhyasTheme.clay,
            action: result.state == LocationPermissionState.deniedForever
                ? SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () => Geolocator.openAppSettings(),
                  )
                : null,
          ),
        );
      }
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AbhyasTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currentLoc = _panchangService.currentLocation;
        final isGps = currentLoc.name.contains('GPS');

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AbhyasTheme.saffron),
                    const SizedBox(width: 8),
                    const Text(
                      'Panchang Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AbhyasTheme.darkInk,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: AbhyasTheme.line),
              // Option 1: Use Current Device Location (GPS)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(context);
                    _detectDeviceLocation();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isGps
                          ? AbhyasTheme.saffron.withValues(alpha: 0.15)
                          : AbhyasTheme.darkSurfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isGps ? AbhyasTheme.saffron : AbhyasTheme.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: AbhyasTheme.sky, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Use Current Location (GPS)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AbhyasTheme.darkInk,
                                ),
                              ),
                              Text(
                                isGps
                                    ? 'Active: ${currentLoc.formattedCoordinates}'
                                    : 'Auto-detect via device location permission',
                                style: const TextStyle(
                                  color: AbhyasTheme.darkInkSoft,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isGps)
                          const Icon(Icons.check_circle, color: AbhyasTheme.saffron, size: 20)
                        else
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AbhyasTheme.darkInkSoft),
                      ],
                    ),
                  ),
                ),
              ),
              // Option 2: Enter Custom Coordinates Manually
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomCoordinatesDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: currentLoc.isCustom && !isGps
                          ? AbhyasTheme.saffron.withValues(alpha: 0.15)
                          : AbhyasTheme.darkSurfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: currentLoc.isCustom && !isGps
                            ? AbhyasTheme.saffron
                            : AbhyasTheme.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_location_alt, color: AbhyasTheme.saffron, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Set Custom Coordinates',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AbhyasTheme.darkInk,
                                ),
                              ),
                              Text(
                                currentLoc.isCustom && !isGps
                                    ? 'Active: ${currentLoc.name} (${currentLoc.formattedCoordinates})'
                                    : 'Enter custom GPS latitude & longitude',
                                style: const TextStyle(
                                  color: AbhyasTheme.darkInkSoft,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentLoc.isCustom && !isGps)
                          const Icon(Icons.check_circle, color: AbhyasTheme.saffron, size: 20)
                        else
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AbhyasTheme.darkInkSoft),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: [
                    Text(
                      'OR SELECT SACRED REFERENCE CITY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AbhyasTheme.darkInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: GeoLocation.sacredCities.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AbhyasTheme.line),
                  itemBuilder: (context, index) {
                    final city = GeoLocation.sacredCities[index];
                    final isSelected =
                        !currentLoc.isCustom && currentLoc.name == city.name;
                    return ListTile(
                      title: Text(
                        city.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AbhyasTheme.saffron
                              : AbhyasTheme.darkInk,
                        ),
                      ),
                      subtitle: Text(
                        '${city.stateOrCountry} · ${city.formattedCoordinates}',
                        style: const TextStyle(
                          color: AbhyasTheme.darkInkSoft,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AbhyasTheme.saffron)
                          : null,
                      onTap: () {
                        _panchangService.setLocation(city);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final panchang = _panchangService.getPanchangFor(_selectedDate);
    final brahmaStatus = _panchangService.getBrahmaMuhurtaStatus(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vedic Panchang'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Change Location',
            onPressed: _showLocationPicker,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildLocationBanner(panchang.location),
          const SizedBox(height: 12),
          _buildDateNavigator(isToday),
          const SizedBox(height: 16),
          if (isToday) _buildLiveMuhurtaStatusBanner(brahmaStatus, panchang, now),
          if (isToday) const SizedBox(height: 16),
          _buildPanchaAngaSection(panchang),
          const SizedBox(height: 20),
          _buildSolarCard(panchang),
          const SizedBox(height: 20),
          _buildSacredMuhurtasSection(panchang, now, isToday),
          const SizedBox(height: 20),
          _buildInauspiciousKalasSection(panchang, now, isToday),
          const SizedBox(height: 20),
          _buildChoghadiyaSection(panchang, now, isToday),
          const SizedBox(height: 20),
          _buildSvaraYogaSection(panchang),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLocationBanner(GeoLocation loc) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showLocationPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AbhyasTheme.darkSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: loc.isCustom ? AbhyasTheme.saffron.withValues(alpha: 0.6) : AbhyasTheme.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              loc.isCustom ? Icons.edit_location_alt : Icons.place,
              size: 20,
              color: AbhyasTheme.saffron,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          loc.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AbhyasTheme.darkInk,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (loc.isCustom) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AbhyasTheme.saffron.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AbhyasTheme.saffron, width: 0.8),
                          ),
                          child: const Text(
                            'CUSTOM',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AbhyasTheme.saffron,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${loc.formattedCoordinates} · TZ: ${loc.timezoneOffsetHours >= 0 ? '+' : ''}${loc.timezoneOffsetHours}h',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AbhyasTheme.darkInkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Change',
              style: TextStyle(
                fontSize: 12,
                color: AbhyasTheme.sky,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.keyboard_arrow_right, size: 18, color: AbhyasTheme.sky),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigator(bool isToday) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final formattedDate =
        '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeDate(-1),
          tooltip: 'Previous Day',
        ),
        Expanded(
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AbhyasTheme.saffron),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isToday)
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('Today'),
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeDate(1),
          tooltip: 'Next Day',
        ),
      ],
    );
  }

  Widget _buildLiveMuhurtaStatusBanner(
      BrahmaMuhurtaStatus status, DailyPanchang panchang, DateTime now) {
    final activeMuhurta = panchang.getCurrentMuhurta(now);
    final activeChoghadiya = panchang.getCurrentChoghadiya(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: status.isActive
              ? [const Color(0xFF4A2800), const Color(0xFF2B1800)]
              : [AbhyasTheme.darkSurfaceAlt, AbhyasTheme.darkSurface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.isActive ? AbhyasTheme.saffron : AbhyasTheme.line,
          width: status.isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.isActive ? Icons.wb_twilight : Icons.hourglass_top,
                color: AbhyasTheme.saffron,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                status.isActive
                    ? 'Brahma Muhurta Active Now'
                    : 'Brahma Muhurta ${status.countdownString}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AbhyasTheme.darkInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Window: ${PanchangService.formatTime(panchang.brahmaMuhurta.startTime)} – ${PanchangService.formatTime(panchang.brahmaMuhurta.endTime)}',
            style: const TextStyle(
              fontSize: 13,
              color: AbhyasTheme.darkInkSoft,
            ),
          ),
          if (activeMuhurta != null || activeChoghadiya != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (activeMuhurta != null && activeMuhurta.name != 'Brahma Muhurta')
                  Chip(
                    backgroundColor: activeMuhurta.type == MuhurtaType.inauspicious
                        ? AbhyasTheme.clay.withOpacity(0.3)
                        : AbhyasTheme.sky.withOpacity(0.2),
                    label: Text(
                      'Active: ${activeMuhurta.name}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                if (activeChoghadiya != null)
                  Chip(
                    backgroundColor: activeChoghadiya.color.withOpacity(0.25),
                    label: Text(
                      'Choghadiya: ${activeChoghadiya.name} (${activeChoghadiya.natureLabel})',
                      style: TextStyle(
                        fontSize: 11,
                        color: activeChoghadiya.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanchaAngaSection(DailyPanchang p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome, size: 18, color: AbhyasTheme.saffron),
            SizedBox(width: 8),
            Text(
              'The Five Limbs (Pancha-Anga)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 1. Tithi Card
        _buildAngaCard(
          title: 'Tithi (Lunar Day)',
          sanskrit: p.tithi.fullSanskritTitle,
          mainValue: '${p.tithi.name} · ${p.tithi.pakshaName}',
          detail: 'Deity: ${p.tithi.deity} · ${p.tithi.spiritualSignificance}',
          icon: Icons.brightness_6,
          accentColor: p.tithi.isEkadashi || p.tithi.isPurnima
              ? AbhyasTheme.saffron
              : AbhyasTheme.sky,
          badge: p.tithi.isEkadashi
              ? 'EKADASHI'
              : (p.tithi.isPurnima
                  ? 'PURNIMA'
                  : (p.tithi.isAmavasya
                      ? 'AMAVASYA'
                      : (p.tithi.isPradosha ? 'PRADOSHA' : null))),
        ),
        const SizedBox(height: 10),
        // 2. Vara Card
        _buildAngaCard(
          title: 'Vara (Solar Weekday)',
          sanskrit: p.vara.sanskritName,
          mainValue: '${p.vara.englishDay} (${p.vara.sanskritName})',
          detail:
              'Graha: ${p.vara.rulingGraha} · Element: ${p.vara.element}\nEnergy: ${p.vara.energeticQuality}',
          icon: Icons.calendar_today,
          accentColor: AbhyasTheme.leaf,
        ),
        const SizedBox(height: 10),
        // 3. Nakshatra Card
        _buildAngaCard(
          title: 'Nakshatra (Lunar Mansion)',
          sanskrit: p.nakshatra.sanskritName,
          mainValue:
              '${p.nakshatra.name} · Pada ${p.nakshatra.pada} (${p.nakshatra.guna} Guna)',
          detail:
              'Ruler: ${p.nakshatra.rulingGraha} · Deity: ${p.nakshatra.deity}\nGuidance: ${p.nakshatra.yogicGuidance}',
          icon: Icons.star_border,
          accentColor: AbhyasTheme.hold,
        ),
        const SizedBox(height: 10),
        // 4. Yoga Card
        _buildAngaCard(
          title: 'Yoga (Luni-Solar Harmony)',
          sanskrit: p.yoga.sanskritName,
          mainValue: p.yoga.name,
          detail: 'Significance: ${p.yoga.meaning}',
          icon: Icons.link,
          accentColor: p.yoga.isAuspicious ? AbhyasTheme.leaf : AbhyasTheme.clay,
          badge: p.yoga.isAuspicious ? 'AUSPICIOUS' : 'CAUTION',
        ),
        const SizedBox(height: 10),
        // 5. Karana Card
        _buildAngaCard(
          title: 'Karana (Half Tithi)',
          sanskrit: p.karana.sanskritName,
          mainValue:
              '${p.karana.name} (${p.karana.isMovable ? "Movable / Chara" : "Fixed / Sthira"})',
          detail: 'Quality: ${p.karana.quality}',
          icon: Icons.adjust,
          accentColor: AbhyasTheme.sky,
        ),
      ],
    );
  }

  Widget _buildAngaCard({
    required String title,
    required String sanskrit,
    required String mainValue,
    required String detail,
    required IconData icon,
    required Color accentColor,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AbhyasTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AbhyasTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AbhyasTheme.darkInkSoft,
                ),
              ),
              const Spacer(),
              Text(
                sanskrit,
                style: const TextStyle(
                  fontSize: 12,
                  color: AbhyasTheme.darkInkSoft,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor, width: 0.8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mainValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AbhyasTheme.darkInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              color: AbhyasTheme.darkInkSoft,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarCard(DailyPanchang p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.wb_sunny, color: AbhyasTheme.saffron, size: 20),
                SizedBox(width: 8),
                Text(
                  'Surya & Chandra Transit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSolarItem('Sunrise', PanchangService.formatTime(p.sunrise), Icons.wb_twilight, AbhyasTheme.saffron),
                _buildSolarItem('Solar Noon', PanchangService.formatTime(p.solarNoon), Icons.wb_sunny, Colors.amber),
                _buildSolarItem('Sunset', PanchangService.formatTime(p.sunset), Icons.nightlight_outlined, AbhyasTheme.sky),
              ],
            ),
            const Divider(height: 24, color: AbhyasTheme.line),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Daylight: ${PanchangService.formatDuration(p.daylightDuration)}',
                  style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                ),
                Container(width: 1, height: 14, color: AbhyasTheme.line),
                Text(
                  'Night: ${PanchangService.formatDuration(p.nightDuration)}',
                  style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft)),
      ],
    );
  }

  Widget _buildSacredMuhurtasSection(
      DailyPanchang p, DateTime now, bool isToday) {
    final list = [
      p.brahmaMuhurta,
      p.pratahSandhya,
      p.abhijitMuhurta,
      p.madhyahnaSandhya,
      p.sayamSandhya,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.spa, size: 18, color: AbhyasTheme.saffron),
            SizedBox(width: 8),
            Text(
              'Sacred Muhurtas & Sandhya Kaalas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...list.map((m) => _buildMuhurtaTile(m, now, isToday)),
      ],
    );
  }

  Widget _buildMuhurtaTile(MuhurtaPeriod m, DateTime now, bool isToday) {
    final isCurrent = isToday && m.isCurrent(now);
    final hasPassed = isToday && now.isAfter(m.endTime);

    Color badgeColor = AbhyasTheme.sky;
    String badgeText = 'Upcoming';
    if (isCurrent) {
      badgeColor = AbhyasTheme.saffron;
      badgeText = 'ACTIVE NOW';
    } else if (hasPassed) {
      badgeColor = AbhyasTheme.darkInkSoft;
      badgeText = 'Passed';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? AbhyasTheme.saffron.withOpacity(0.08)
            : AbhyasTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AbhyasTheme.saffron : AbhyasTheme.line,
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      m.sanskritName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AbhyasTheme.darkInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${PanchangService.formatTime(m.startTime)} – ${PanchangService.formatTime(m.endTime)} (${m.duration(now).inMinutes} min)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AbhyasTheme.darkInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            m.description,
            style: const TextStyle(
              fontSize: 12,
              color: AbhyasTheme.darkInkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.self_improvement,
                  size: 14, color: AbhyasTheme.leaf),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Recommended: ${m.yogicPractice}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AbhyasTheme.leaf,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (m.name == 'Brahma Muhurta') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Begin Morning Sadhana'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CycleComposerScreen()),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInauspiciousKalasSection(
      DailyPanchang p, DateTime now, bool isToday) {
    final kalas = [p.rahuKalam, p.yamaGandam, p.gulikaKalam];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.shield_outlined, size: 18, color: AbhyasTheme.clay),
            SizedBox(width: 8),
            Text(
              'Kaala Windows (Restraint & Inner Japa)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...kalas.map((k) {
          final isCurrent = isToday && k.isCurrent(now);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AbhyasTheme.clay.withOpacity(0.12)
                  : AbhyasTheme.darkSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent ? AbhyasTheme.clay : AbhyasTheme.line,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            k.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${k.sanskritName})',
                            style: const TextStyle(
                              color: AbhyasTheme.darkInkSoft,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${PanchangService.formatTime(k.startTime)} – ${PanchangService.formatTime(k.endTime)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AbhyasTheme.darkInk,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AbhyasTheme.clay,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AbhyasTheme.darkBg,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChoghadiyaSection(DailyPanchang p, DateTime now, bool isToday) {
    final list = _showDayChoghadiya ? p.dayChoghadiya : p.nightChoghadiya;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.access_time, size: 18, color: AbhyasTheme.saffron),
                SizedBox(width: 8),
                Text(
                  'Choghadiya Timings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Day', style: TextStyle(fontSize: 12)),
                  selected: _showDayChoghadiya,
                  onSelected: (val) {
                    setState(() {
                      _showDayChoghadiya = true;
                    });
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Night', style: TextStyle(fontSize: 12)),
                  selected: !_showDayChoghadiya,
                  onSelected: (val) {
                    setState(() {
                      _showDayChoghadiya = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...list.map((c) {
          final isCurrent = isToday && c.isCurrent(now);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent
                  ? c.color.withOpacity(0.15)
                  : AbhyasTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent ? c.color : AbhyasTheme.line,
                width: isCurrent ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: c.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${c.natureLabel})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AbhyasTheme.darkInkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${PanchangService.formatTime(c.startTime)} – ${PanchangService.formatTime(c.endTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AbhyasTheme.darkBg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSvaraYogaSection(DailyPanchang p) {
    final svara = p.svaraRecommendation;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AbhyasTheme.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AbhyasTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.air, color: AbhyasTheme.sky, size: 22),
              SizedBox(width: 10),
              Text(
                'Svara Yoga Alignment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Recommended Nadi: ${svara.nadiName}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AbhyasTheme.saffron,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Governing Elements: ${svara.dominantElement}',
            style: const TextStyle(fontSize: 13, color: AbhyasTheme.darkInkSoft),
          ),
          const SizedBox(height: 8),
          Text(
            svara.guidance,
            style: const TextStyle(
              fontSize: 12,
              color: AbhyasTheme.darkInk,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Harmonizing Practices:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AbhyasTheme.darkInkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: svara.recommendedPranayamas.map((pranayama) {
              return Chip(
                backgroundColor: AbhyasTheme.darkSurface,
                side: const BorderSide(color: AbhyasTheme.line),
                label: Text(
                  pranayama,
                  style: const TextStyle(fontSize: 12, color: AbhyasTheme.darkInk),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
