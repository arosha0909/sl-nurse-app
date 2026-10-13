/// Domain models mirroring the sl-nurse-api JSON contracts.
///
/// Dates: shifts are calendar days. The API sends `YYYY-MM-DD`; the app keeps them as
/// local midnight `DateTime`s so they compare naturally with the device calendar.
library;

/* ------------------------------------------------------------------ *
 * Enums with API string mapping
 * ------------------------------------------------------------------ */
enum ShiftType {
  morning('Morning'),
  evening('Evening'),
  night('Night'),
  off('Off');

  const ShiftType(this.api);
  final String api;

  static ShiftType parse(String v) =>
      values.firstWhere((e) => e.api == v, orElse: () => ShiftType.off);

  String get label => switch (this) {
    ShiftType.morning => 'Morning Shift',
    ShiftType.evening => 'Evening Shift',
    ShiftType.night => 'Night Shift',
    ShiftType.off => 'Day Off',
  };

  String get short => switch (this) {
    ShiftType.morning => 'M',
    ShiftType.evening => 'E',
    ShiftType.night => 'N',
    ShiftType.off => 'Off',
  };

  /// Standard Sri Lankan government hospital duty windows (local time).
  int get startHour => switch (this) {
    ShiftType.morning => 7,
    ShiftType.evening => 13,
    ShiftType.night => 19,
    ShiftType.off => 0,
  };

  double get standardHours => switch (this) {
    ShiftType.morning || ShiftType.evening => 6,
    ShiftType.night => 12,
    ShiftType.off => 0,
  };

  String get timeRange => switch (this) {
    ShiftType.morning => '07:00 AM – 01:00 PM',
    ShiftType.evening => '01:00 PM – 07:00 PM',
    ShiftType.night => '07:00 PM – 07:00 AM',
    ShiftType.off => 'Rest day',
  };

  /// Scheduled start/end instants on [day] (end may be the next morning).
  ({DateTime start, DateTime end}) window(DateTime day) {
    final start = DateTime(day.year, day.month, day.day, startHour);
    return (
      start: start,
      end: start.add(Duration(minutes: (standardHours * 60).round())),
    );
  }
}

enum ShiftStatus {
  scheduled('Scheduled'),
  completed('Completed'),
  missed('Missed'),
  leave('Leave');

  const ShiftStatus(this.api);
  final String api;

  static ShiftStatus parse(String v) =>
      values.firstWhere((e) => e.api == v, orElse: () => ShiftStatus.scheduled);
}

enum LeaveType {
  none('None'),
  casual('Casual'),
  sick('Sick'),
  noPay('NoPay'),
  halfDay('HalfDay');

  const LeaveType(this.api);
  final String api;

  static LeaveType parse(String v) =>
      values.firstWhere((e) => e.api == v, orElse: () => LeaveType.none);

  String get label => switch (this) {
    LeaveType.none => 'None',
    LeaveType.casual => 'Casual leave',
    LeaveType.sick => 'Sick leave',
    LeaveType.noPay => 'No-pay leave',
    LeaveType.halfDay => 'Half day',
  };
}

/// Workflow actions accepted by `PUT /shifts/:id`.
enum ShiftAction {
  checkIn('CHECK_IN'),
  checkOut('CHECK_OUT'),
  switchToOt('SWITCH_TO_OT'),
  endOt('END_OT');

  const ShiftAction(this.api);
  final String api;

  String get label => switch (this) {
    ShiftAction.checkIn => 'Check in',
    ShiftAction.checkOut => 'Check out',
    ShiftAction.switchToOt => 'Sign out & start OT',
    ShiftAction.endOt => 'End OT',
  };
}

/* ------------------------------------------------------------------ *
 * JSON helpers
 * ------------------------------------------------------------------ */
typedef Json = Map<String, dynamic>;

