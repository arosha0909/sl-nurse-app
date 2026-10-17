import 'dart:async';

import 'models.dart';
import 'repository.dart';

/// In-memory backend for demo mode (`--dart-define=DEMO_MODE=true`) and widget tests.
///
/// Generates ~4 months of shifts on a M M E E N N Off rota anchored on today, and
/// applies writes (actions, toggles, bulk imports) so every flow can be tried offline.
class MockRepository implements NurseRepository {
  /// [newUser]: a just-registered nurse (no shifts, no salary, setup steps pending), to
  /// exercise progressive profiling. Otherwise a nurse with months of history.
  MockRepository({
    DateTime? today,
    this.latency = Duration.zero,
    bool newUser = false,
  }) : today = dayOf(today ?? DateTime.now()) {
    if (newUser) {
      startAsNewUser(fullName: 'Dilani Perera', contact: '+94771234567');
    } else {
      _seed();
    }
  }

  /// Typical basic salary used until the nurse enters theirs (the API's admin setting).
  static const estimatedBaseSalary = 55000.0;

  /// Resets to a brand-new account, as after sign-up.
  void startAsNewUser({required String fullName, required String contact}) {
    _shifts.clear();
    _profile = UserProfile(
      id: 'demo-new',
      fullName: fullName,
      email: contact.contains('@') ? contact : '',
      phone: contact.contains('@') ? '' : contact,
      hospitalOrWard: '',
      baseSalary: 0,
      defaultNightAllowance: 0,
      defaultOtHourlyRate: 0,
      salarySetup: OnboardingState.pending,
      workplaceSetup: OnboardingState.pending,
    );
    _config = const SalaryConfig(
      allowances: [],
      deductions: [],
      otRateMultiplier: 1.5,
    );
  }

  final DateTime today;
  final Duration latency;

  var _profile = const UserProfile(
    id: 'demo',
    fullName: 'Dilani Perera',
    email: 'dilani@example.lk',
    phone: '+94771234567',
    hospitalOrWard: 'Ward 07 · NHSL Colombo',
    baseSalary: 112000,
    defaultNightAllowance: 750,
    defaultOtHourlyRate: 0,
  );

  var _config = const SalaryConfig(
    allowances: [
      NamedAmount('Cost of Living Allowance (COLA)', 7800),
      NamedAmount('Interim Allowance', 5000),
    ],
    deductions: [NamedAmount("Widows' & Orphans' Pension (W&OP)", 4900)],
    otRateMultiplier: 1.5,
  );

  final _shifts = <Shift>[];
  var _nextId = 1;

  static const _rotation = [
    ShiftType.morning,
    ShiftType.morning,
    ShiftType.evening,
    ShiftType.evening,
    ShiftType.night,
    ShiftType.night,
    ShiftType.off,
  ];
  static const _otPattern = [3.0, 0.0, 2.0, 1.5, 0.0, 2.5, 4.0];

  void _seed() {
    for (var offset = -75; offset <= 35; offset++) {
      final date = DateTime(today.year, today.month, today.day + offset);
      final slot =
          offset %
          7; // Dart's % is non-negative, so past days follow the rota too
      final type = _rotation[slot];
      final ot = type == ShiftType.off
          ? (offset % 21 == 6 ? 4.0 : 0.0)
          : _otPattern[slot];
      final past = offset < 0;

      var shift = Shift(
        id: 'm${_nextId++}',
        date: date,
        type: type,
        status: past ? ShiftStatus.completed : ShiftStatus.scheduled,
        isOT: ot > 0, // future days carry rostered OT, like a real roster
        otHours: ot,
      );
      // A few realistic absences.
      if (offset == -9) {
        shift = shift.copyWith(
          status: ShiftStatus.leave,
          leaveType: LeaveType.casual,
          otHours: 0,
          isOT: false,
        );
      }
      if (offset == -23) {
        shift = shift.copyWith(
          status: ShiftStatus.leave,
          leaveType: LeaveType.sick,
          otHours: 0,
          isOT: false,
        );
      }
      if (offset == -40) {
        shift = shift.copyWith(
          status: ShiftStatus.leave,
          leaveType: LeaveType.casual,
          otHours: 0,
          isOT: false,
        );
      }
      // Today: already checked in, OT planned after the main shift.
      if (offset == 0) {
        final start = type.window(date).start;
        shift = shift.copyWith(
          checkInTime: start.subtract(const Duration(minutes: 8)),
          otHours: 3,
          isOT: true,
        );
      }
      _shifts.add(shift);
    }
  }

