import 'dart:convert';
import 'package:http/http.dart' as http;

/// SolarEnergyService
///
/// Attempts to use the NREL PVWatts API when an API key is provided. If no
/// API key is supplied the service falls back to a simple heuristic-based
/// calculation (panel wattage * sunlight hours * cloud cover).
class SolarEnergyService {
  final String? apiKey;
  final http.Client _client;

  SolarEnergyService({this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  /// Calculates energy prediction for the given street lights and weather.
  ///
  /// streetLights: list of maps containing at least panelWattage and optional lat/lon
  /// weatherData: map that may contain cloudCover (0-100)
  /// timeRange: one of 'Today', 'This Week', 'This Month'
  Future<Map<String, dynamic>?> calculateEnergyPrediction({
    required List<Map<String, dynamic>> streetLights,
    required dynamic weatherData,
    required String timeRange,
  }) async {
    // If we have an API key, try PVWatts with the aggregate capacity.
    if (apiKey != null && apiKey!.isNotEmpty && streetLights.isNotEmpty) {
      try {
        // Aggregate system capacity in kW
        final totalWatts = streetLights.fold<double>(
          0.0,
          (acc, s) => acc + (s['panelWattage'] ?? 50.0).toDouble(),
        );
        final systemCapacity = (totalWatts / 1000.0).clamp(0.001, 10000.0);

        // Use coordinates from the first light if available
        final first = streetLights.first;
        final lat = (first['latitude'] ?? first['lat'] ?? 0.0).toDouble();
        final lon = (first['longitude'] ?? first['lng'] ?? 0.0).toDouble();

        final pv = await _callPvWatts(
          lat: lat,
          lon: lon,
          systemCapacity: systemCapacity,
        );
        if (pv != null) {
          // pv may contain `ac_annual` or `outputs.ac_annual` depending on response
          double annualKwh = 0.0;
          if (pv['outputs'] != null && pv['outputs']['ac_annual'] != null) {
            annualKwh = (pv['outputs']['ac_annual'] as num).toDouble();
          } else if (pv['ac_annual'] != null) {
            annualKwh = (pv['ac_annual'] as num).toDouble();
          }

          // Convert annual to requested time range
          double predicted = 0.0;
          if (timeRange.toLowerCase() == 'today') {
            predicted = annualKwh / 365.0;
          } else if (timeRange.toLowerCase().contains('week')) {
            predicted = (annualKwh / 365.0) * 7.0;
          } else {
            // month
            predicted = annualKwh / 12.0;
          }

          final perLight = streetLights.isNotEmpty
              ? predicted / streetLights.length
              : 0.0;

          return {
            'timeRange': timeRange,
            'predictedEnergy': predicted,
            'perLight': perLight,
            'source': 'pvwatts',
            'pv_response': pv,
          };
        }
      } catch (e) {
        // Log and fall back to heuristic
        // ignore: avoid_print
        print('PVWatts error: $e');
      }
    }

    // Fallback heuristic calculation (per-light)
    final double cloudCover = (weatherData?['cloudCover'] ?? 0).toDouble();
    final double sunlightHours = _estimateSunlightHours();
    double total = 0.0;
    for (var light in streetLights) {
      final panelWattage = (light['panelWattage'] ?? 50.0).toDouble();
      total += calculateSolarOutput(
        panelWattage: panelWattage,
        sunlightHours: sunlightHours,
        cloudCover: cloudCover,
      );
    }

    return {
      'timeRange': timeRange,
      'predictedEnergy': total,
      'perLight': streetLights.isNotEmpty ? total / streetLights.length : 0.0,
      'source': 'heuristic',
    };
  }

  /// Calls NREL PVWatts API and returns decoded JSON or null on failure.
  Future<Map<String, dynamic>?> _callPvWatts({
    required double lat,
    required double lon,
    required double systemCapacity,
  }) async {
    final uri = Uri.https('developer.nrel.gov', '/api/pvwatts/v6.json', {
      'api_key': apiKey ?? '',
      'lat': lat.toString(),
      'lon': lon.toString(),
      'system_capacity': systemCapacity.toString(),
      'azimuth': '180',
      'tilt': '20',
      'array_type': '1',
      'module_type': '0',
      'losses': '14.0',
      'dataset': 'intl',
    });

    final resp = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      try {
        final decoded = json.decode(resp.body) as Map<String, dynamic>;
        return decoded;
      } catch (e) {
        // ignore: avoid_print
        print('PVWatts decode error: $e');
      }
    } else {
      // ignore: avoid_print
      print('PVWatts HTTP ${resp.statusCode}: ${resp.body}');
    }
    return null;
  }

  double calculateSolarOutput({
    required double panelWattage,
    required double sunlightHours,
    required double cloudCover,
  }) {
    final double efficiency = (1.0 - (cloudCover.clamp(0, 100) / 100.0))
        .toDouble();
    final double energyWh = panelWattage * sunlightHours * efficiency;
    return energyWh / 1000.0;
  }

  double _estimateSunlightHours() {
    final now = DateTime.now();
    if (now.hour >= 6 && now.hour <= 18) return 8.0;
    return 0.0;
  }
}