double _num(Object? v) => v is num ? v.toDouble() : 0;
int _int(Object? v) => v is num ? v.round() : 0;
DateTime? _instant(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// "2026-10-13" → local midnight.
DateTime parseDay(String v) {
  final p = v.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String formatDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/* ------------------------------------------------------------------ *
 * User
 * ------------------------------------------------------------------ */
/// Progressive profiling: optional setup steps are asked for when first needed.
enum OnboardingState {
  pending('pending'),
  completed('completed'),
  skipped('skipped');

  const OnboardingState(this.api);
  final String api;

  /// Accounts created before progressive profiling have no state: treat as completed.
  static OnboardingState parse(Object? v) => values.firstWhere(
    (e) => e.api == v,
    orElse: () => OnboardingState.completed,
  );
}

enum SignInProvider {
  google('google'),
  apple('apple');

  const SignInProvider(this.api);
  final String api;

  String get label => this == SignInProvider.google ? 'Google' : 'Apple';
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.hospitalOrWard,
    required this.baseSalary,
    required this.defaultNightAllowance,
    required this.defaultOtHourlyRate,
    this.salarySetup = OnboardingState.completed,
    this.workplaceSetup = OnboardingState.completed,
    this.providers = const [],
    this.hasPassword = true,
  });

  factory UserProfile.fromJson(Json j) {
    final onboarding = j['onboarding'] as Json?;
    return UserProfile(
      id: j['id'] as String? ?? '',
      fullName: j['fullName'] as String? ?? '',
      email: j['email'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      hospitalOrWard: j['hospitalOrWard'] as String? ?? '',
      baseSalary: _num(j['baseSalary']),
      defaultNightAllowance: _num(j['defaultNightAllowance']),
      defaultOtHourlyRate: _num(j['defaultOtHourlyRate']),
      salarySetup: OnboardingState.parse(onboarding?['salary']),
      workplaceSetup: OnboardingState.parse(onboarding?['workplace']),
      providers: [
        for (final p in (j['providers'] as List? ?? const []))
          ...SignInProvider.values.where((e) => e.api == p),
      ],
      hasPassword: j['hasPassword'] as bool? ?? true,
    );
  }

  final String id;
  final String fullName;

  /// Empty when the account was created with a mobile number only (and vice versa).
  final String email;
  final String phone;
  final String hospitalOrWard;
  final double baseSalary;
  final double defaultNightAllowance;
  final double defaultOtHourlyRate;
  final OnboardingState salarySetup;
  final OnboardingState workplaceSetup;
  final List<SignInProvider> providers;
  final bool hasPassword;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// Email, or the mobile number for phone-only accounts.
  String get contact => email.isNotEmpty ? email : phone;

  /// True until the nurse enters a basic salary: forecasts use a typical estimate.
  bool get salaryIsEstimate =>
      baseSalary <= 0 && salarySetup != OnboardingState.completed;

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? hospitalOrWard,
    double? baseSalary,
    double? defaultNightAllowance,
    double? defaultOtHourlyRate,
    OnboardingState? salarySetup,
    OnboardingState? workplaceSetup,
  }) => UserProfile(
    id: id,
    email: email,
    providers: providers,
    hasPassword: hasPassword,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    hospitalOrWard: hospitalOrWard ?? this.hospitalOrWard,
    baseSalary: baseSalary ?? this.baseSalary,
    defaultNightAllowance: defaultNightAllowance ?? this.defaultNightAllowance,
    defaultOtHourlyRate: defaultOtHourlyRate ?? this.defaultOtHourlyRate,
    salarySetup: salarySetup ?? this.salarySetup,
    workplaceSetup: workplaceSetup ?? this.workplaceSetup,
  );
}

/// Minimal sign-up: a name, one way to reach the nurse and a password.
/// Pay details and workplace are collected later, in context.
class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.emailOrPhone,
    required this.password,
  });

  final String fullName;

  /// Anything containing "@" is sent as an email, otherwise as a Sri Lankan mobile.
  final String emailOrPhone;
  final String password;

  bool get isEmail => emailOrPhone.contains('@');

  Json toJson() => {
    'fullName': fullName,
    if (isEmail) 'email': emailOrPhone.trim() else 'phone': emailOrPhone.trim(),
    'password': password,
  };
}

/// Result of any sign-in: the user, and whether this request created the account.
class AuthResult {
  const AuthResult(this.user, {this.isNewUser = false});

  final UserProfile user;
  final bool isNewUser;
}

/* ------------------------------------------------------------------ *
 * Shifts
 * ------------------------------------------------------------------ */
class Shift {
  const Shift({
    required this.id,
    required this.date,
    required this.type,
    this.status = ShiftStatus.scheduled,
    this.leaveType = LeaveType.none,
    this.isOT = false,
    this.otHours = 0,
    this.checkInTime,
    this.checkOutTime,
    this.otStartTime,
    this.otEndTime,
    this.notes,
  });

