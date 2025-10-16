import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SolarPredictionCard extends StatelessWidget {
  final Map<String, dynamic>? prediction;
  final dynamic weatherData;
  final int animationDelay;

  const SolarPredictionCard({
    super.key,
    required this.prediction,
    required this.weatherData,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final predicted = prediction != null
        ? (prediction!['predictedEnergy'] ?? 0.0)
        : 0.0;
    final perLight = prediction != null
        ? (prediction!['perLight'] ?? 0.0)
        : 0.0;

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
          Text(
            'Solar Predictions',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'Predicted solar generation: ${predicted.toStringAsFixed(2)} kWh',
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            'Per light average: ${perLight.toStringAsFixed(2)} kWh',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          if (weatherData != null) ...[
            Text(
              'Weather: ${weatherData['description'] ?? weatherData['condition'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 12.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              'Cloud Cover: ${weatherData['cloudCover'] ?? 'N/A'}%',
              style: TextStyle(fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }
}
