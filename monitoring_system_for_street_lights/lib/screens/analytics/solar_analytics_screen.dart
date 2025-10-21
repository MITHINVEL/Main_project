import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../services/weather_service.dart';
import '../../models/solar_analytics_model.dart';
import '../../services/solar_energy_service.dart';
import '../../services/solar_prediction_service.dart';
import '../../services/real_time_analytics_service.dart';
import '../street_light/add_street_light_screen.dart';
import '../street_light/street_light_detail_screen.dart';

class SolarAnalyticsScreen extends StatefulWidget {
  const SolarAnalyticsScreen({super.key});

  @override
  State<SolarAnalyticsScreen> createState() => _SolarAnalyticsScreenState();
}

class _SolarAnalyticsScreenState extends State<SolarAnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Energy prediction data with battery consumption consideration
  Map<String, double> _dailyEnergyData = {};
  Map<String, double> _weeklyEnergyData = {};
  Map<String, double> _monthlyEnergyData = {};
  double _batteryEfficiency = 85.0; // Battery efficiency percentage
  double _expectedDailyConsumption = 0.0;

  // Solar prediction data
  final SolarPredictionService _solarPredictionService =
      SolarPredictionService();
  List<Map<String, dynamic>> _solarPredictions = [];
  bool _isLoadingPredictions = false;
  String? _predictionError;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAnalyticsData();
    _generateEnergyPredictions();
    _loadSolarPredictions();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _animationController.forward();
  }

  void _generateEnergyPredictions() {
    final now = DateTime.now();

    // Calculate expected daily consumption based on street lights
    _expectedDailyConsumption = _solarStreetLights.fold<double>(
      0.0,
      (sum, light) =>
          sum +
          ((light['powerConsumption'] ?? 25.0) *
              12 /
              1000), // 12 hours operation
    );

    // Daily predictions (24 hours) - Solar generation vs consumption
    for (int i = 0; i < 24; i++) {
      final hour = i;
      double solarGeneration = 0;
      double consumption = 0;

      if (hour >= 6 && hour <= 18) {
        // Solar generation hours with realistic curve
        final peak = 12; // Peak at noon
        final distance = (hour - peak).abs();
        final efficiency = _weatherData != null
            ? (100 - (_weatherData['cloudCover'] ?? 20)) / 100
            : 0.8;
        solarGeneration =
            math.max(0, (80 - (distance * distance * 1.5)) * efficiency) +
            (math.Random().nextDouble() * 15 - 7.5);
      }

      // Street lights consume energy during night hours
      if (hour >= 18 || hour <= 6) {
        consumption =
            _expectedDailyConsumption / 12; // Distribute over 12 night hours
      }

      _dailyEnergyData['${hour.toString().padLeft(2, '0')}:00'] = math.max(
        0,
        solarGeneration - consumption,
      );
    }

    // Weekly predictions (7 days)
    for (int i = 0; i < 7; i++) {
      final day = now.add(Duration(days: i - 3));
      final dayName = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][day.weekday - 1];
      final baseGeneration = 120 + (math.Random().nextDouble() * 60);
      final weatherVariation =
          math.Random().nextDouble() * 0.3 + 0.7; // 70-100% efficiency
      _weeklyEnergyData[dayName] =
          baseGeneration * weatherVariation - _expectedDailyConsumption;
    }

    // Monthly predictions (30 days)
    for (int i = 0; i < 30; i++) {
      final day = now.add(Duration(days: i - 15));
      final seasonalFactor =
          math.cos((day.month - 6) * math.pi / 6) * 0.3 +
          0.7; // Seasonal variation
      final baseGeneration = 100 * seasonalFactor;
      _monthlyEnergyData['${day.day}'] =
          baseGeneration +
          (math.Random().nextDouble() * 40) -
          _expectedDailyConsumption;
    }
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Loading real-time analytics data...');

      // Fetch real-time data from server and APIs
      final realTimeData =
          await RealTimeAnalyticsService.getRealTimeAnalytics();

      if (realTimeData['success'] == true) {
        print('✅ Real-time data loaded successfully');

        // Update street lights with real-time data
        _solarStreetLights = List<Map<String, dynamic>>.from(
          realTimeData['streetLights'] ?? [],
        );

        // Update weather data
        final weather = realTimeData['weather'] ?? {};
        _weatherData = {
          'temperature': weather['main']?['temp'] ?? 25.0,
          'description': weather['weather']?[0]?['description'] ?? 'clear sky',
          'cloudCover': weather['clouds']?['all'] ?? 20,
          'condition': weather['weather']?[0]?['main'] ?? 'Clear',
          'humidity': weather['main']?['humidity'] ?? 60,
          'windSpeed': weather['wind']?['speed'] ?? 5.0,
          'icon': weather['weather']?[0]?['icon'] ?? '01d',
        };

        // Update energy data with real-time calculations
        final energyData = realTimeData['energyData'] ?? {};
        _dailyEnergyData = Map<String, double>.from(energyData['daily'] ?? {});
        _weeklyEnergyData = Map<String, double>.from(
          energyData['weekly'] ?? {},
        );
        _monthlyEnergyData = Map<String, double>.from({
          'Week 1': _weeklyEnergyData.values.fold(0.0, (a, b) => a + b) * 0.25,
          'Week 2': _weeklyEnergyData.values.fold(0.0, (a, b) => a + b) * 0.27,
          'Week 3': _weeklyEnergyData.values.fold(0.0, (a, b) => a + b) * 0.23,
          'Week 4': _weeklyEnergyData.values.fold(0.0, (a, b) => a + b) * 0.25,
        });

        // Create analytics model from real-time data
        final analytics = realTimeData['analytics'] ?? {};
        _analyticsData = SolarAnalyticsModel(
          totalStreetLights: analytics['totalLights'] ?? 0,
          activeLights: analytics['activeLights'] ?? 0,
          totalEnergyConsumption: (analytics['powerConsumption'] ?? 0.0)
              .toDouble(),
          totalSolarGeneration: (analytics['solarProduction'] ?? 0.0)
              .toDouble(),
          energySavings: (analytics['energyBalance'] ?? 0.0).toDouble(),
          efficiencyPercentage: (analytics['systemEfficiency'] ?? 0.0)
              .toDouble(),
          weatherCondition: _weatherData?['description'] ?? 'Unknown',
          temperature: (_weatherData?['temperature'] ?? 0.0).toDouble(),
          prediction: {
            'message':
                'Real-time data updated at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            'timestamp': DateTime.now().toIso8601String(),
            'source': 'real-time-api',
          },
        );

        _hasData = _solarStreetLights.isNotEmpty;

        print(
          '📊 Analytics updated: ${_analyticsData?.totalStreetLights} lights, ${_analyticsData?.activeLights} active',
        );
      } else {
        print('⚠️ Real-time data failed, using fallback');
        await _loadFallbackData();
      }

      // Load solar predictions with real-time data
      await _loadSolarPredictions();
    } catch (e) {
      print('❌ Error loading real-time analytics: $e');
      _showErrorSnackBar(
        'Loading real-time data... Using cached data temporarily',
      );
      await _loadFallbackData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Load fallback data when real-time service fails
  Future<void> _loadFallbackData() async {
    await Future.wait([
      _loadSolarStreetLights(),
      _loadWeatherData(),
      _loadEnergyPredictions(),
    ]);

    if (_solarStreetLights.isEmpty) {
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
        }
      } catch (e) {
        print('Fallback fetch error: $e');
      }
    }

    if (_solarStreetLights.isEmpty) {
      _hasData = false;
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
  }

  Future<void> _loadSolarStreetLights() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Query query = FirebaseFirestore.instance
          .collection('street_lights')
          .where('createdBy', isEqualTo: user.uid);

      if (_isSearching && _searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        query = query.where('name', isGreaterThanOrEqualTo: searchTerm);
      }

      final querySnapshot = await query.get();

      _solarStreetLights = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();

      print('Loaded ${_solarStreetLights.length} solar street lights');
    } catch (e) {
      print('Error loading solar street lights: $e');
    }
  }

  Future<void> _loadWeatherData() async {
    try {
      double lat = 0.0;
      double lon = 0.0;
      if (_solarStreetLights.isNotEmpty) {
        final first = _solarStreetLights.first;
        lat = (first['latitude'] ?? first['lat'] ?? 0.0).toDouble();
        lon = (first['longitude'] ?? first['lng'] ?? 0.0).toDouble();
      }

      final weatherObj = await WeatherService.getCurrentWeather(lat, lon);
      if (weatherObj != null) {
        _weatherData = {
          'temperature': weatherObj.temperature,
          'description': weatherObj.description,
          'cloudCover': 20, // Demo value
          'condition': weatherObj.description,
          'humidity': weatherObj.humidity,
          'windSpeed': weatherObj.windSpeed,
          'icon': weatherObj.icon,
        };
      }
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
      }
    } catch (e) {
      print('Error calculating energy predictions: $e');
    }
  }

  void _calculateAnalytics() {
    if (_solarStreetLights.isEmpty) return;

    double totalConsumption = 0;
    double totalSolarGeneration = 0;
    int activeLights = 0;

    for (var light in _solarStreetLights) {
      final isActive = light['status'] == 'on' || light['isActive'] == true;
      if (isActive) {
        activeLights++;
        final power = (light['powerConsumption'] ?? 25).toDouble();
        final brightness = (light['brightness'] ?? 100).toDouble() / 100.0;
        totalConsumption +=
            power * brightness * 12.0 / 1000.0; // 12 hours operation in kWh
      }

      // Calculate solar generation based on weather
      if (_weatherData != null) {
        final panelWattage = (light['panelWattage'] ?? 50).toDouble();
        totalSolarGeneration += _solarService.calculateSolarOutput(
          panelWattage: panelWattage,
          sunlightHours: _getSunlightHours(),
          cloudCover: (_weatherData!['cloudCover'] ?? 20).toDouble(),
        );
      }
    }

    // Apply battery efficiency
    final effectiveSolarGeneration =
        totalSolarGeneration * (_batteryEfficiency / 100.0);

    _analyticsData = SolarAnalyticsModel(
      totalStreetLights: _solarStreetLights.length,
      activeLights: activeLights,
      totalEnergyConsumption: totalConsumption,
      totalSolarGeneration: effectiveSolarGeneration,
      energySavings: effectiveSolarGeneration - totalConsumption,
      efficiencyPercentage: totalConsumption > 0
          ? (effectiveSolarGeneration / totalConsumption * 100)
          : 0,
      weatherCondition: _weatherData?['condition'] ?? 'Unknown',
      temperature: _weatherData?['temperature'] ?? 0,
      prediction: _energyPrediction,
    );
  }

  double _getSunlightHours() {
    final now = DateTime.now();
    if (now.hour >= 6 && now.hour <= 18) {
      return 8.0 + (math.Random().nextDouble() * 2 - 1); // 7-9 hours variation
    }
    return 0.0;
  }

  // Solar Prediction Methods
  Future<void> _loadSolarPredictions() async {
    setState(() {
      _isLoadingPredictions = true;
      _predictionError = null;
    });

    try {
      print('🌞 Loading real-time solar predictions...');

      // Get real-time location-based coordinates
      double latitude = 11.3410; // Erode, Tamil Nadu (default)
      double longitude = 77.7172;

      // Use first street light location if available
      if (_solarStreetLights.isNotEmpty) {
        final firstLight = _solarStreetLights.first;
        latitude = (firstLight['latitude'] ?? firstLight['lat'] ?? 11.3410)
            .toDouble();
        longitude = (firstLight['longitude'] ?? firstLight['lng'] ?? 77.7172)
            .toDouble();
      }

      // Calculate real system capacity based on actual street lights
      final totalWattage = _solarStreetLights.fold<double>(
        0.0,
        (sum, light) => sum + (light['panelWattage'] ?? 50.0).toDouble(),
      );
      final systemCapacity = totalWattage / 1000.0; // Convert to kW

      print('📍 Using location: $latitude, $longitude');
      print(
        '⚡ System capacity: ${systemCapacity}kW from ${_solarStreetLights.length} lights',
      );

      final response = await (_solarPredictionService as dynamic)
          .getSolarPrediction(
            latitude: latitude,
            longitude: longitude,
            systemCapacity: math.max(0.1, systemCapacity), // Minimum 0.1kW
            days: 7,
          );

      if (response['success'] == true) {
        final predictions = List<Map<String, dynamic>>.from(
          response['predictions'],
        );

        // Enhance predictions with real-time data
        for (int i = 0; i < predictions.length; i++) {
          final prediction = predictions[i];

          // Add real-time enhancements
          prediction['realTimeUpdated'] = DateTime.now().toIso8601String();
          prediction['systemSize'] = '${systemCapacity.toStringAsFixed(1)}kW';
          prediction['lightsCount'] = _solarStreetLights.length;
          prediction['dataSource'] =
              'Real-time APIs (OpenWeatherMap + Solar Calculations)';

          // Calculate per-light energy generation
          if (prediction['energyGeneration'] != null &&
              _solarStreetLights.isNotEmpty) {
            prediction['energyPerLight'] =
                (prediction['energyGeneration'] / _solarStreetLights.length)
                    .toStringAsFixed(1);
          }
        }

        setState(() {
          _solarPredictions = predictions;
          _isLoadingPredictions = false;
        });

        print('✅ Solar predictions loaded: ${predictions.length} days of data');
      } else {
        setState(() {
          _predictionError =
              response['error'] ?? 'Failed to load real-time predictions';
          _solarPredictions = List<Map<String, dynamic>>.from(
            response['predictions'] ?? [],
          );
          _isLoadingPredictions = false;
        });
        print('⚠️ Prediction error: ${response['error']}');
      }
    } catch (e) {
      setState(() {
        _predictionError = 'Error loading real-time solar predictions: $e';
        _isLoadingPredictions = false;
        _solarPredictions = [];
      });
      print('❌ Solar prediction error: $e');
    }
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
    _pulseController.dispose();
    _rotationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure status bar icons are dark (visible) on light backgrounds for this screen.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: CustomPaint(
          painter: LuxuryBackgroundPainter(_backgroundController.value),
          child: Column(
            children: [
              _buildLuxuryHeader(),
              _buildTimeRangeSelector(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadAnalyticsData();
                    _generateEnergyPredictions();
                  },
                  child: _isLoading
                      ? _buildLoadingState()
                      : _buildAnalyticsContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryHeader() {
    return Container(
      padding: EdgeInsets.only(top: 30.w, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
            const Color(0xFF667EEA).withOpacity(0.8),
          ],
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'Solar Analytics',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Smart Energy Intelligence',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(6.w),
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
      child: Row(
        children: List.generate(_timeRanges.length, (index) {
          final isSelected = _selectedTimeRange == index;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                setState(() => _selectedTimeRange = index);
                await _loadEnergyPredictions();
                _generateEnergyPredictions();
                _calculateAnalytics();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  _timeRanges[index],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF718096),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().slideY(begin: 0.3, delay: 400.ms, duration: 600.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.2),
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Icon(Iconsax.sun_1, size: 48.sp, color: Colors.white),
                ),
              );
            },
          ),
          SizedBox(height: 30.h),
          Text(
            'Analyzing Solar Data...',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Processing weather conditions and energy predictions',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
          ),
          SizedBox(height: 40.h),
          Container(
            width: 250.w,
            height: 6.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.r),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.2),
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 1000.ms);
  }

  Widget _buildAnalyticsContent() {
    if (!_hasData || _analyticsData == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          _buildOverviewCards(),
          SizedBox(height: 24.h),
          _buildEnergyChart(),
          SizedBox(height: 24.h),
          _buildBatteryEfficiencyCard(),
          SizedBox(height: 24.h),
          _buildPredictionCards(),
          SizedBox(height: 24.h),

          SizedBox(height: 14.h),
          _buildStreetLightsGrid(),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.1),
                    const Color(0xFF764BA2).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Icon(
                Iconsax.sun_1,
                size: 64.sp,
                color: const Color(0xFF667EEA),
              ),
            ),
            SizedBox(height: 30.h),
            Text(
              'No Solar Data Available',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Add solar street lights to view energy analytics and predictions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF718096),
                height: 1.5,
              ),
            ),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await _loadAnalyticsData();
                    _generateEnergyPredictions();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 16.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddStreetLightScreen(),
                      ),
                    );
                    if (result == true) {
                      await _loadAnalyticsData();
                      _generateEnergyPredictions();
                    }
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add Light'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667EEA),
                    side: BorderSide(color: const Color(0xFF667EEA)),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 16.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
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
          child: _buildStatCard(
            'Active Lights',
            '${_analyticsData!.activeLights}',
            'of ${_analyticsData!.totalStreetLights}',
            Iconsax.lamp_on,
            const Color(0xFF10B981),
            0,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatCard(
            'Energy Saved',
            '${_analyticsData!.energySavings.toStringAsFixed(1)}',
            'kWh Today',
            Iconsax.battery_charging,
            const Color(0xFF667EEA),
            100,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    int delay,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF718096)),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, delay: delay.ms, duration: 600.ms);
  }

  Widget _buildEnergyChart() {
    Map<String, double> currentData;
    String chartTitle;

    switch (_selectedTimeRange) {
      case 0:
        currentData = _dailyEnergyData;
        chartTitle = 'Daily Energy Flow (24h)';
        break;
      case 1:
        currentData = _weeklyEnergyData;
        chartTitle = 'Weekly Energy Predictions';
        break;
      case 2:
        currentData = _monthlyEnergyData;
        chartTitle = 'Monthly Energy Forecast';
        break;
      default:
        currentData = _dailyEnergyData;
        chartTitle = 'Daily Energy Flow (24h)';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Iconsax.chart, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chartTitle,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Net energy after consumption',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h), // Reduced spacing
          SizedBox(
            height: 200.h,
            child: _buildCustomChart(currentData),
          ), // Reduced height
        ],
      ),
    ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 600.ms);
  }

  Widget _buildCustomChart(Map<String, double> data) {
    if (data.isEmpty) return Container();

    final maxValue = data.values.reduce(math.max);
    final minValue = data.values.reduce(math.min);
    final range = maxValue - minValue;

    return SingleChildScrollView(
      // Add scrollview to prevent overflow
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: data.entries.map((entry) {
          final normalizedHeight = range > 0
              ? ((entry.value - minValue) / range)
              : 0.5;
          final height = math.max(
            8,
            normalizedHeight * 140.h,
          ); // Reduced max height
          final isPositive = entry.value >= 0;

          return Container(
            width: 25.w, // Fixed width to prevent overflow
            margin: EdgeInsets.symmetric(horizontal: 1.w), // Reduced margin
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min, // Prevent overflow
              children: [
                // Value text with constraint
                if (entry.value > 0)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 15.h, // Limit text height
                      maxWidth: 25.w,
                    ),
                    child: Text(
                      '${entry.value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 8.sp, // Reduced font size
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                SizedBox(height: 4.h), // Reduced spacing
                // Chart bar
                Container(
                  height: height.toDouble(),
                  width: 12.w, // Fixed bar width
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isPositive
                          ? [
                              const Color(0xFF10B981).withOpacity(0.7),
                              const Color(0xFF10B981),
                            ]
                          : [
                              const Color(0xFFEF4444).withOpacity(0.7),
                              const Color(0xFFEF4444),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(2.r), // Reduced radius
                  ),
                ),
                SizedBox(height: 4.h), // Reduced spacing
                // Label text with constraint
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 15.h, // Limit text height
                    maxWidth: 25.w,
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 7.sp, // Further reduced font size
                      color: const Color(0xFF718096),
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBatteryEfficiencyCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF10B981), const Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Iconsax.battery_charging, color: Colors.white, size: 24.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Battery Efficiency',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Energy storage and consumption',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_batteryEfficiency.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildBatteryMetric(
                  'Daily Consumption',
                  '${_expectedDailyConsumption.toStringAsFixed(1)} kWh',
                  Iconsax.flash_1,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildBatteryMetric(
                  'Energy Stored',
                  '${(_analyticsData?.totalSolarGeneration ?? 0 * 0.85).toStringAsFixed(1)} kWh',
                  Iconsax.battery_full,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, delay: 300.ms, duration: 600.ms);
  }

  Widget _buildBatteryMetric(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildPredictionCard(
            'Tomorrow',
            '${((_analyticsData?.totalSolarGeneration ?? 0) * 1.1).toStringAsFixed(1)} kWh',
            'Expected generation',
            Iconsax.sun_1,
            const Color(0xFFFBBF24),
            'Sunny weather predicted',
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildPredictionCard(
            'This Week',
            '${((_analyticsData?.totalSolarGeneration ?? 0) * 6.8).toStringAsFixed(0)} kWh',
            'Weekly forecast',
            Iconsax.calendar,
            const Color(0xFF8B5CF6),
            'Variable conditions',
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(
    String period,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String note,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            period,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF718096)),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              note,
              style: TextStyle(
                fontSize: 10.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, delay: 400.ms, duration: 600.ms);
  }

  Widget _buildWeatherMetric(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPredictionColor(double efficiency) {
    if (efficiency >= 0.8)
      return const Color(0xFF10B981); // Green for high efficiency
    if (efficiency >= 0.6) return const Color(0xFFFBBF24); // Yellow for medium
    return const Color(0xFFEF4444); // Red for low efficiency
  }

  Widget _buildSolarForecastSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.sun_1, color: const Color(0xFFFBBF24), size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                '7-Day Solar Forecast',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Icon(
                Iconsax.refresh,
                color: const Color(0xFF718096),
                size: 16.sp,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (_isLoadingPredictions)
            _buildForecastLoading()
          else if (_solarPredictions.isEmpty)
            _buildForecastError()
          else
            _buildForecastList(),
        ],
      ),
    );
  }

  Widget _buildForecastLoading() {
    return Column(
      children: List.generate(
        3,
        (index) =>
            Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1000.ms,
                  delay: Duration(milliseconds: index * 200),
                ),
      ),
    );
  }

  Widget _buildForecastError() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, color: Colors.orange, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forecast Unavailable',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                if (_predictionError != null)
                  Text(
                    _predictionError!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange[700],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastList() {
    return Column(
      children: _solarPredictions.take(7).map((prediction) {
        final energy = (prediction['energyGeneration'] as double? ?? 0.0);
        final efficiency = (prediction['efficiency'] as double? ?? 0.0);
        final confidence = (prediction['confidence'] as double? ?? 85.0);
        final weather = prediction['weather'] as String? ?? 'Unknown';
        final dateFormatted =
            prediction['dateFormatted'] as String? ?? 'Unknown';

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // Date and weather icon
              Container(
                width: 60.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatted.split(',').first,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                    Text(
                      dateFormatted.split(',').last.trim(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),

              // Weather condition
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getWeatherColor(weather),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  weather,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),

              // Energy generation
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${energy.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: _getPredictionColor(efficiency),
                    ),
                  ),
                  Text(
                    '${confidence.toInt()}% confidence',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF718096),
                    ),
                  ),
                ],
              ),

              // Efficiency indicator
              SizedBox(width: 8.w),
              Container(
                width: 4.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: _getPredictionColor(efficiency),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getWeatherColor(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return const Color(0xFFFBBF24);
      case 'partly cloudy':
        return const Color(0xFF8B5CF6);
      case 'cloudy':
        return const Color(0xFF6B7280);
      case 'overcast':
        return const Color(0xFF374151);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Widget _buildStreetLightsGrid() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Iconsax.lamp_on, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solar Street Lights',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      '${_solarStreetLights.length} lights monitored',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_analyticsData?.activeLights ?? 0} Active',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio:
                  1.1, // Increased to give more height and prevent overflow
            ),
            itemCount: math.min(_solarStreetLights.length, 6),
            itemBuilder: (context, index) {
              final light = _solarStreetLights[index];
              return _buildLightCard(light, index);
            },
          ),
          if (_solarStreetLights.length > 6)
            Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to full lights list
                  },
                  icon: Icon(Iconsax.eye, size: 16.sp),
                  label: Text('View All ${_solarStreetLights.length} Lights'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF667EEA),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().slideY(begin: 0.3, delay: 600.ms, duration: 600.ms);
  }

  Widget _buildLightCard(Map<String, dynamic> light, int index) {
    final isActive = light['status'] == 'on' || light['isActive'] == true;
    final brightness = light['brightness'] ?? 100;
    final powerConsumption = (light['powerConsumption'] ?? 25.0).toDouble();
    final location = light['location'] ?? light['address'] ?? 'Unknown';

    return GestureDetector(
      onTap: () {
        // Navigate to street light detail page with the light data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreetLightDetailScreen(data: light),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12.w), // Reduced padding to prevent overflow
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF10B981).withOpacity(0.05),
                  ],
                )
              : LinearGradient(
                  colors: [const Color(0xFFF7FAFC), const Color(0xFFF7FAFC)],
                ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isActive
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w), // Reduced padding
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFF718096),
                    borderRadius: BorderRadius.circular(8.r), // Reduced radius
                  ),
                  child: Icon(
                    Iconsax.lamp_on,
                    color: Colors.white,
                    size: 14.sp,
                  ), // Reduced size
                ),
                const Spacer(),
                Container(
                  width: 6.w, // Reduced size
                  height: 6.w, // Made it circular with equal width/height
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFF718096),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h), // Reduced spacing
            Flexible(
              // Use Flexible instead of fixed height
              child: Text(
                light['name'] ?? 'Street Light ${index + 1}',
                style: TextStyle(
                  fontSize: 13.sp, // Slightly reduced font size
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 3.h), // Reduced spacing
            Flexible(
              // Use Flexible for location text
              child: Text(
                location,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF718096),
                ), // Reduced font size
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(), // Use Spacer to push bottom content to the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  // Use Expanded instead of Flexible to prevent overflow
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.flash_1,
                        color: const Color(0xFF667EEA),
                        size: 9.sp, // Further reduced size
                      ),
                      SizedBox(width: 1.w), // Further reduced spacing
                      Flexible(
                        child: Text(
                          '${powerConsumption.toStringAsFixed(1)}W',
                          style: TextStyle(
                            fontSize: 9.sp, // Further reduced font size
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF667EEA),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ), // Further reduced padding
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          4.r,
                        ), // Further reduced radius
                      ),
                      child: Center(
                        child: Text(
                          '$brightness%',
                          style: TextStyle(
                            fontSize: 8.sp, // Further reduced font size
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF10B981),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      delay: (700 + index * 100).ms,
      duration: 400.ms,
    );
  }
}