  factory Shift.fromJson(Json j) => Shift(
    id: j['id'] as String,
    date: parseDay(j['date'] as String),
    type: ShiftType.parse(j['shiftType'] as String),
    status: ShiftStatus.parse(j['status'] as String? ?? 'Scheduled'),
    leaveType: LeaveType.parse(j['leaveType'] as String? ?? 'None'),
    isOT: j['isOT'] as bool? ?? false,
    otHours: _num(j['otHours']),
    checkInTime: _instant(j['checkInTime']),
    checkOutTime: _instant(j['checkOutTime']),
    otStartTime: _instant(j['otStartTime']),
    otEndTime: _instant(j['otEndTime']),
    notes: j['notes'] as String?,
  );

  final String id;
  final DateTime date;
  final ShiftType type;
  final ShiftStatus status;
  final LeaveType leaveType;
  final bool isOT;
  final double otHours;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime? otStartTime;
  final DateTime? otEndTime;
  final String? notes;

  bool get isLeave => status == ShiftStatus.leave;
  bool get isWork => type != ShiftType.off || otHours > 0;
  bool get isWorked => status == ShiftStatus.completed && isWork;
  bool get otInProgress => otStartTime != null && otEndTime == null;

  /// Hours on the main shift: real clock times when recorded and plausible.
  double get mainHours {
    if (isLeave || status == ShiftStatus.missed || type == ShiftType.off) {
      return 0;
    }
    if (checkInTime != null && checkOutTime != null) {
      final h = checkOutTime!.difference(checkInTime!).inMinutes / 60;
      if (h >= 1 && h <= 16) return h;
    }
    return type.standardHours;
  }

  /// Next step of the attendance workflow, or null when the day is settled.
  ShiftAction? get nextAction {
    if (isLeave || status == ShiftStatus.missed || type == ShiftType.off) {
      return null;
    }
    if (checkInTime == null) return ShiftAction.checkIn;
    if (otInProgress) return ShiftAction.endOt;
    if (checkOutTime == null) return ShiftAction.checkOut;
    return null;
  }

  Shift copyWith({
    ShiftType? type,
    ShiftStatus? status,
    LeaveType? leaveType,
    bool? isOT,
    double? otHours,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    DateTime? otStartTime,
    DateTime? otEndTime,
  }) => Shift(
    id: id,
    date: date,
    notes: notes,
    type: type ?? this.type,
    status: status ?? this.status,
    leaveType: leaveType ?? this.leaveType,
    isOT: isOT ?? this.isOT,
    otHours: otHours ?? this.otHours,
    checkInTime: checkInTime ?? this.checkInTime,
    checkOutTime: checkOutTime ?? this.checkOutTime,
    otStartTime: otStartTime ?? this.otStartTime,
    otEndTime: otEndTime ?? this.otEndTime,
  );
}

/// A shift to create (single or bulk).
class ShiftDraft {
  const ShiftDraft({
    required this.date,
    required this.type,
    this.status = ShiftStatus.scheduled,
    this.leaveType = LeaveType.none,
    this.otHours = 0,
  });

  final DateTime date;
  final ShiftType type;
  final ShiftStatus status;
  final LeaveType leaveType;
  final double otHours;

  Json toJson() => {
    'date': formatDay(date),
    'shiftType': type.api,
    'status': status.api,
    'leaveType': leaveType.api,
    if (otHours > 0) 'otHours': otHours,
  };
}

/// Partial update for `PUT /shifts/:id`; only non-null fields are sent.
class ShiftUpdate {
  const ShiftUpdate({
    this.action,
    this.at,
    this.type,
    this.status,
    this.leaveType,
    this.otHours,
  });

  final ShiftAction? action;
  final DateTime? at;
  final ShiftType? type;
  final ShiftStatus? status;
  final LeaveType? leaveType;
  final double? otHours;

  Json toJson() => {
    if (action != null) 'action': action!.api,
    if (at != null) 'at': at!.toUtc().toIso8601String(),
    if (type != null) 'shiftType': type!.api,
    if (status != null) 'status': status!.api,
    if (leaveType != null) 'leaveType': leaveType!.api,
    if (otHours != null) 'otHours': otHours,
  };
}

