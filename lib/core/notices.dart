import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import 'device_prefs.dart';
import 'format.dart';

/// What a notification is about; decides its icon and what tapping it opens.
enum NoticeKind {
  shiftStart,
  forgotStart,
  mainEnd,
  otEnd,
  otSwitch,
  daySummary,
  payDetails,
  announcement;

  static NoticeKind parse(Object? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => announcement);

  /// Planned from the roster; replaced every time the roster changes.
  bool get fromRoster =>
      this == shiftStart ||
      this == forgotStart ||
      this == mainEnd ||
      this == otEnd;
}

/// Where tapping a notification takes the nurse.
abstract final class NoticeRoute {
  static const home = 'home';
  static const pay = 'pay';
  static const inbox = 'inbox';
}

/// One notification: pushed by the phone at [at] and kept in the in-app inbox.
@immutable
class Notice {
  const Notice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.route = NoticeRoute.home,
    this.read = false,
  });

  factory Notice.fromJson(Map<String, dynamic> j) => Notice(
    id: j['id'] as int,
    kind: NoticeKind.parse(j['kind']),
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
    route: j['route'] as String? ?? NoticeRoute.home,
    read: j['read'] as bool? ?? false,
  );

  /// Stable per subject (e.g. shift + kind), so re-planning replaces instead of duplicating.
  final int id;
  final NoticeKind kind;
  final String title;
  final String body;
  final DateTime at;
  final String route;
  final bool read;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'body': body,
    'at': at.millisecondsSinceEpoch,
    'route': route,
    'read': read,
  };

  Notice copyWith({bool? read}) => Notice(
    id: id,
    kind: kind,
    title: title,
    body: body,
    at: at,
    route: route,
    read: read ?? this.read,
  );
}

