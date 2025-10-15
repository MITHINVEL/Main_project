
class WeatherService {
 static Future<WeatherData?> getCurrentWeather(double lat, double lon) async {
    try {
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay

      return WeatherData(
        temperature: 28.5,
        description: 'Partly Cloudy',
        humidity: 65,
        windSpeed: 12.0,
        icon: '02d',
        cityName: 'Current Location',
        feelsLike: 31.2,
        pressure: 1013,
        visibility: 10,
      );

      // Uncomment below for actual API call:
      /*
      final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }
      return null;
      */
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  // Get weather forecast
  static Future<List<WeatherForecast>?> getWeatherForecast(
    double lat,
    double lon,
  ) async {
    try {
      // For demo purposes, return sample forecast data
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay

      return [
        WeatherForecast(
          dateTime: DateTime.now().add(Duration(days: 1)),
          temperature: 30.0,
          description: 'Sunny',
          icon: '01d',
        ),
        WeatherForecast(
          dateTime: DateTime.now().add(Duration(days: 2)),
          temperature: 27.5,
          description: 'Cloudy',
          icon: '03d',
        ),
        WeatherForecast(
          dateTime: DateTime.now().add(Duration(days: 3)),
          temperature: 25.0,
          description: 'Rainy',
          icon: '10d',
        ),
        WeatherForecast(
          dateTime: DateTime.now().add(Duration(days: 4)),
          temperature: 29.0,
          description: 'Partly Cloudy',
          icon: '02d',
        ),
        WeatherForecast(
          dateTime: DateTime.now().add(Duration(days: 5)),
          temperature: 32.0,
          description: 'Sunny',
          icon: '01d',
        ),
      ];

      // Uncomment below for actual API call:
      /*
      final url = '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        return forecastList.take(5).map((item) => WeatherForecast.fromJson(item)).toList();
      }
      return null;
      */
    } catch (e) {
      print('Error fetching forecast: $e');
      return null;
    }
  }

  // Get UV Index (sunshine data)
  static Future<UVData?> getUVIndex(double lat, double lon) async {
    try {
      // For demo purposes, return sample UV data
      await Future.delayed(
        Duration(milliseconds: 500),
      ); // Simulate network delay

      return UVData(
        uvIndex: 6.5, // Moderate UV index
        dateTime: DateTime.now(),
      );

      // Uncomment below for actual API call:
      /*
      final url = 'https://api.openweathermap.org/data/2.5/uvi?lat=$lat&lon=$lon&appid=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UVData.fromJson(data);
      }
      return null;
      */
    } catch (e) {
      print('Error fetching UV data: $e');
      return null;
    }
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
  });

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
      visibility: (json['visibility'] as int) ~/ 1000, // Convert to km
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
