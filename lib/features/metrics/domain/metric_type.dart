import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Every metric VitaPulse tracks. `dbName` matches the `metric_type` check
/// constraint in the `health_metrics` table.
enum MetricType {
  steps('steps', 'count', 'Steps', Icons.directions_walk_rounded, AppColors.steps),
  heartRate('heart_rate', 'bpm', 'Heart rate', Icons.monitor_heart_rounded, AppColors.heartRate),
  sleepSession('sleep_session', 'min', 'Sleep', Icons.bedtime_rounded, AppColors.sleep),
  bpSystolic('bp_systolic', 'mmHg', 'Systolic', Icons.bloodtype_rounded, AppColors.bloodPressure),
  bpDiastolic('bp_diastolic', 'mmHg', 'Diastolic', Icons.bloodtype_outlined, AppColors.bloodPressure),
  spo2('spo2', '%', 'SpO₂', Icons.bubble_chart_rounded, AppColors.spo2),
  weight('weight', 'kg', 'Weight', Icons.monitor_weight_rounded, AppColors.weight),
  waterIntake('water_intake', 'ml', 'Water', Icons.water_drop_rounded, AppColors.water),
  caloriesBurned('calories_burned', 'kcal', 'Calories', Icons.local_fire_department_rounded, AppColors.calories);

  const MetricType(this.dbName, this.unit, this.label, this.icon, this.accent);

  final String dbName;
  final String unit;
  final String label;
  final IconData icon;
  final Color accent;

  static MetricType fromDbName(String name) =>
      values.firstWhere((t) => t.dbName == name);
}