  Future<T> _delay<T>(T value) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return value;
  }

  /* ---------------- Profile ---------------- */
  @override
  Future<UserProfile> me() => _delay(_profile);

  @override
  Future<UserProfile> updateProfile(Json changes) {
    final base = (changes['baseSalary'] as num?)?.toDouble();
    final ward = changes['hospitalOrWard'] as String?;
    final onboarding = (changes['onboarding'] as Json?) ?? const {};
    OnboardingState? state(Object? v) =>
        v == null ? null : OnboardingState.values.firstWhere((e) => e.api == v);
    _profile = _profile.copyWith(
      fullName: changes['fullName'] as String?,
      phone: changes['phone'] as String?,
      hospitalOrWard: ward,
      baseSalary: base,
      defaultNightAllowance: (changes['defaultNightAllowance'] as num?)
          ?.toDouble(),
      defaultOtHourlyRate: (changes['defaultOtHourlyRate'] as num?)?.toDouble(),
      // Same rule as the API: supplying the data completes the setup step.
      salarySetup:
          state(onboarding['salary']) ??
          (base != null && base > 0 ? OnboardingState.completed : null),
      workplaceSetup:
          state(onboarding['workplace']) ??
          (ward != null && ward.isNotEmpty ? OnboardingState.completed : null),
    );
    return _delay(_profile);
  }

  /* ---------------- Shifts ---------------- */
  @override
  Future<List<Shift>> shifts({
    required DateTime from,
    required DateTime to,
    ShiftStatus? status,
  }) {
    final list =
        _shifts
            .where(
              (s) =>
                  !s.date.isBefore(dayOf(from)) && !s.date.isAfter(dayOf(to)),
            )
            .where((s) => status == null || s.status == status)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return _delay(list);
  }

  @override
  Future<Shift> createShift(ShiftDraft d) {
    if (_shifts.any((s) => sameDay(s.date, d.date) && s.type == d.type)) {
      throw StateError(
        'A ${d.type.api} shift already exists on ${formatDay(d.date)}',
      );
    }
    final shift = _fromDraft('m${_nextId++}', d);
    _shifts.add(shift);
    return _delay(shift);
  }

  /// Same defaults as the API: a long duty plans the rest of its span as OT.
  static Shift _fromDraft(String id, ShiftDraft d) {
    final main = d.standardHours ?? d.type.standardHours;
    final working =
        d.status != ShiftStatus.leave && d.status != ShiftStatus.missed;
    final planned = working ? (d.type.spanHours - main).clamp(0, 24) : 0.0;
    final ot = d.otHours > 0 ? d.otHours : planned.toDouble();
    return Shift(
      id: id,
      date: dayOf(d.date),
      type: d.type,
      status: d.status,
      leaveType: d.leaveType,
      isOT: ot > 0,
      otHours: ot,
      standardHours: main,
      nightAllowanceApplicable:
          working &&
          (d.type == ShiftType.night || d.type == ShiftType.twentyFour),
    );
  }

  @override
  Future<Shift> updateShift(String id, ShiftUpdate u) {
    final i = _shifts.indexWhere((s) => s.id == id);
    if (i < 0) throw StateError('Shift not found');
    var s = _shifts[i];
    final at = u.at ?? DateTime.now();

    switch (u.action) {
      case ShiftAction.checkIn:
        s = s.copyWith(checkInTime: at);
      case ShiftAction.checkOut:
        s = _checkOut(s, at);
      case ShiftAction.switchToOt:
        s = s.copyWith(
          checkOutTime: s.checkOutTime ?? at,
          otStartTime: at,
          status: ShiftStatus.completed,
          isOT: true,
        );
      case ShiftAction.endOt:
        final hours =
            (at.difference(s.otStartTime ?? at).inMinutes / 15).round() / 4;
        s = s.copyWith(otEndTime: at, otHours: hours, isOT: hours > 0);
      case null:
        break;
    }
    if (u.type != null) s = s.copyWith(type: u.type);
    if (u.standardHours != null) {
      s = s.copyWith(standardHours: u.standardHours);
    }
    if (u.leaveType != null) {
      s = s.copyWith(
        leaveType: u.leaveType,
        status: u.leaveType == LeaveType.none
            ? (u.status ?? ShiftStatus.scheduled)
            : ShiftStatus.leave,
      );
      if (u.leaveType != LeaveType.none) {
        s = s.copyWith(otHours: 0, isOT: false);
      }
    } else if (u.status != null) {
      s = s.copyWith(
        status: u.status,
        leaveType: u.status == ShiftStatus.leave ? s.leaveType : LeaveType.none,
      );
    }
    if (u.otHours != null) {
      s = s.copyWith(otHours: u.otHours, isOT: u.otHours! > 0);
    }

    _shifts[i] = s;
    return _delay(s);
  }

  /// Ends a duty: a long duty is split into main hours and automatic OT, like the API.
  static Shift _checkOut(Shift s, DateTime at) {
    final start = s.checkInTime ?? at;
    final worked = at.difference(start).inMinutes / 60;
    double quarter(double h) => (h * 4).round() / 4;
    if (!s.hasAutoOt) {
      return s.copyWith(
        checkOutTime: at,
        status: ShiftStatus.completed,
        calculatedMainHours: quarter(worked),
      );
    }
    final main = worked < s.standardHours ? worked : s.standardHours;
    final ot = quarter(worked - main);
    final mainEnd = start.add(Duration(minutes: (main * 60).round()));
    final done = Shift(
      id: s.id,
      date: s.date,
      type: s.type,
      status: ShiftStatus.completed,
      isOT: ot > 0,
      otHours: ot,
      standardHours: s.standardHours,
      calculatedMainHours: quarter(main),
      checkInTime: start,
      checkOutTime: mainEnd,
      otStartTime: ot > 0 ? mainEnd : null,
      otEndTime: ot > 0 ? at : null,
      notes: s.notes,
    );
    return done.copyWith(nightAllowanceApplicable: _overlapsNight(start, at));
  }

  /// At least an hour inside 22:00–06:00.
  static bool _overlapsNight(DateTime start, DateTime end) {
    var minutes = 0;
    for (
      var t = start;
      t.isBefore(end) && minutes < 60;
      t = t.add(const Duration(minutes: 15))
    ) {
      if (t.hour >= 22 || t.hour < 6) minutes += 15;
    }
    return minutes >= 60;
  }

  @override
  Future<Shift> startDuty(String shiftId) =>
      updateShift(shiftId, const ShiftUpdate(action: ShiftAction.checkIn));

  @override
  Future<({Shift shift, DutySummary summary})> endDuty(String shiftId) async {
    final before = _shifts.firstWhere((s) => s.id == shiftId);
    final shift = await updateShift(
      shiftId,
      ShiftUpdate(
        action: before.otInProgress ? ShiftAction.endOt : ShiftAction.checkOut,
      ),
    );
    const otRate = 700.0;
    final night = shift.nightAllowanceApplicable
        ? _profile.defaultNightAllowance
        : 0.0;
    return (
      shift: shift,
      summary: DutySummary(
        code: shift.code,
        checkIn: shift.checkInTime!,
        checkOut: shift.otEndTime ?? shift.checkOutTime!,
        mainHours: shift.mainHours,
        otHours: shift.otHours,
        nightAllowanceApplicable: shift.nightAllowanceApplicable,
        otPay: shift.otHours * otRate,
        nightAllowance: night,
        monthToDateOt: 22600,
        monthToDateNight: 6000,
      ),
    );
  }

  @override
  Future<void> deleteShift(String id) {
    _shifts.removeWhere((s) => s.id == id);
    return _delay(null);
  }

  @override
  Future<BulkResult> bulkShifts(
    List<ShiftDraft> drafts, {
    bool overwrite = false,
  }) {
    var inserted = 0, updated = 0, skipped = 0;
    for (final d in drafts) {
      final i = _shifts.indexWhere(
        (s) => sameDay(s.date, d.date) && s.type == d.type,
      );
      if (i < 0) {
        _shifts.add(_fromDraft('m${_nextId++}', d));
        inserted++;
      } else if (overwrite) {
        // Like the API, an overwrite replaces roster fields but keeps recorded times.
        final old = _shifts[i];
        _shifts[i] = _fromDraft(old.id, d).copyWith(
          checkInTime: old.checkInTime,
          checkOutTime: old.checkOutTime,
          otStartTime: old.otStartTime,
          otEndTime: old.otEndTime,
        );
        updated++;
      } else {
        skipped++;
      }
    }
    return _delay(
      BulkResult(inserted: inserted, updated: updated, skipped: skipped),
    );
  }

  /* ---------------- Roster OCR ---------------- */
  @override
  Future<RosterScanResult> scanRoster({
    required int month,
    required int year,
    List<int>? imageBytes,
    String? filename,
    String? mimeType,
    String? rawText,
    String? rowLabel,
  }) {
    final days = DateTime(year, month + 1, 0).day;
    final rows = <ParsedRosterShift>[
      for (var d = 1; d <= days; d++)
        ParsedRosterShift(
          date: DateTime(year, month, d),
          type: _rotation[(d - 1) % 7],
          status: d == 12 ? ShiftStatus.leave : ShiftStatus.scheduled,
          leaveType: d == 12 ? LeaveType.casual : LeaveType.none,
          otHours: d == 9 ? 3 : 0,
          source: d == 12
              ? 'CL'
              : (d == 9 ? '1/OT3' : _rotation[(d - 1) % 7].code),
          // One smudged cell, as real photos usually have.
          confidence: d == 17 ? 0.6 : 0.86,
        ),
    ];
    return _delay(
      RosterScanResult(
        shifts: rows,
        unparsed: const [
          'WARD 07 - NURSING DUTY ROSTER — Not a recognisable roster line',
        ],
        warnings: const ['1 entry has low confidence; please double-check it.'],
        provider: 'demo',
        confidence: 0.9,
      ),
    );
  }

  /* ---------------- Salary ---------------- */
  @override
  Future<SalaryForecast> forecast({required int month, required int year}) {
    if (_shifts.isEmpty) return _delay(_newUserForecast(month, year));
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final isCurrent = month == today.month && year == today.year;
    final elapsed = isCurrent
        ? today.day - 1
        : (DateTime(year, month).isBefore(today) ? daysInMonth : 0);
    final f = elapsed / daysInMonth;
    const allowances = 12800.0, otRate = 700.0, night = 750.0;
    final otCompleted = 32 * f / 0.45;
    return _delay(
      SalaryForecast(
        month: month,
        year: year,
        daysInMonth: daysInMonth,
        daysElapsed: elapsed,
        currentEarned:
            112000 * f + allowances * f + otCompleted * otRate + 8 * f * night,
        earnedBreakdown: {
          'basicProRata': 112000 * f,
          'allowancesProRata': allowances * f,
          'overtime': otCompleted * otRate,
          'nightAllowance': 8 * f * night,
        },
        projectedGross: 153400,
        projectedDeductions: 4900,
        projectedNet: 148500,
        rangeLow: 145200,
        rangeHigh: 151900,
        rosterOnlyNet: 141900,
        baseSalary: 112000,
        allowances: allowances,
        nightShifts: 8,
        nightAmount: 6000,
        otHourlyRate: otRate,
        otAmount: 22600,
        configuredDeductions: 4900,
        noPayAmount: 0,
        otCompleted: double.parse(otCompleted.clamp(0, 70).toStringAsFixed(1)),
        otScheduled: 12,
        otExpectedExtra: 6.3,
        otTotal: 32.3,
        otRangeLow: 28.9,
        otRangeHigh: 35.7,
        otHistoricalAverage: 30.5,
        confidencePercent: 86,
        confidenceLevel: 'High',
        confidenceFactors: const {
          'monthElapsed': 0.42,
          'rosterCoverage': 0.95,
          'otConsistency': 0.81,
          'attendanceReliability': 0.97,
          'historyDepth': 1,
        },
        monthsWithData: 3,
        otByWeekday: const [
          WeekdayOt(
            weekday: 'Sunday',
            avgHours: 1.2,
            frequency: 0.3,
            consistent: false,
          ),
          WeekdayOt(
            weekday: 'Monday',
            avgHours: 2.4,
            frequency: 0.7,
            consistent: true,
          ),
          WeekdayOt(
            weekday: 'Tuesday',
            avgHours: 0.8,
            frequency: 0.25,
            consistent: false,
          ),
          WeekdayOt(
            weekday: 'Wednesday',
            avgHours: 1.6,
            frequency: 0.5,
            consistent: false,
          ),
          WeekdayOt(
            weekday: 'Thursday',
            avgHours: 1.1,
            frequency: 0.4,
            consistent: false,
          ),
          WeekdayOt(
            weekday: 'Friday',
            avgHours: 2.9,
            frequency: 0.8,
            consistent: true,
          ),
          WeekdayOt(
            weekday: 'Saturday',
            avgHours: 1.9,
            frequency: 0.55,
            consistent: false,
          ),
        ],
        consistentOtDays: const ['Monday', 'Friday'],
        assumptions: const [
          'OT rate derived as basic ÷ 240 hours × 1.5 = LKR 700/hour.',
          'Basic salary and fixed allowances accrue evenly over the calendar month.',
          'Extra OT and absences are estimated from your last 3 month(s) of records, weighting recent months more.',
        ],
        warnings: const [],
      ),
    );
  }

  /// A just-registered nurse: basic salary only (her own, or the typical estimate).
  SalaryForecast _newUserForecast(int month, int year) {
    final days = DateTime(year, month + 1, 0).day;
    final base = _profile.salaryIsEstimate
        ? estimatedBaseSalary
        : _profile.baseSalary;
    final otRate = _profile.defaultOtHourlyRate > 0
        ? _profile.defaultOtHourlyRate
        : base / 240 * 1.5;
    final elapsed = month == today.month && year == today.year
        ? today.day - 1
        : 0;
    return SalaryForecast(
      salaryIsEstimate: _profile.salaryIsEstimate,
      month: month,
      year: year,
      daysInMonth: days,
      daysElapsed: elapsed,
      currentEarned: base * elapsed / days,
      earnedBreakdown: {'basicProRata': base * elapsed / days},
      projectedGross: base,
      projectedDeductions: 0,
      projectedNet: base,
      rangeLow: base,
      rangeHigh: base,
      rosterOnlyNet: base,
      baseSalary: base,
      allowances: 0,
      nightShifts: 0,
      nightAmount: 0,
      otHourlyRate: otRate,
      otAmount: 0,
      configuredDeductions: 0,
      noPayAmount: 0,
      otCompleted: 0,
      otScheduled: 0,
      otExpectedExtra: 0,
      otTotal: 0,
      otRangeLow: 0,
      otRangeHigh: 0,
      otHistoricalAverage: null,
      confidencePercent: 40,
      confidenceLevel: 'Low',
      confidenceFactors: const {
        'monthElapsed': 0,
        'rosterCoverage': 0,
        'otConsistency': 0.5,
        'attendanceReliability': 0.8,
        'historyDepth': 0,
      },
      monthsWithData: 0,
      otByWeekday: const [],
      consistentOtDays: const [],
      assumptions: [
        if (_profile.salaryIsEstimate)
          'Using a typical basic salary of LKR 55,000 until you add yours.',
        'Add your roster to include OT and night allowances.',
      ],
      warnings: const ['No shifts recorded for this month yet.'],
    );
  }

  @override
  Future<WorkTrends> workTrends({int months = 3}) {
    return _delay(
      WorkTrends(
        workedShifts: 71,
        percentages: const {
          'Morning': 33.8,
          'Evening': 32.4,
          'Night': 28.2,
          'OffDayOT': 5.6,
        },
        doubleShiftDays: 2,
        regularHours: 512,
        otHours: 96.5,
        otRatio: 0.16,
        avgWeeklyHours: 46.8,
        monthly: [
          for (var m = months - 1; m >= 0; m--)
            MonthlyWork(
              month: formatDay(
                DateTime(today.year, today.month - m),
              ).substring(0, 7),
              workedShifts: 24 - m,
              regularHours: 170.0 - m * 6,
              otHours: 28.0 + (m.isEven ? 4 : -3),
            ),
        ],
        otTrend: 'rising',
        burnoutScore: 41,
        burnoutLevel: 'Moderate',
        burnoutIndicators: const {
          'avgWeeklyHours': 46.8,
          'nightShare': 0.28,
          'longestWorkStreakDays': 6,
          'longestNightStreak': 2,
          'quickReturns': 3,
          'extendedDutyStretches': 1,
          'otRatio': 0.16,
        },
        burnoutReasons: const [
          '3 quick return(s) with less than 11 hours of rest.',
          '1 continuous duty stretch(es) longer than 16 hours.',
          'Overtime has been rising compared with previous months.',
        ],
        disclaimer:
            'A workload indicator based on your logged shifts, not a medical assessment.',
      ),
    );
  }

  @override
  Future<SalaryConfig> salaryConfig() => _delay(_config);

  @override
  Future<SalaryConfig> updateSalaryConfig(SalaryConfig config) {
    _config = config;
    return _delay(_config);
  }

  @override
  Future<List<Announcement>> announcements() => _delay([
    Announcement(
      id: 'welcome',
      title: 'Welcome to Nurse Companion',
      body:
          'Add your roster and tap Start duty on each shift. Your OT and salary are worked out for you.',
      at: DateTime(today.year, today.month, today.day - 2, 9),
    ),
  ]);

  /// Illustrative figures for the demo only, labelled as samples.
  @override
  Future<List<SalaryScale>> salaryScales() => _delay(const [
    SalaryScale(
      code: 'NO-III',
      name: 'Nursing Officer – Grade III (sample)',
      initial: 50000,
      increment: 1000,
      steps: 10,
    ),
    SalaryScale(
      code: 'NO-II',
      name: 'Nursing Officer – Grade II (sample)',
      initial: 60000,
      increment: 1200,
      steps: 10,
    ),
  ]);

  @override
  Future<void> swapShift(
    String shiftId, {
    required String colleague,
    DateTime? takeDate,
    ShiftType? takeType,
  }) async {
    final i = _shifts.indexWhere((s) => s.id == shiftId);
    if (i < 0) throw StateError('Shift not found');
    if (takeDate != null && takeType != null) {
      final taken = _fromDraft(
        'm${_nextId++}',
        ShiftDraft(date: takeDate, type: takeType),
      );
      _shifts.add(taken.copyWith(swappedWith: colleague));
    }
    _shifts[i] = _shifts[i].copyWith(
      status: ShiftStatus.swapped,
      otHours: 0,
      isOT: false,
      swappedWith: colleague,
    );
    await _delay(null);
  }
}

