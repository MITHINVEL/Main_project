import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:math' as math;
import '../../services/weather_service.dart';
import '../../models/solar_analytics_model.dart';
import '../../services/solar_energy_service.dart';
import '../street_light/add_street_light_screen.dart';
import '../../widgets/analytics_card.dart';
import '../../widgets/energy_chart.dart';
import '../../widgets/solar_prediction_card.dart';

// SolarEnergyService is implemented in lib/services/solar_energy_service.dart

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;

  // Use SolarEnergyService; if you have an NREL API key, pass it here.
  final SolarEnergyService _solarService = SolarEnergyService();

  // Data variables
  SolarAnalyticsModel? _analyticsData;
  List<Map<String, dynamic>> _solarStreetLights = [];
  dynamic _weatherData;
  Map<String, dynamic>? _energyPrediction;
  bool _isLoading = true;
  bool _hasData = true;

  // UI State
  int _selectedTimeRange = 0; // 0: Today, 1: Week, 2: Month
  final List<String> _timeRanges = ['Today', 'This Week', 'This Month'];
  // Filter / load field
  final TextEditingController _loadFieldController = TextEditingController();
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAnalyticsData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _animationController.forward();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data in parallel
      await Future.wait([
        _loadSolarStreetLights(),
        _loadWeatherData(),
        _loadEnergyPredictions(),
      ]);

      // If no active street lights found, try a fallback (load all user's street lights)
      if (_solarStreetLights.isEmpty) {
        // Fallback: try loading all user's street lights without isActive filter
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final qs = await FirebaseFirestore.instance
                .collection('street_lights')
                .where('createdBy', isEqualTo: user.uid)
                .get();
            _solarStreetLights = qs.docs
                .map((d) => {...d.data(), 'id': d.id})
                .toList();
            print(
              'Fallback loaded ${_solarStreetLights.length} street lights for user ${user.email}',
            );
          }
        } catch (e) {
          print('Fallback fetch error: $e');
        }
      }

      // Calculate analytics based on loaded data (or show empty state)
      if (_solarStreetLights.isEmpty) {
        _hasData = false;
        // Provide a minimal analytics model with zeros so UI can render consistently
        _analyticsData = SolarAnalyticsModel(
          totalStreetLights: 0,
          activeLights: 0,
          totalEnergyConsumption: 0.0,
          totalSolarGeneration: 0.0,
          energySavings: 0.0,
          efficiencyPercentage: 0.0,
          weatherCondition: 'No data',
          temperature: 0.0,
          prediction: null,
        );
      } else {
        _hasData = true;
        _calculateAnalytics();
      }
    } catch (e) {
      print('Error loading analytics data: $e');
      _showErrorSnackBar('Failed to load analytics data');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSolarStreetLights() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, cannot load street lights');
        return;
      }

      // Load street lights for current user only
      final querySnapshot = await FirebaseFirestore.instance
          .collection('street_lights')
          .where('createdBy', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      _solarStreetLights = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();

      print(
        'Loaded ${_solarStreetLights.length} solar street lights for user ${user.email}',
      );
    } catch (e) {
      print('Error loading solar street lights: $e');
    }
  }

  Future<void> _loadWeatherData() async {
    try {
      // Get weather data for solar prediction
      // WeatherService expects lat, lon; use a best-effort fallback (0,0) or derive from first street light
      double lat = 0.0;
      double lon = 0.0;
      if (_solarStreetLights.isNotEmpty) {
        final first = _solarStreetLights.first;
        lat = (first['latitude'] ?? first['lat'] ?? 0.0).toDouble();
        lon = (first['longitude'] ?? first['lng'] ?? 0.0).toDouble();
      }
      final weatherObj = await WeatherService.getCurrentWeather(lat, lon);
      if (weatherObj != null) {
        // Convert WeatherData object to a map-like structure the analytics page expects
        _weatherData = {
          'temperature': weatherObj.temperature,
          'description': weatherObj.description,
          'cloudCover':
              0, // demo data; WeatherService mock doesn't provide cloud cover
          'condition': weatherObj.description,
        };
      } else {
        _weatherData = null;
      }
      print('Weather data loaded: ${_weatherData.toString()}');
    } catch (e) {
      print('Error loading weather data: $e');
    }
  }

  Future<void> _loadEnergyPredictions() async {
    try {
      if (_weatherData != null && _solarStreetLights.isNotEmpty) {
        _energyPrediction = await _solarService.calculateEnergyPrediction(
          streetLights: _solarStreetLights,
          weatherData: _weatherData!,
          timeRange: _timeRanges[_selectedTimeRange],
        );
        print('Energy predictions calculated: ${_energyPrediction.toString()}');
      }
    } catch (e) {
      print('Error calculating energy predictions: $e');
    }
  }

  void _calculateAnalytics() {
    if (_solarStreetLights.isEmpty) return;

    // Calculate total energy consumption and generation
    double totalConsumption = 0;
    double totalSolarGeneration = 0;
    int activeLights = 0;

    for (var light in _solarStreetLights) {
      if (light['status'] == 'on') {
        activeLights++;
        totalConsumption +=
            (light['powerConsumption'] ?? 0.0) *
            (light['brightness'] ?? 100) /
            100;
      }

      // Calculate solar generation based on weather
      if (_weatherData != null) {
        totalSolarGeneration += _solarService.calculateSolarOutput(
          panelWattage: 50.0, // Assume 50W solar panels
          sunlightHours: _getSunlightHours(),
          cloudCover: _weatherData!['cloudCover'] ?? 0,
        );
      }
    }

    _analyticsData = SolarAnalyticsModel(
      totalStreetLights: _solarStreetLights.length,
      activeLights: activeLights,
      totalEnergyConsumption: totalConsumption,
      totalSolarGeneration: totalSolarGeneration,
      energySavings: totalSolarGeneration - totalConsumption,
      efficiencyPercentage: totalConsumption > 0
          ? (totalSolarGeneration / totalConsumption * 100)
          : 0,
      weatherCondition: _weatherData?['condition'] ?? 'Unknown',
      temperature: _weatherData?['temperature'] ?? 0,
      prediction: _energyPrediction,
    );
  }

  double _getSunlightHours() {
    final now = DateTime.now();
    if (now.hour >= 6 && now.hour <= 18) {
      return 8.0; // Average sunlight hours
    }
    return 0.0;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _loadFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomPaint(
        painter: SolarAnalyticsBackgroundPainter(_backgroundController.value),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildLoadFieldRow(),
              _buildTimeRangeSelector(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadAnalyticsData();
                  },
                  child: _isLoading
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400.h,
                            child: _buildLoadingState(),
                          ),
                        )
                      : _buildAnalyticsContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: const Color(0xFF2D3748),
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solar Analytics',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Text(
                'Smart Energy Insights',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF718096),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Iconsax.sun_1,
              color: const Color(0xFF10B981),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
              ],
            ),
            child: IconButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                await _loadAnalyticsData();
                if (mounted) setState(() => _isLoading = false);
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analytics refreshed')),
                  );
              },
              icon: const Icon(Icons.refresh, color: Color(0xFF667EEA)),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3, duration: 600.ms);
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_timeRanges.length, (index) {
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                setState(() {
                  _selectedTimeRange = index;
                });
                await _loadEnergyPredictions();
                _calculateAnalytics();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _selectedTimeRange == index
                      ? const Color(0xFF667EEA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _timeRanges[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _selectedTimeRange == index
                        ? Colors.white
                        : const Color(0xFF718096),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 600.ms);
  }

  Widget _buildLoadFieldRow() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _loadFieldController,
              decoration: InputDecoration(
                hintText: 'Enter GSM Number or Street Light No',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _isFiltering
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20.sp),
                        onPressed: () async {
                          _loadFieldController.clear();
                          setState(() {
                            _isFiltering = false;
                          });
                          await _loadAnalyticsData();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadForIdentifier(),
            ),
          ),
          SizedBox(width: 10.w),
          ElevatedButton(
            onPressed: _isLoading ? null : _loadForIdentifier,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: Text('Load'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadForIdentifier() async {
    final q = _loadFieldController.text.trim();
    if (q.isEmpty) {
      // clear filter and reload
      setState(() {
        _isFiltering = false;
        _isLoading = true;
      });
      await _loadAnalyticsData();
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isFiltering = true;
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('User not logged in');
        return;
      }

      // Try to find by GSM number field
      final coll = FirebaseFirestore.instance.collection('street_lights');
      QuerySnapshot<Map<String, dynamic>> qs = await coll
          .where('createdBy', isEqualTo: user.uid)
          .where('gsmNumber', isEqualTo: q)
          .get();
      if (qs.docs.isEmpty) {
        // Try by streetLightNumber or name
        qs = await coll
            .where('createdBy', isEqualTo: user.uid)
            .where('streetLightNumber', isEqualTo: q)
            .get();
      }

      if (qs.docs.isEmpty) {
        // No exact match; try a 'contains' like search on name (client-side)
        final all = await coll.where('createdBy', isEqualTo: user.uid).get();
        final matches = all.docs.where((d) {
          final data = d.data();
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(q.toLowerCase());
        }).toList();

        if (matches.isEmpty) {
          _showErrorSnackBar('No street light found for "$q"');
          // keep previous data
        } else {
          _solarStreetLights = matches
              .map((d) => {...d.data(), 'id': d.id})
              .toList();
        }
      } else {
        _solarStreetLights = qs.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList();
      }

      // Reload weather for the selected light(s) and recalc predictions
      await _loadWeatherData();
      await _loadEnergyPredictions();
      _calculateAnalytics();
    } catch (e) {
      print('Error loading for identifier $q: $e');
      _showErrorSnackBar('Failed to load data for $q');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Iconsax.sun_1,
              size: 48.sp,
              color: const Color(0xFF667EEA),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Calculating Solar Analytics...',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Analyzing weather data and energy predictions',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
          ),
          SizedBox(height: 30.h),
          SizedBox(
            width: 200.w,
            child: LinearProgressIndicator(
              backgroundColor: const Color(0xFF667EEA).withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF667EEA),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildAnalyticsContent() {
    if (!_hasData || _analyticsData == null) {
      return _buildEmptyAnalyticsState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          SizedBox(height: 10.h),
          _buildOverviewCards(),
          SizedBox(height: 20.h),
          _buildEnergyChart(),
          SizedBox(height: 20.h),
          _buildSolarPredictionCard(),
          SizedBox(height: 20.h),
          _buildWeatherCard(),
          SizedBox(height: 20.h),
          _buildSolarStreetLightsGrid(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalyticsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.sun_1, size: 64.sp, color: const Color(0xFF667EEA)),
            SizedBox(height: 16.h),
            Text(
              'No Street Light Data',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'We could not find any active street light entries. Add a street light or refresh to try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await _loadAnalyticsData();
                    setState(() => _isLoading = false);
                  },
                  child: Text('Refresh'),
                ),
                SizedBox(width: 12.w),
                OutlinedButton(
                  onPressed: () async {
                    final res = await Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const AddStreetLightScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                    if (res == true) {
                      await _loadAnalyticsData();
                    }
                  },
                  child: Text('Add Street Light'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: AnalyticsCard(
            title: 'Active Lights',
            value: '${_analyticsData!.activeLights}',
            subtitle: 'of ${_analyticsData!.totalStreetLights}',
            icon: Iconsax.lamp_on,
            color: const Color(0xFF10B981),
            animationDelay: 0,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AnalyticsCard(
            title: 'Energy Saved',
            value: '${_analyticsData!.energySavings.toStringAsFixed(1)}kW',
            subtitle: 'Today',
            icon: Iconsax.battery_charging,
            color: const Color(0xFF667EEA),
            animationDelay: 100,
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyChart() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart, color: const Color(0xFF667EEA), size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Energy Overview',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          EnergyChart(
            consumptionData: _analyticsData!.totalEnergyConsumption,
            generationData: _analyticsData!.totalSolarGeneration,
            timeRange: _timeRanges[_selectedTimeRange],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, delay: 400.ms, duration: 600.ms);
  }

  Widget _buildSolarPredictionCard() {
    return SolarPredictionCard(
      prediction: _analyticsData!.prediction,
      weatherData: _weatherData,
      animationDelay: 600,
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.sun_1, color: Colors.white, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Weather Conditions',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_analyticsData!.temperature.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _analyticsData!.weatherCondition,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Solar Efficiency\n${_analyticsData!.efficiencyPercentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, delay: 800.ms, duration: 600.ms);
  }

  Widget _buildSolarStreetLightsGrid() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.lamp_on,
                color: const Color(0xFF667EEA),
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Solar Street Lights',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_solarStreetLights.length} Lights',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.2,
            ),
            itemCount: _solarStreetLights.take(6).length,
            itemBuilder: (context, index) {
              final light = _solarStreetLights[index];
              return _buildSolarLightCard(light, index);
            },
          ),
          if (_solarStreetLights.length > 6)
            Padding(
              padding: EdgeInsets.only(top: 15.h),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full lights list
                  },
                  child: Text(
                    'View All ${_solarStreetLights.length} Lights',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF667EEA),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().slideY(begin: 0.3, delay: 1000.ms, duration: 600.ms);
  }

  Widget _buildSolarLightCard(Map<String, dynamic> light, int index) {
    final isActive = light['status'] == 'on';
    final brightness = light['brightness'] ?? 100;
    final powerConsumption = light['powerConsumption'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isActive
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFF718096),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Iconsax.lamp_on, color: Colors.white, size: 16.sp),
              ),
              const Spacer(),
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFF718096),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            light['name'] ?? 'Street Light ${index + 1}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            light['area'] ?? 'Unknown Area',
            style: TextStyle(fontSize: 10.sp, color: const Color(0xFF718096)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Iconsax.flash_1,
                color: const Color(0xFF667EEA),
                size: 12.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                '${powerConsumption.toStringAsFixed(1)}W',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF667EEA),
                ),
              ),
              const Spacer(),
              if (isActive)
                Text(
                  '$brightness%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF10B981),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      delay: (1200 + index * 100).ms,
      duration: 400.ms,
    );
  }
}

// Custom Painter for Solar Analytics Background
class SolarAnalyticsBackgroundPainter extends CustomPainter {
  final double animationValue;

  SolarAnalyticsBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Animated solar rays
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30.0 + animationValue * 30) * (3.14159 / 180);
      final offset = Offset(
        size.width * 0.9 + 80 * math.cos(angle),
        size.height * 0.1 + 80 * math.sin(angle),
      );

      paint.color = const Color(0xFFFBBF24).withOpacity(0.03);
      canvas.drawCircle(offset, 8 + (i * 0.5), paint);
    }

    // Energy flow particles
    for (int i = 0; i < 8; i++) {
      final offset = Offset(
        (size.width * 0.1 * i) + (60 * (animationValue + i * 0.2).remainder(1)),
        (size.height * 0.8) + (20 * math.sin(animationValue * 2 + i)),
      );

      paint.color = const Color(0xFF10B981).withOpacity(0.02);
      canvas.drawCircle(offset, 6 + (i * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
