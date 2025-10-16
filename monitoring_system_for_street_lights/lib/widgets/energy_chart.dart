import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EnergyChart extends StatelessWidget {
  final double consumptionData;
  final double generationData;
  final String timeRange;

  const EnergyChart({
    super.key,
    required this.consumptionData,
    required this.generationData,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    // Minimal placeholder chart: two bars
    final maxVal =
        (consumptionData > generationData ? consumptionData : generationData) +
        1;
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                'Consumption',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 8.h),
              Container(
                height: 120.h,
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (consumptionData / maxVal) * 120.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text('$consumptionData kWh', style: TextStyle(fontSize: 12.sp)),
            ],
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(
            children: [
              Text(
                'Generation',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 8.h),
              Container(
                height: 120.h,
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (generationData / maxVal) * 120.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text('$generationData kWh', style: TextStyle(fontSize: 12.sp)),
            ],
          ),
        ),
      ],
    );
  }
}