class BulkResult {
  const BulkResult({
    required this.inserted,
    required this.updated,
    required this.skipped,
  });

  factory BulkResult.fromJson(Json j) => BulkResult(
    inserted: _int(j['inserted']),
    updated: _int(j['updated']),
    skipped: _int(j['skipped']),
  );

  final int inserted;
  final int updated;
  final int skipped;
}

/* ------------------------------------------------------------------ *
 * Roster OCR
 * ------------------------------------------------------------------ */
class ParsedRosterShift {
  const ParsedRosterShift({
    required this.date,
    required this.type,
    required this.status,
    required this.leaveType,
    required this.otHours,
    required this.source,
    required this.confidence,
  });

  factory ParsedRosterShift.fromJson(Json j) => ParsedRosterShift(
    date: parseDay(j['date'] as String),
    type: ShiftType.parse(j['shiftType'] as String),
    status: ShiftStatus.parse(j['status'] as String? ?? 'Scheduled'),
    leaveType: LeaveType.parse(j['leaveType'] as String? ?? 'None'),
    otHours: _num(j['otHours']),
    source: j['source'] as String? ?? '',
    confidence: _num(j['confidence']),
  );

  final DateTime date;
  final ShiftType type;
  final ShiftStatus status;
  final LeaveType leaveType;
  final double otHours;
  final String source;
  final double confidence;

  bool get lowConfidence => confidence < 0.75;

  ParsedRosterShift copyWith({
    ShiftType? type,
    ShiftStatus? status,
    LeaveType? leaveType,
    double? otHours,
  }) => ParsedRosterShift(
    date: date,
    source: source,
    // A manual edit is, by definition, confirmed by the nurse.
    confidence: 1,
    type: type ?? this.type,
    status: status ?? this.status,
    leaveType: leaveType ?? this.leaveType,
    otHours: otHours ?? this.otHours,
  );

  ShiftDraft toDraft() => ShiftDraft(
    date: date,
    type: type,
    status: status,
    leaveType: leaveType,
    otHours: otHours,
  );
}

class RosterScanResult {
  const RosterScanResult({
    required this.shifts,
    required this.unparsed,
    required this.warnings,
    required this.provider,
    required this.confidence,
  });

  factory RosterScanResult.fromJson(Json j) {
    final ocr = (j['ocr'] as Json?) ?? const {};
    return RosterScanResult(
      shifts: [
        for (final s in (j['shifts'] as List? ?? const []))
          ParsedRosterShift.fromJson(s as Json),
      ],
      unparsed: [
        for (final u in (j['unparsed'] as List? ?? const []))
          '${(u as Json)['line']} — ${u['reason']}',
      ],
      warnings: [
        for (final w in (j['warnings'] as List? ?? const [])) w as String,
      ],
      provider: ocr['provider'] as String? ?? '',
      confidence: _num(ocr['confidence']),
    );
  }

  final List<ParsedRosterShift> shifts;
  final List<String> unparsed;
  final List<String> warnings;
  final String provider;
  final double confidence;
}

/* ------------------------------------------------------------------ *
 * Salary configuration
 * ------------------------------------------------------------------ */
class NamedAmount {
  const NamedAmount(this.name, this.amount);

  factory NamedAmount.fromJson(Json j) =>
      NamedAmount(j['name'] as String? ?? '', _num(j['amount']));

  final String name;
  final double amount;

  Json toJson() => {'name': name, 'amount': amount};
}

class SalaryConfig {
  const SalaryConfig({
    required this.allowances,
    required this.deductions,
    required this.otRateMultiplier,
  });

  factory SalaryConfig.fromJson(Json j) => SalaryConfig(
    allowances: [
      for (final a in (j['allowances'] as List? ?? const []))
        NamedAmount.fromJson(a as Json),
    ],
    deductions: [
      for (final d in (j['deductions'] as List? ?? const []))
        NamedAmount.fromJson(d as Json),
    ],
    otRateMultiplier: j['otRateMultiplier'] is num
        ? _num(j['otRateMultiplier'])
        : 1.5,
  );

  final List<NamedAmount> allowances;
  final List<NamedAmount> deductions;
  final double otRateMultiplier;

