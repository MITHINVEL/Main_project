import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _currentWeather;
  UVData? _uvData;

  bool _isLoading = true;
  String? _error;
  String _locationName = 'Getting location...'; // Store real location name

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _locationName = 'Getting location...';
    });

    try {
      double lat = 11.3410; // Default Erode coordinates  
      double lon = 77.7172;
      String locationName = 'Erode, Tamil Nadu'; // Default location

      // Try to get current location
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
        
        // Get real address from coordinates using API
        try {
          locationName = await LocationService.getAddressFromCoordinates(lat, lon);
          print('Got real location: $locationName');
        } catch (e) {
          print('Error getting address: $e');
          locationName = 'Current Location';
        }
      } else {
        print('Using default location: $locationName');
      }

      // Fetch weather data (will use demo data)
      final weather = await WeatherService.getCurrentWeather(lat, lon);
      final uv = await WeatherService.getUVIndex(lat, lon);


      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _uvData = uv;

          _locationName = locationName; // Set the real location name
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load weather data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return Column(
      children: [
        // Current Weather Card
        _buildCurrentWeatherCard(),
        SizedBox(height: 16.h),

        // UV Index Card
        if (_uvData != null) SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
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
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading weather data...',
            style: TextStyle(fontSize: 16.sp, color: Color(0xFF718096)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
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
        children: [
          Icon(Icons.cloud_off, size: 48.sp, color: Color(0xFFE53E3E)),
          SizedBox(height: 16.h),
          Text(
            _error!,
            style: TextStyle(fontSize: 16.sp, color: Color(0xFF718096)),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadWeatherData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF667EEA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildCurrentWeatherCard() {
    if (_currentWeather == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/cloud-of-bunch-of-7372799_1280.jpg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE, d MMM').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 240.w),
                        child: Text(
                          _locationName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                      size: 26.sp,
                    ),
                  ),
                ],
              ),
      
              SizedBox(height: 20.h),
      
              Row(
                children: [
                  // Temperature
                  Text(
                    '${_currentWeather!.temperature.round()}°C',
                    style: TextStyle(
                      fontSize: 48.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 16.w),
      
                  // Weather description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentWeather!.description.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Feels like ${_currentWeather!.feelsLike.round()}°C',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color.fromARGB(255, 254, 253, 253)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      
              SizedBox(height: 20.h),
      
              // Weather details
              Row(
                children: [
                  _buildWeatherDetail(
                    Icons.water_drop,
                    'Humidity',
                    '${_currentWeather!.humidity}%',
                  ),
                  _buildWeatherDetail(
                    Icons.air,
                    'Wind',
                    '${_currentWeather!.windSpeed.toStringAsFixed(1)} m/s',
                  ),
                  _buildWeatherDetail(
                    Icons.compress,
                    'Pressure',
                    '${_currentWeather!.pressure} hPa',
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.3, duration: 800.ms),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon, 
              color: Colors.white.withOpacity(0.95),
              size: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

}
