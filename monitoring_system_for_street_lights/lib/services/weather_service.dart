import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

class WeatherService {
  static Future<WeatherData?> getCurrentWeather(double lat, double lon) async {
    try {
      final url =
          '$_baseUrl?latitude=$lat&longitude=$lon'
          '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
          'weather_code,wind_speed_10m,surface_pressure,cloud_cover'
          '&timezone=auto';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromOpenMeteo(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return null;
    }
  }

  // Get weather forecast
  static Future<List<WeatherForecast>?> getWeatherForecast(
    double lat,
    double lon,
  ) async {
    try {
      final url =
          '$_baseUrl?latitude=$lat&longitude=$lon'
          '&hourly=temperature_2m,weather_code'
          '&timezone=auto&forecast_hours=15';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hourly = data['hourly'];
        final times = hourly['time'] as List;
        final temps = hourly['temperature_2m'] as List;
        final codes = hourly['weather_code'] as List;

        List<WeatherForecast> forecasts = [];
        for (int i = 0; i < min(5, times.length); i++) {
          final code = (codes[i] as num).toInt();
          forecasts.add(WeatherForecast(
            dateTime: DateTime.parse(times[i]),
            temperature: (temps[i] as num).toDouble(),
            description: _wmoDescription(code),
            icon: _wmoToIcon(code),
          ));
        }
        return forecasts;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
      return null;
    }
  }

  // Get UV Index (estimated from cloud cover & solar position)
  static Future<UVData?> getUVIndex(double lat, double lon) async {
    try {
      final weather = await getCurrentWeather(lat, lon);
      if (weather != null) {
        final hour = DateTime.now().hour;
        double estimatedUV = 0.0;
        if (hour >= 6 && hour <= 18) {
          double solarFactor = sin((hour - 6) * pi / 12);
          double cloudFactor = 1.0 - (weather.cloudCover / 100.0) * 0.75;
          estimatedUV = 10.0 * solarFactor * cloudFactor;
        }
        return UVData(
          uvIndex: estimatedUV.clamp(0.0, 12.0),
          dateTime: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching UV data: $e');
      return null;
    }
  }

  /// Map WMO weather code to description
  static String _wmoDescription(int code) {
    switch (code) {
      case 0: return 'Clear sky';
      case 1: return 'Mainly clear';
      case 2: return 'Partly cloudy';
      case 3: return 'Overcast';
      case 45: case 48: return 'Foggy';
      case 51: case 53: case 55: return 'Drizzle';
      case 61: case 63: case 65: return 'Rain';
      case 66: case 67: return 'Freezing rain';
      case 71: case 73: case 75: return 'Snowfall';
      case 77: return 'Snow grains';
      case 80: case 81: case 82: return 'Rain showers';
      case 85: case 86: return 'Snow showers';
      case 95: return 'Thunderstorm';
      case 96: case 99: return 'Thunderstorm with hail';
      default: return 'Clear sky';
    }
  }

  /// Map WMO weather code to icon code (compatible with existing icon logic)
  static String _wmoToIcon(int code) {
    final isDay = DateTime.now().hour >= 6 && DateTime.now().hour < 18;
    final suffix = isDay ? 'd' : 'n';
    if (code == 0 || code == 1) return '01$suffix';
    if (code == 2) return '02$suffix';
    if (code == 3) return '04$suffix';
    if (code == 45 || code == 48) return '50$suffix';
    if (code >= 51 && code <= 55) return '09$suffix';
    if (code >= 61 && code <= 67) return '10$suffix';
    if (code >= 71 && code <= 77) return '13$suffix';
    if (code >= 80 && code <= 82) return '09$suffix';
    if (code >= 95) return '11$suffix';
    return '01$suffix';
  }
}

// Weather Data Model
class WeatherData {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final String cityName;
  final double feelsLike;
  final int pressure;
  final int visibility;
  final int cloudCover;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.cityName,
    required this.feelsLike,
    required this.pressure,
    required this.visibility,
    required this.cloudCover,
  });

  /// Parse from Open-Meteo API response
  factory WeatherData.fromOpenMeteo(Map<String, dynamic> json) {
    final current = json['current'];
    final code = (current['weather_code'] as num).toInt();
    final isDay = DateTime.now().hour >= 6 && DateTime.now().hour < 18;
    final suffix = isDay ? 'd' : 'n';

    String icon;
    if (code == 0 || code == 1) {
      icon = '01$suffix';
    } else if (code == 2) {
      icon = '02$suffix';
    } else if (code == 3) {
      icon = '04$suffix';
    } else if (code >= 51 && code <= 55) {
      icon = '09$suffix';
    } else if (code >= 61 && code <= 67) {
      icon = '10$suffix';
    } else if (code >= 95) {
      icon = '11$suffix';
    } else {
      icon = '01$suffix';
    }

    // Wind speed from km/h to m/s
    final windKmh = (current['wind_speed_10m'] as num).toDouble();
    final windMs = windKmh / 3.6;

    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: windMs,
      description: WeatherService._wmoDescription(code),
      icon: icon,
      cityName: '',
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      pressure: (current['surface_pressure'] as num).toInt(),
      visibility: 10,
      cloudCover: (current['cloud_cover'] as num).toInt(),
    );
  }

  /// Legacy OpenWeatherMap parser (kept for compatibility)
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      cityName: json['name'] as String,
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      pressure: json['main']['pressure'] as int,
      visibility: (json['visibility'] as int) ~/ 1000,
      cloudCover: json['clouds']?['all'] ?? 20,
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
}

// Weather Forecast Model
class WeatherForecast {
  final DateTime dateTime;
  final double temperature;
  final String description;
  final String icon;

  WeatherForecast({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.icon,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
}

// UV Data Model
class UVData {
  final double uvIndex;
  final DateTime dateTime;

  UVData({required this.uvIndex, required this.dateTime});

  factory UVData.fromJson(Map<String, dynamic> json) {
    return UVData(
      uvIndex: (json['value'] as num).toDouble(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['date'] * 1000),
    );
  }

  String get uvLevel {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  String get uvDescription {
    if (uvIndex <= 2) return 'Minimal sun protection needed';
    if (uvIndex <= 5) return 'Some protection required';
    if (uvIndex <= 7) return 'Protection essential';
    if (uvIndex <= 10) return 'Extra protection needed';
    return 'Stay in shade during midday';
  }
}
