import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';
import 'format.dart';

/// Shift reminders, offered once after the nurse's first check-in and toggled in Profile.
/// Reminders are local to the device: nothing is sent to the server.
abstract interface class ReminderService {
  /// Local scheduled notifications work on Android and iOS only.
  bool get supported;

  Future<bool> isEnabled();

  /// Asks the OS for permission. Returns false if the nurse declines.
  Future<bool> enable();
  Future<void> disable();

  /// Replaces all scheduled reminders with one per upcoming work shift, [lead] before it.
  Future<void> schedule(
    List<Shift> upcoming, {
    required DateTime now,
    Duration lead = reminderLead,
  });

  /// Whether the one-time "turn on reminders?" prompt has been shown on this device.
  Future<bool> wasOffered();
  Future<void> markOffered();

  /// On a long duty, notifies the nurse when the main shift ends and OT begins.
  /// Asks for notification permission if needed; independent of the reminders toggle.
  Future<void> scheduleOtTransition(Shift shift);
  Future<void> cancelOtTransition();
}

/// Shown when a long duty's main hours are done.
const otTransitionTitle = 'Main Shift Completed!';
const otTransitionBody =
    'Switched to Overtime (OT) Mode. Keep up the great work! 🩺';

/// When the OT-transition alert fires for [shift], or null if it doesn't apply.
DateTime? otTransitionAt(Shift shift, DateTime now) {
  if (!shift.hasAutoOt || !shift.onDuty) return null;
  final at = shift.mainEnd;
  return at != null && at.isAfter(now) ? at : null;
}

/// How long before a shift starts the reminder fires, unless changed in App Settings.
const reminderLead = Duration(minutes: 60);

/// "30 min", "1 hour", "2 hours"
String leadLabel(Duration lead) => lead.inMinutes < 60
    ? '${lead.inMinutes} min'
    : lead.inMinutes == 60
    ? '1 hour'
    : '${lead.inMinutes ~/ 60} hours';

/// Which shifts get a reminder, and when. Pure, so it is unit-tested.
List<({Shift shift, DateTime at})> plannedReminders(
  List<Shift> shifts,
  DateTime now, [
  Duration lead = reminderLead,
]) =>
    [
        for (final s in shifts)
          if (s.type != ShiftType.off &&
              !s.isLeave &&
              s.status == ShiftStatus.scheduled)
            (shift: s, at: s.type.window(s.date).start.subtract(lead)),
      ].where((r) => r.at.isAfter(now)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));

class LocalReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  static const _enabledKey = 'reminders.enabled';
  static const _offeredKey = 'reminders.offered';
  static const _otTransitionId = 900001;
  static const _dutyChannel = AndroidNotificationDetails(
    'duty_status',
    'Duty status',
    channelDescription: 'Tells you when a long duty switches to overtime',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _channel = AndroidNotificationDetails(
    'shift_reminders',
    'Shift reminders',
    channelDescription: 'A reminder an hour before each rostered shift',
    importance: Importance.high,
    priority: Priority.high,
  );

  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _init() async {
    if (_initialised) return;
    tz_data.initializeTimeZones();
    // Sri Lanka has a single time zone and no DST; shift times are Colombo wall-clock times.
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested explicitly from the prompt, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialised = true;
  }

  @override
  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  @override
  Future<bool> enable() async {
    if (!supported) return false;
    await _init();
    bool granted;
    if (defaultTargetPlatform == TargetPlatform.android) {
      granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    } else {
      granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true, badge: true) ??
          false;
    }
    await (await SharedPreferences.getInstance()).setBool(_enabledKey, granted);
    return granted;
  }

  @override
  Future<void> disable() async {
    await (await SharedPreferences.getInstance()).setBool(_enabledKey, false);
    if (!supported) return;
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> schedule(
    List<Shift> upcoming, {
    required DateTime now,
    Duration lead = reminderLead,
  }) async {
    if (!supported || !await isEnabled()) return;
    await _init();
    // Replace shift reminders only; an OT-transition alert for a duty in progress stays.
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.id != _otTransitionId) await _plugin.cancel(id: p.id);
    }
    // iOS keeps at most 64 pending notifications; two weeks of shifts is well below that.
    for (final r in plannedReminders(upcoming, now, lead).take(40)) {
      final start = r.shift.type.window(r.shift.date).start;
      await _plugin.zonedSchedule(
        id: r.shift.id.hashCode & 0x7fffffff,
        title: '${r.shift.type.label} in ${leadLabel(lead)}',
        body:
            'Starts at ${Fmt.time(start)}${r.shift.otHours > 0 ? ' · +${Fmt.hours(r.shift.otHours)}h OT planned' : ''}',
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact (Doze-friendly) avoids the exact-alarm permission; a few minutes' drift is fine.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<bool> wasOffered() async =>
      (await SharedPreferences.getInstance()).getBool(_offeredKey) ?? false;

  @override
  Future<void> markOffered() async =>
      (await SharedPreferences.getInstance()).setBool(_offeredKey, true);

  @override
  Future<void> scheduleOtTransition(Shift shift) async {
    final at = otTransitionAt(shift, DateTime.now());
    if (!supported || at == null) return;
    await _init();
    final granted = defaultTargetPlatform == TargetPlatform.android
        ? await _plugin
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >()
                  ?.requestNotificationsPermission() ??
              false
        : await _plugin
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.requestPermissions(alert: true, sound: true) ??
              false;
    if (!granted) return;
    await _plugin.zonedSchedule(
      id: _otTransitionId,
      title: otTransitionTitle,
      body: otTransitionBody,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: _dutyChannel,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelOtTransition() async {
    if (!supported) return;
    await _init();
    await _plugin.cancel(id: _otTransitionId);
  }
}

/// Tests, demo mode and unsupported platforms.
class MemoryReminderService implements ReminderService {
  MemoryReminderService({this.supported = true, this.grant = true});

  @override
  final bool supported;

  /// What the fake OS permission dialog answers.
  final bool grant;
  bool enabled = false;
  bool offered = false;
  List<({Shift shift, DateTime at})> scheduled = const [];

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> enable() async => enabled = supported && grant;

  @override
  Future<void> disable() async {
    enabled = false;
    scheduled = const [];
  }

  @override
  Future<void> schedule(
    List<Shift> upcoming, {
    required DateTime now,
    Duration lead = reminderLead,
  }) async {
    if (enabled) scheduled = plannedReminders(upcoming, now, lead);
  }

  @override
  Future<bool> wasOffered() async => offered;

  @override
  Future<void> markOffered() async => offered = true;

  /// When the pending OT-transition alert fires, if one is scheduled.
  DateTime? otTransition;

  @override
  Future<void> scheduleOtTransition(Shift shift) async {
    if (supported) otTransition = otTransitionAt(shift, DateTime.now());
  }

  @override
  Future<void> cancelOtTransition() async => otTransition = null;
}