/// Stable 31-bit id for a subject string (Android notification ids are ints).
int noticeId(String subject) {
  var h = 0x811c9dc5;
  for (final c in subject.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/// Translates a notification text into the nurse's language.
typedef NoticeTr = String Function(String text, [Map<String, Object?> args]);

/// Which duty notifications to plan, and how early.
class NoticeOptions {
  const NoticeOptions({
    this.lead = const Duration(minutes: 60),
    this.start = true,
    this.forgotStart = true,
    this.endReminders = true,
  });

  final Duration lead;
  final bool start;
  final bool forgotStart;
  final bool endReminders;

  /// End reminders use the chosen lead, but never more than 30 minutes ahead.
  Duration get endLead =>
      lead > const Duration(minutes: 30) ? const Duration(minutes: 30) : lead;
}

/// How long after the rostered start a forgotten Start duty is nudged.
const forgotStartGrace = Duration(minutes: 15);

/// "5 min", "1 h", "2 h"
String leadText(Duration d, NoticeTr tr) => d.inMinutes < 60
    ? tr('{n} min', {'n': d.inMinutes})
    : tr('{n} h', {'n': d.inMinutes ~/ 60});

/// Every duty notification the roster calls for, from [now] on. Pure, so it is unit-tested.
///
///  - before a duty starts ([NoticeOptions.lead] ahead)
///  - when the start time has passed without Start duty
///  - before the main shift ends, and before planned OT ends
List<Notice> planDutyNotices(
  List<Shift> shifts,
  DateTime now,
  NoticeOptions o,
  NoticeTr tr,
) {
  final out = <Notice>[];
  for (final s in shifts) {
    final working =
        s.type != ShiftType.off &&
        !s.isLeave &&
        !s.isSwapped &&
        s.status != ShiftStatus.missed;
    if (!working || s.status == ShiftStatus.completed) continue;

    final name = tr(s.type.label);
    final start = s.type.window(s.date).start;
    final notStarted = s.checkInTime == null;

    if (notStarted && o.start) {
      out.add(
        Notice(
          id: noticeId('${s.id}:start'),
          kind: NoticeKind.shiftStart,
          title: tr('{shift} in {lead}', {
            'shift': name,
            'lead': leadText(o.lead, tr),
          }),
          body: s.otHours > 0
              ? tr('Starts at {time} · {hours} h OT planned', {
                  'time': Fmt.time(start),
                  'hours': Fmt.hours(s.otHours),
                })
              : tr('Starts at {time}', {'time': Fmt.time(start)}),
          at: start.subtract(o.lead),
        ),
      );
    }
    if (notStarted && o.forgotStart) {
      out.add(
        Notice(
          id: noticeId('${s.id}:forgot'),
          kind: NoticeKind.forgotStart,
          title: tr('Did you start your duty?'),
          body: tr(
            'Your {shift} started at {time}. Tap Start duty so your hours and OT are counted.',
            {'shift': name, 'time': Fmt.time(start)},
          ),
          at: start.add(forgotStartGrace),
        ),
      );
    }
    if (!o.endReminders) continue;

    // The main shift ends a set number of hours after the (actual or rostered) start.
    final mainStart = s.checkInTime ?? start;
    final mainEnd = s.hasAutoOt || s.checkInTime != null
        ? mainStart.add(Duration(minutes: (s.standardHours * 60).round()))
        : start.add(Duration(minutes: (s.type.standardHours * 60).round()));
    if (s.checkOutTime == null) {
      out.add(
        Notice(
          id: noticeId('${s.id}:mainEnd'),
          kind: NoticeKind.mainEnd,
          title: tr('Main shift ends in {lead}', {
            'lead': leadText(o.endLead, tr),
          }),
          body: s.hasAutoOt
              ? tr('OT starts automatically at {time}. No need to sign out.', {
                  'time': Fmt.time(mainEnd),
                })
              : tr('Your main shift ends at {time}. End duty, or stay on OT.', {
                  'time': Fmt.time(mainEnd),
                }),
          at: mainEnd.subtract(o.endLead),
        ),
      );
    }

    // Planned OT: the rest of a long duty, or OT rostered after a standard shift.
    final otStart = s.otStartTime ?? mainEnd;
    final otHours = s.hasAutoOt
        ? s.type.spanHours - s.standardHours
        : s.otHours;
    if (otHours > 0 && s.otEndTime == null) {
      final otEnd = otStart.add(Duration(minutes: (otHours * 60).round()));
      out.add(
        Notice(
          id: noticeId('${s.id}:otEnd'),
          kind: NoticeKind.otEnd,
          title: tr('OT ends in {lead}', {'lead': leadText(o.endLead, tr)}),
          body: tr('Your OT ends at {time}. Tap End duty when you leave.', {
            'time': Fmt.time(otEnd),
          }),
          at: otEnd.subtract(o.endLead),
        ),
      );
    }
  }
  return out.where((n) => n.at.isAfter(now)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
}

/// Every notification the nurse has had (or has coming), for the in-app list.
/// Kept on the phone, newest first; future ones appear once their time comes.
class NoticeInbox extends ChangeNotifier {
  NoticeInbox(this._prefs) {
    final raw = _prefs.read(_key);
    if (raw != null) {
      try {
        _items.addAll([
          for (final j in jsonDecode(raw) as List)
            Notice.fromJson(j as Map<String, dynamic>),
        ]);
      } catch (_) {
        // A corrupt list only loses history.
      }
    }
  }

  static const _key = 'inbox';
  static const _max = 120;

  final DevicePrefs _prefs;
  final List<Notice> _items = [];

  /// Notifications that have happened by [now], newest first.
  List<Notice> visible(DateTime now) =>
      _items.where((n) => !n.at.isAfter(now)).toList()
        ..sort((a, b) => b.at.compareTo(a.at));

  int unread(DateTime now) => visible(now).where((n) => !n.read).length;

  /// Replaces the roster-planned notices with [planned], keeping the ones already shown.
  Future<void> replacePlanned(List<Notice> planned, DateTime now) async {
    _items.removeWhere((n) => n.kind.fromRoster && n.at.isAfter(now));
    _upsertAll(planned);
    await _save();
  }

  Future<void> add(Notice notice) async {
    _upsertAll([notice]);
    await _save();
  }

  /// Server announcements, kept read/unread across refreshes.
  Future<void> mergeAnnouncements(List<Notice> announcements) async {
    _upsertAll(announcements);
    await _save();
  }

  Future<void> markRead(int id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0 || _items[i].read) return;
    _items[i] = _items[i].copyWith(read: true);
    await _save();
  }

  Future<void> markAllRead(DateTime now) async {
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].at.isAfter(now)) {
        _items[i] = _items[i].copyWith(read: true);
      }
    }
    await _save();
  }

  void _upsertAll(List<Notice> notices) {
    for (final n in notices) {
      final i = _items.indexWhere((x) => x.id == n.id);
      if (i < 0) {
        _items.add(n);
      } else {
        // Keep "read" when the same notice is planned again.
        _items[i] = Notice(
          id: n.id,
          kind: n.kind,
          title: n.title,
          body: n.body,
          at: n.at,
          route: n.route,
          read: _items[i].read && _items[i].at == n.at,
        );
      }
    }
    _items.sort((a, b) => b.at.compareTo(a.at));
    if (_items.length > _max) _items.removeRange(_max, _items.length);
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.write(_key, jsonEncode([for (final n in _items) n.toJson()]));
  }
}