// Custom Painter for Luxury Background
class LuxuryBackgroundPainter extends CustomPainter {
  final double animationValue;

  LuxuryBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Animated gradient orbs
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45.0 + animationValue * 20) * (math.pi / 180);
      final radius = 60 + (i * 10);
      final offset = Offset(
        size.width * 0.8 + radius * math.cos(angle),
        size.height * 0.2 + radius * math.sin(angle),
      );

      paint.shader = RadialGradient(
        colors: [
          const Color(0xFF667EEA).withOpacity(0.03),
          const Color(0xFF667EEA).withOpacity(0.01),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: offset, radius: 40));

      canvas.drawCircle(offset, 40, paint);
    }

    // Floating energy particles
    for (int i = 0; i < 12; i++) {
      final progress = (animationValue + i * 0.08).remainder(1);
      final offset = Offset(
        size.width * 0.1 + (size.width * 0.8 * progress),
        size.height * 0.3 + (30 * math.sin(progress * math.pi * 2 + i)),
      );

      paint.shader = null;
      paint.color = const Color(
        0xFF10B981,
      ).withOpacity(0.02 + (0.03 * math.sin(progress * math.pi)));
      canvas.drawCircle(offset, 3 + (i * 0.5), paint);
    }

    // Solar ray effects
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5 + animationValue * 15) * (math.pi / 180);
      final startRadius = 80;
      final endRadius = 120;

      final start = Offset(
        size.width * 0.9 + startRadius * math.cos(angle),
        size.height * 0.1 + startRadius * math.sin(angle),
      );

      final end = Offset(
        size.width * 0.9 + endRadius * math.cos(angle),
        size.height * 0.1 + endRadius * math.sin(angle),
      );

      paint.shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [const Color(0xFFFBBF24).withOpacity(0.02), Colors.transparent],
      ).createShader(Rect.fromPoints(start, end));

      canvas.drawLine(start, end, paint..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