/// Demo sign-in: any credentials work.
class MockAuthService implements AuthService {
  MockAuthService(this._repo, {this.signedIn = true});

  final MockRepository _repo;
  bool signedIn;

  @override
  Future<UserProfile?> restore() async => signedIn ? _repo.me() : null;

  @override
  Future<AuthResult> login(String emailOrPhone, String password) async {
    signedIn = true;
    return AuthResult(await _repo.me());
  }

  @override
  Future<AuthResult> register(RegisterRequest request) async {
    signedIn = true;
    _repo.startAsNewUser(
      fullName: request.fullName,
      contact: request.emailOrPhone.trim(),
    );
    return AuthResult(await _repo.me(), isNewUser: true);
  }

  /// Demo: Google / Apple sign-in always creates a fresh account.
  @override
  Future<AuthResult> signInWithProvider(
    SignInProvider provider,
    String idToken, {
    String? fullName,
  }) async {
    signedIn = true;
    _repo.startAsNewUser(
      fullName: fullName ?? 'Nurse',
      contact: 'nurse@example.lk',
    );
    return AuthResult(await _repo.me(), isNewUser: true);
  }

  @override
  Future<Set<SignInProvider>> enabledProviders() async =>
      SignInProvider.values.toSet();

  @override
  Future<void> logout() async => signedIn = false;
}
