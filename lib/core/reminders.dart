import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';
import 'notices.dart';

/// Phone notifications: duty reminders planned from the roster, the OT switch on long
/// duties, and one-off notices (day summary, pay details). Everything is scheduled on the
/// device, so it works offline and nothing is sent to the server.
abstract interface class ReminderService {
  /// Local scheduled notifications work on Android and iOS only.
  bool get supported;

  /// The nurse has turned notifications on (and the OS allowed them).
  Future<bool> isEnabled();

  /// Asks the OS for permission. Returns false if the nurse declines.
  Future<bool> enable();
  Future<void> disable();

  /// Replaces every roster-planned notification with [notices].
  Future<void> schedule(List<Notice> notices);

  /// Shows [notice] at its time (immediately if that has passed).
  Future<void> show(Notice notice);

  /// Whether the one-time "turn on reminders?" prompt has been shown on this device.
  Future<bool> wasOffered();
  Future<void> markOffered();

  /// On a long duty, notifies the nurse when the main shift ends and OT begins.
  /// Asks for notification permission if needed; independent of the reminders toggle.
  Future<void> scheduleOtTransition(
    Shift shift, {
    required String title,
    required String body,
  });
  Future<void> cancelOtTransition();

  /// Called with a [NoticeRoute] when the nurse taps a notification.
  set onOpen(ValueChanged<String>? handler);

  /// The route of the notification that launched the app, if any (read once).
  Future<String?> takeLaunchRoute();
}

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

class LocalReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;
  ValueChanged<String>? _onOpen;

  static const _enabledKey = 'reminders.enabled';
  static const _offeredKey = 'reminders.offered';
  static const _otTransitionId = 900001;

  /// Brand charcoal behind the white status-bar icon.
  static const _brand = Color(0xFF2B2D42);

  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  set onOpen(ValueChanged<String>? handler) => _onOpen = handler;

  Future<void> _init() async {
    if (_initialised) return;
    tz_data.initializeTimeZones();
    // Sri Lanka has a single time zone and no DST; shift times are Colombo wall-clock times.
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        // White silhouette of the app character (Android requires a one-colour icon).
        android: AndroidInitializationSettings('ic_stat_nurse'),
        // Permission is requested explicitly from the prompt, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _onOpen?.call(_route(r.payload)),
    );
    _initialised = true;
  }

  /// Payload is "route|kind".
  static String _route(String? payload) =>
      (payload ?? NoticeRoute.home).split('|').first;

  static String _payload(Notice n) => '${n.route}|${n.kind.name}';

  static NotificationDetails _details(Notice n) {
    final (channel, name, description) = switch (n.kind) {
      NoticeKind.otSwitch => (
        'duty_status',
        'Duty status',
        'Tells you when a long duty switches to overtime',
      ),
      NoticeKind.daySummary ||
      NoticeKind.payDetails ||
      NoticeKind.announcement => (
        'summaries',
        'Summaries & tips',
        'Your daily earnings summary and helpful reminders',
      ),
      _ => (
        'shift_reminders',
        'Duty reminders',
        'Before your duty starts and ends, and if you forget to start it',
      ),
    };
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        name,
        channelDescription: description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_nurse',
        // The full-colour app icon inside the notification.
        largeIcon: const DrawableResourceAndroidBitmap('notification_large'),
        color: _brand,
        styleInformation: BigTextStyleInformation(n.body),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  @override
  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true, badge: true) ??
        false;
  }

  @override
  Future<bool> enable() async {
    if (!supported) return false;
    await _init();
    final granted = await _requestPermission();
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
  Future<void> schedule(List<Notice> notices) async {
    if (!supported || !await isEnabled()) return;
    await _init();
    // Replace roster reminders only; the OT switch and one-off notices stay.
    for (final p in await _plugin.pendingNotificationRequests()) {
      final kind = NoticeKind.parse((p.payload ?? '').split('|').last);
      if (kind.fromRoster) await _plugin.cancel(id: p.id);
    }
    // iOS keeps at most 64 pending notifications; two weeks of duties stays below that.
    for (final n in notices.take(50)) {
      await _zoned(n);
    }
  }

  Future<void> _zoned(Notice n) => _plugin.zonedSchedule(
    id: n.id,
    title: n.title,
    body: n.body,
    payload: _payload(n),
    scheduledDate: tz.TZDateTime.from(n.at, tz.local),
    notificationDetails: _details(n),
    // Inexact (Doze-friendly) avoids the exact-alarm permission; a few minutes' drift is fine.
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );

  @override
  Future<void> show(Notice notice) async {
    if (!supported || !await isEnabled()) return;
    await _init();
    if (notice.at.isAfter(DateTime.now())) {
      await _zoned(notice);
    } else {
      await _plugin.show(
        id: notice.id,
        title: notice.title,
        body: notice.body,
        notificationDetails: _details(notice),
        payload: _payload(notice),
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
  Future<void> scheduleOtTransition(
    Shift shift, {
    required String title,
    required String body,
  }) async {
    final at = otTransitionAt(shift, DateTime.now());
    if (!supported || at == null) return;
    await _init();
    if (!await _requestPermission()) return;
    await _zoned(
      Notice(
        id: _otTransitionId,
        kind: NoticeKind.otSwitch,
        title: title,
        body: body,
        at: at,
      ),
    );
  }

  @override
  Future<void> cancelOtTransition() async {
    if (!supported) return;
    await _init();
    await _plugin.cancel(id: _otTransitionId);
  }

  @override
  Future<String?> takeLaunchRoute() async {
    if (!supported) return null;
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return _route(details!.notificationResponse?.payload);
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

  /// Roster-planned notifications currently scheduled.
  List<Notice> scheduled = const [];

  /// One-off notifications shown or scheduled (day summary, pay details).
  final shown = <Notice>[];
  ValueChanged<String>? _onOpen;
  String? launchRoute;

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
  Future<void> schedule(List<Notice> notices) async {
    if (enabled) scheduled = notices;
  }

  @override
  Future<void> show(Notice notice) async {
    if (enabled) shown.add(notice);
  }

  @override
  Future<bool> wasOffered() async => offered;

  @override
  Future<void> markOffered() async => offered = true;

  /// When the pending OT-transition alert fires, if one is scheduled.
  DateTime? otTransition;

  @override
  Future<void> scheduleOtTransition(
    Shift shift, {
    required String title,
    required String body,
  }) async {
    if (supported) otTransition = otTransitionAt(shift, DateTime.now());
  }

  @override
  Future<void> cancelOtTransition() async => otTransition = null;

  @override
  set onOpen(ValueChanged<String>? handler) => _onOpen = handler;

  /// Simulates tapping a notification.
  void tap(String route) => _onOpen?.call(route);

  @override
  Future<String?> takeLaunchRoute() async {
    final r = launchRoute;
    launchRoute = null;
    return r;
  }
}