  Json toJson() => {
    'allowances': [for (final a in allowances) a.toJson()],
    'deductions': [for (final d in deductions) d.toJson()],
    'otRateMultiplier': otRateMultiplier,
  };

  SalaryConfig copyWith({
    List<NamedAmount>? allowances,
    List<NamedAmount>? deductions,
    double? otRateMultiplier,
  }) => SalaryConfig(
    allowances: allowances ?? this.allowances,
    deductions: deductions ?? this.deductions,
    otRateMultiplier: otRateMultiplier ?? this.otRateMultiplier,
  );
}

/* ------------------------------------------------------------------ *
 * Analytics: GET /analytics/predict-salary
 * ------------------------------------------------------------------ */
class WeekdayOt {
  const WeekdayOt({
    required this.weekday,
    required this.avgHours,
    required this.frequency,
    required this.consistent,
  });

  factory WeekdayOt.fromJson(Json j) => WeekdayOt(
    weekday: j['weekday'] as String? ?? '',
    avgHours: _num(j['avgOtHoursPerWorkDay']),
    frequency: _num(j['frequency']),
    consistent: j['consistent'] as bool? ?? false,
  );

  final String weekday;
  final double avgHours;
  final double frequency;
  final bool consistent;
}

class SalaryForecast {
  const SalaryForecast({
    this.salaryIsEstimate = false,
    this.isBasic = false,
    required this.month,
    required this.year,
    required this.daysInMonth,
    required this.daysElapsed,
    required this.currentEarned,
    required this.earnedBreakdown,
    required this.projectedGross,
    required this.projectedDeductions,
    required this.projectedNet,
    required this.rangeLow,
    required this.rangeHigh,
    required this.rosterOnlyNet,
    required this.baseSalary,
    required this.allowances,
    required this.nightShifts,
    required this.nightAmount,
    required this.otHourlyRate,
    required this.otAmount,
    required this.configuredDeductions,
    required this.noPayAmount,
    required this.otCompleted,
    required this.otScheduled,
    required this.otExpectedExtra,
    required this.otTotal,
    required this.otRangeLow,
    required this.otRangeHigh,
    required this.otHistoricalAverage,
    required this.confidencePercent,
    required this.confidenceLevel,
    required this.confidenceFactors,
    required this.monthsWithData,
    required this.otByWeekday,
    required this.consistentOtDays,
    required this.assumptions,
    required this.warnings,
  });

  factory SalaryForecast.fromJson(Json j) {
    final period = j['period'] as Json;
    final earned = j['currentEarned'] as Json;
    final projected = j['projectedTotalSalary'] as Json;
    final breakdown = projected['breakdown'] as Json;
    final deductions = breakdown['deductions'] as Json;
    final ot = j['predictedOtHours'] as Json;
    final confidence = j['confidenceScore'] as Json;
    final patterns = j['historicalPatterns'] as Json;
    return SalaryForecast(
      salaryIsEstimate: j['salaryIsEstimate'] as bool? ?? false,
      month: _int(period['month']),
      year: _int(period['year']),
      daysInMonth: _int(period['daysInMonth']),
      daysElapsed: _int(period['daysElapsed']),
      currentEarned: _num(earned['amount']),
      earnedBreakdown: {
        for (final e in (earned['breakdown'] as Json).entries)
          e.key: _num(e.value),
      },
      projectedGross: _num(projected['gross']),
      projectedDeductions: _num(projected['deductions']),
      projectedNet: _num(projected['net']),
      rangeLow: _num((projected['range'] as Json)['low']),
      rangeHigh: _num((projected['range'] as Json)['high']),
      rosterOnlyNet: _num(projected['rosterOnlyNet']),
      baseSalary: _num(breakdown['baseSalary']),
      allowances: _num(breakdown['allowances']),
      nightShifts: _num(
        (breakdown['nightAllowance'] as Json)['expectedShifts'],
      ),
      nightAmount: _num((breakdown['nightAllowance'] as Json)['amount']),
      otHourlyRate: _num((breakdown['overtime'] as Json)['hourlyRate']),
      otAmount: _num((breakdown['overtime'] as Json)['amount']),
      configuredDeductions: _num(deductions['configured']),
      noPayAmount: _num((deductions['noPay'] as Json)['amount']),
      otCompleted: _num(ot['completed']),
      otScheduled: _num(ot['scheduled']),
      otExpectedExtra: _num(ot['expectedExtra']),
      otTotal: _num(ot['total']),
      otRangeLow: _num((ot['range'] as Json)['low']),
      otRangeHigh: _num((ot['range'] as Json)['high']),
      otHistoricalAverage: ot['historicalMonthlyAverage'] is num
          ? _num(ot['historicalMonthlyAverage'])
          : null,
      confidencePercent: _int(confidence['percent']),
      confidenceLevel: confidence['level'] as String? ?? 'Low',
      confidenceFactors: {
        for (final e in (confidence['factors'] as Json).entries)
          e.key: _num(e.value),
      },
      monthsWithData: _int(patterns['monthsWithData']),
      otByWeekday: [
        for (final w in (patterns['otByWeekday'] as List? ?? const []))
          WeekdayOt.fromJson(w as Json),
      ],
      consistentOtDays: [
        for (final d in (patterns['consistentOtDays'] as List? ?? const []))
          d as String,
      ],
      assumptions: [
        for (final a in (j['assumptions'] as List? ?? const [])) a as String,
      ],
      warnings: [
        for (final w in (j['warnings'] as List? ?? const [])) w as String,
      ],
    );
  }

