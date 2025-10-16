class SolarAnalyticsModel {
  final int totalStreetLights;
  final int activeLights;
  final double totalEnergyConsumption;
  final double totalSolarGeneration;
  final double energySavings;
  final double efficiencyPercentage;
  final String weatherCondition;
  final double temperature;
  final Map<String, dynamic>? prediction;

  SolarAnalyticsModel({
    required this.totalStreetLights,
    required this.activeLights,
    required this.totalEnergyConsumption,
    required this.totalSolarGeneration,
    required this.energySavings,
    required this.efficiencyPercentage,
    required this.weatherCondition,
    required this.temperature,
    required this.prediction,
  });
}
