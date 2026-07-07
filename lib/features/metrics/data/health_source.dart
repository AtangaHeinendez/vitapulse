import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/metric_sample.dart';
import '../domain/metric_type.dart';

/// Where health data comes from on this device.
abstract class HealthSource {
  /// True when the underlying provider (Health Connect) can be used.
  Future<bool> isAvailable();

  /// Asks the platform for read access. Returns true when granted.
  Future<bool> requestPermissions();

  /// True if permissions were already granted.
  Future<bool> hasPermissions();

  /// All samples from the last [days] days.
  Future<List<MetricSample>> fetchSamples({int days = 30});

  /// Best-effort steps for today from the phone's own step sensor, used when
  /// Health Connect has no step data. Null when unsupported/denied.
  Future<int?> fallbackTodaySteps();

  /// Writes a manual water intake entry back to the platform, if supported.
  Future<void> writeWater(double ml, DateTime at);
}

/// Health Connect implementation via the `health` package.
class HealthConnectSource implements HealthSource {
  HealthConnectSource(this._prefs);

  final SharedPreferences _prefs;
  final Health _health = Health();

  static const _readTypes = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.WEIGHT,
    HealthDataType.WATER,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  List<HealthDataAccess> get _accessLevels => [
        for (final t in _readTypes)
          t == HealthDataType.WATER
              ? HealthDataAccess.READ_WRITE
              : HealthDataAccess.READ,
      ];

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      await _health.configure();
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    final granted =
        await _health.hasPermissions(_readTypes, permissions: _accessLevels);
    return granted ?? false;
  }

  @override
  Future<bool> requestPermissions() async {
    // Phone step sensor fallback needs ACTIVITY_RECOGNITION (Android 10+).
    await Permission.activityRecognition.request();
    return _health.requestAuthorization(_readTypes,
        permissions: _accessLevels);
  }

  @override
  Future<List<MetricSample>> fetchSamples({int days = 30}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final points = await _health.getHealthDataFromTypes(
      types: _readTypes,
      startTime: start,
      endTime: now,
    );
    final deduped = _health.removeDuplicates(points);

    final samples = <MetricSample>[];
    for (final p in deduped) {
      final value = p.value;
      if (value is! NumericHealthValue) continue;
      final v = value.numericValue.toDouble();
      switch (p.type) {
        case HealthDataType.STEPS:
          samples.add(_s(MetricType.steps, v, p.dateFrom));
        case HealthDataType.HEART_RATE:
          samples.add(_s(MetricType.heartRate, v, p.dateFrom));
        case HealthDataType.SLEEP_SESSION:
          // Attribute the whole session to its end time ("last night").
          samples.add(_s(MetricType.sleepSession, v, p.dateTo));
        case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
          samples.add(_s(MetricType.bpSystolic, v, p.dateFrom));
        case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
          samples.add(_s(MetricType.bpDiastolic, v, p.dateFrom));
        case HealthDataType.BLOOD_OXYGEN:
          samples.add(_s(MetricType.spo2, v, p.dateFrom));
        case HealthDataType.WEIGHT:
          samples.add(_s(MetricType.weight, v, p.dateFrom));
        case HealthDataType.WATER:
          // Health Connect hydration is liters; we store milliliters.
          samples.add(_s(MetricType.waterIntake, v * 1000, p.dateFrom));
        case HealthDataType.TOTAL_CALORIES_BURNED:
          samples.add(_s(MetricType.caloriesBurned, v, p.dateFrom));
        default:
          break;
      }
    }
    return samples;
  }

  MetricSample _s(MetricType t, double v, DateTime at) =>
      MetricSample(type: t, value: v, recordedAt: at);

  static const _kBaselineDay = 'pedometer_baseline_day';
  static const _kBaselineCount = 'pedometer_baseline_count';

  @override
  Future<int?> fallbackTodaySteps() async {
    if (!await Permission.activityRecognition.isGranted) return null;
    try {
      final event = await Pedometer.stepCountStream.first
          .timeout(const Duration(seconds: 5));
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final baselineDay = _prefs.getString(_kBaselineDay);
      final baseline = _prefs.getInt(_kBaselineCount);
      if (baselineDay != today || baseline == null || baseline > event.steps) {
        // First reading today (or reboot reset the cumulative counter):
        // start counting from here.
        await _prefs.setString(_kBaselineDay, today);
        await _prefs.setInt(_kBaselineCount, event.steps);
        return 0;
      }
      return event.steps - baseline;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeWater(double ml, DateTime at) async {
    try {
      await _health.writeHealthData(
        value: ml / 1000, // liters
        type: HealthDataType.WATER,
        startTime: at,
        endTime: at,
      );
    } catch (_) {
      // Health Connect write is best-effort; Supabase remains source of truth.
    }
  }
}

/// Deterministic fake data for emulators/web so UI work can proceed without
/// a watch. Enabled with --dart-define=MOCK_HEALTH=true.
class MockHealthSource implements HealthSource {
  MockHealthSource({int seed = 7}) : _rng = Random(seed);

  final Random _rng;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<int?> fallbackTodaySteps() async => null;

  @override
  Future<void> writeWater(double ml, DateTime at) async {}

  @override
  Future<List<MetricSample>> fetchSamples({int days = 30}) async {
    final samples = <MetricSample>[];
    final now = DateTime.now();
    for (var d = 0; d < days; d++) {
      final day = DateTime(now.year, now.month, now.day - d);
      final isToday = d == 0;
      final hoursAvailable = isToday ? now.hour : 24;

      // Steps: hourly buckets through the day.
      for (var h = 7; h < min(22, hoursAvailable); h++) {
        samples.add(MetricSample(
          type: MetricType.steps,
          value: (200 + _rng.nextInt(900)).toDouble(),
          recordedAt: day.add(Duration(hours: h, minutes: 10)),
          source: 'mock',
        ));
      }
      // Heart rate: every 2 hours.
      for (var h = 0; h < hoursAvailable; h += 2) {
        samples.add(MetricSample(
          type: MetricType.heartRate,
          value: (58 + _rng.nextInt(50)).toDouble(),
          recordedAt: day.add(Duration(hours: h, minutes: 30)),
          source: 'mock',
        ));
      }
      // Sleep: one session ending ~06:45.
      samples.add(MetricSample(
        type: MetricType.sleepSession,
        value: (360 + _rng.nextInt(150)).toDouble(),
        recordedAt: day.add(const Duration(hours: 6, minutes: 45)),
        source: 'mock',
      ));
      // Blood pressure: morning reading.
      final sys = 108 + _rng.nextInt(24);
      samples.add(MetricSample(
        type: MetricType.bpSystolic,
        value: sys.toDouble(),
        recordedAt: day.add(const Duration(hours: 8)),
        source: 'mock',
      ));
      samples.add(MetricSample(
        type: MetricType.bpDiastolic,
        value: (sys - 38 - _rng.nextInt(8)).toDouble(),
        recordedAt: day.add(const Duration(hours: 8)),
        source: 'mock',
      ));
      // SpO2: nightly.
      samples.add(MetricSample(
        type: MetricType.spo2,
        value: (95 + _rng.nextInt(4)).toDouble(),
        recordedAt: day.add(const Duration(hours: 5)),
        source: 'mock',
      ));
      // Water: a few logs.
      for (var i = 0; i < 3 + _rng.nextInt(3); i++) {
        samples.add(MetricSample(
          type: MetricType.waterIntake,
          value: 250,
          recordedAt: day.add(Duration(hours: 9 + i * 3)),
          source: 'mock',
        ));
      }
      // Calories: one daily total.
      samples.add(MetricSample(
        type: MetricType.caloriesBurned,
        value: (1900 + _rng.nextInt(700)).toDouble(),
        recordedAt: day.add(const Duration(hours: 21)),
        source: 'mock',
      ));
      // Weight: every 3rd day, slow trend.
      if (d % 3 == 0) {
        samples.add(MetricSample(
          type: MetricType.weight,
          value: 74.5 + d * 0.05 + _rng.nextDouble() * .4,
          recordedAt: day.add(const Duration(hours: 7)),
          source: 'mock',
        ));
      }
    }
    return samples;
  }
}