  /// The basic salary is a typical estimate until the nurse enters their own.
  final bool salaryIsEstimate;

  /// Roster-only calculation (`/salary/predict`): used when the smart forecast isn't in the
  /// nurse's plan. No history-based OT, ranges or confidence.
  final bool isBasic;

  /// Maps the roster-based `/salary/predict` payload onto the forecast shape the UI uses.
  factory SalaryForecast.basicFromJson(Json j, {required DateTime today}) {
    final period = j['period'] as Json;
    final earnings = j['earnings'] as Json;
    final ot = earnings['overtime'] as Json;
    final night = earnings['nightAllowance'] as Json;
    final deductions = j['deductions'] as Json;
    final earned = (j['earnedToDate'] as Json?) ?? const {};
    final days = _int(period['daysInMonth']);
    final elapsed = period['isPastMonth'] == true
        ? days
        : (period['isFutureMonth'] == true ? 0 : today.day - 1);
    final base = _num(earnings['baseSalary']);
    final allowances = _num(earnings['allowancesTotal']);
    final net = _num(j['netSalary']);
    final otHours = _num(ot['totalHours']);
    return SalaryForecast(
      isBasic: true,
      salaryIsEstimate: j['salaryIsEstimate'] as bool? ?? false,
      month: _int(period['month']),
      year: _int(period['year']),
      daysInMonth: days,
      daysElapsed: elapsed,
      currentEarned:
          (base + allowances) * elapsed / (days == 0 ? 1 : days) +
          _num(earned['overtime']) +
          _num(earned['nightAllowance']),
      earnedBreakdown: {
        'basicProRata': base * elapsed / (days == 0 ? 1 : days),
        'allowancesProRata': allowances * elapsed / (days == 0 ? 1 : days),
        'overtime': _num(earned['overtime']),
        'nightAllowance': _num(earned['nightAllowance']),
      },
      projectedGross: _num(earnings['gross']),
      projectedDeductions: _num(deductions['total']),
      projectedNet: net,
      rangeLow: net,
      rangeHigh: net,
      rosterOnlyNet: net,
      baseSalary: base,
      allowances: allowances,
      nightShifts: _num(night['shifts']),
      nightAmount: _num(night['amount']),
      otHourlyRate: _num(ot['hourlyRate']),
      otAmount: _num(ot['amount']),
      configuredDeductions: _num(deductions['configuredTotal']),
      noPayAmount: _num((deductions['noPay'] as Json?)?['amount']),
      otCompleted: _num(ot['completedHours']),
      otScheduled: _num(ot['plannedHours']),
      otExpectedExtra: 0,
      otTotal: otHours,
      otRangeLow: otHours,
      otRangeHigh: otHours,
      otHistoricalAverage: null,
      confidencePercent: 0,
      confidenceLevel: 'Roster-based',
      confidenceFactors: const {},
      monthsWithData: 0,
      otByWeekday: const [],
      consistentOtDays: const [],
      assumptions: [
        for (final a in (j['assumptions'] as List? ?? const [])) a as String,
      ],
      warnings: [
        for (final w in (j['warnings'] as List? ?? const [])) w as String,
      ],
    );
  }
  final int month;
  final int year;
  final int daysInMonth;
  final int daysElapsed;
  final double currentEarned;

