import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/prefs_service.dart';

part 'reminders_service.g.dart';

class ReminderSettings {
  const ReminderSettings({
    this.waterEnabled = false,
    this.waterIntervalHours = 3,
    this.waterStartHour = 9,
    this.waterEndHour = 21,
    this.bpEnabled = false,
    this.bpHour = 8,
    this.bpMinute = 0,
  });

  final bool waterEnabled;
  final int waterIntervalHours;
  final int waterStartHour;
  final int waterEndHour;
  final bool bpEnabled;
  final int bpHour;
  final int bpMinute;

  ReminderSettings copyWith({
    bool? waterEnabled,
    int? waterIntervalHours,
    int? waterStartHour,
    int? waterEndHour,
    bool? bpEnabled,
    int? bpHour,
    int? bpMinute,
  }) =>
      ReminderSettings(
        waterEnabled: waterEnabled ?? this.waterEnabled,
        waterIntervalHours: waterIntervalHours ?? this.waterIntervalHours,
        waterStartHour: waterStartHour ?? this.waterStartHour,
        waterEndHour: waterEndHour ?? this.waterEndHour,
        bpEnabled: bpEnabled ?? this.bpEnabled,
        bpHour: bpHour ?? this.bpHour,
        bpMinute: bpMinute ?? this.bpMinute,
      );

  static ReminderSettings load(SharedPreferences prefs) => ReminderSettings(
        waterEnabled: prefs.getBool('rem_water_on') ?? false,
        waterIntervalHours: prefs.getInt('rem_water_interval') ?? 3,
        waterStartHour: prefs.getInt('rem_water_start') ?? 9,
        waterEndHour: prefs.getInt('rem_water_end') ?? 21,
        bpEnabled: prefs.getBool('rem_bp_on') ?? false,
        bpHour: prefs.getInt('rem_bp_hour') ?? 8,
        bpMinute: prefs.getInt('rem_bp_minute') ?? 0,
      );

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setBool('rem_water_on', waterEnabled);
    await prefs.setInt('rem_water_interval', waterIntervalHours);
    await prefs.setInt('rem_water_start', waterStartHour);
    await prefs.setInt('rem_water_end', waterEndHour);
    await prefs.setBool('rem_bp_on', bpEnabled);
    await prefs.setInt('rem_bp_hour', bpHour);
    await prefs.setInt('rem_bp_minute', bpMinute);
  }
}

class NotificationsService {
  NotificationsService();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _waterIdBase = 100; // + hour of day
  static const _bpId = 200;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Hydration and blood pressure reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> _ensureInit() async {
    if (_initialized || kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Keep the package default if the device zone can't be resolved.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  /// Android 13+ runtime notification permission.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await _ensureInit();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  tz.TZDateTime _nextDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  /// Re-creates every scheduled reminder from [settings].
  Future<void> apply(ReminderSettings settings) async {
    if (kIsWeb) return;
    await _ensureInit();
    await _plugin.cancelAll();

    const details = NotificationDetails(android: _channel);

    if (settings.waterEnabled) {
      for (var h = settings.waterStartHour;
          h <= settings.waterEndHour;
          h += settings.waterIntervalHours) {
        await _plugin.zonedSchedule(
          id: _waterIdBase + h,
          title: 'Time to hydrate 💧',
          body: 'A glass of water keeps your streak going.',
          scheduledDate: _nextDaily(h, 0),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }

    if (settings.bpEnabled) {
      await _plugin.zonedSchedule(
        id: _bpId,
        title: 'Blood pressure check 🩺',
        body: 'Take a reading and log it in VitaPulse.',
        scheduledDate: _nextDaily(settings.bpHour, settings.bpMinute),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}

@Riverpod(keepAlive: true)
NotificationsService notificationsService(Ref ref) => NotificationsService();

@Riverpod(keepAlive: true)
class Reminders extends _$Reminders {
  @override
  ReminderSettings build() =>
      ReminderSettings.load(ref.watch(sharedPrefsProvider));

  Future<void> update(ReminderSettings settings) async {
    state = settings;
    await settings.save(ref.read(sharedPrefsProvider));
    final service = ref.read(notificationsServiceProvider);
    if (settings.waterEnabled || settings.bpEnabled) {
      await service.requestPermission();
    }
    await service.apply(settings);
  }
}