  /// basicProRata, allowancesProRata, overtime, nightAllowance
  final Map<String, double> earnedBreakdown;
  final double projectedGross;
  final double projectedDeductions;
  final double projectedNet;
  final double rangeLow;
  final double rangeHigh;
  final double rosterOnlyNet;
  final double baseSalary;
  final double allowances;
  final double nightShifts;
  final double nightAmount;
  final double otHourlyRate;
  final double otAmount;
  final double configuredDeductions;
  final double noPayAmount;
  final double otCompleted;
  final double otScheduled;
  final double otExpectedExtra;
  final double otTotal;
  final double otRangeLow;
  final double otRangeHigh;
  final double? otHistoricalAverage;
  final int confidencePercent;
  final String confidenceLevel;

  /// monthElapsed, rosterCoverage, otConsistency, attendanceReliability, historyDepth (0..1)
  final Map<String, double> confidenceFactors;
  final int monthsWithData;
  final List<WeekdayOt> otByWeekday;
  final List<String> consistentOtDays;
  final List<String> assumptions;
  final List<String> warnings;
}

/* ------------------------------------------------------------------ *
 * Analytics: GET /analytics/work-trends
 * ------------------------------------------------------------------ */
class MonthlyWork {
  const MonthlyWork({
    required this.month,
    required this.workedShifts,
    required this.regularHours,
    required this.otHours,
  });

  factory MonthlyWork.fromJson(Json j) => MonthlyWork(
    month: j['month'] as String? ?? '',
    workedShifts: _int(j['workedShifts']),
    regularHours: _num(j['regularHours']),
    otHours: _num(j['otHours']),
  );

  final String month; // YYYY-MM
  final int workedShifts;
  final double regularHours;
  final double otHours;
}

class WorkTrends {
  const WorkTrends({
    required this.workedShifts,
    required this.percentages,
    required this.doubleShiftDays,
    required this.regularHours,
    required this.otHours,
    required this.otRatio,
    required this.avgWeeklyHours,
    required this.monthly,
    required this.otTrend,
    required this.burnoutScore,
    required this.burnoutLevel,
    required this.burnoutIndicators,
    required this.burnoutReasons,
    required this.disclaimer,
  });

  factory WorkTrends.fromJson(Json j) {
    final dist = j['distribution'] as Json;
    final hours = j['hours'] as Json;
    final burnout = j['burnout'] as Json;
    return WorkTrends(
      workedShifts: _int(dist['workedShifts']),
      percentages: {
        for (final e in (dist['percentages'] as Json).entries)
          e.key: _num(e.value),
      },
      doubleShiftDays: _int(dist['doubleShiftDays']),
      regularHours: _num(hours['regular']),
      otHours: _num(hours['overtime']),
      otRatio: _num(hours['otRatio']),
      avgWeeklyHours: _num(hours['avgWeeklyHours']),
      monthly: [
        for (final m in (j['monthly'] as List? ?? const []))
          MonthlyWork.fromJson(m as Json),
      ],
      otTrend: j['otTrend'] as String? ?? 'insufficient-data',
      burnoutScore: _int(burnout['score']),
      burnoutLevel: burnout['level'] as String? ?? 'Low',
      burnoutIndicators: {
        for (final e in (burnout['indicators'] as Json).entries)
          e.key: _num(e.value),
      },
      burnoutReasons: [
        for (final r in (burnout['reasons'] as List? ?? const [])) r as String,
      ],
      disclaimer: burnout['disclaimer'] as String? ?? '',
    );
  }

  final int workedShifts;

  /// Morning, Evening, Night, OffDayOT → percent of worked shifts.
  final Map<String, double> percentages;
  final int doubleShiftDays;
  final double regularHours;
  final double otHours;
  final double otRatio;
  final double avgWeeklyHours;
  final List<MonthlyWork> monthly;
  final String otTrend;
  final int burnoutScore;
  final String burnoutLevel;
  final Map<String, double> burnoutIndicators;
  final List<String> burnoutReasons;
  final String disclaimer;
}
