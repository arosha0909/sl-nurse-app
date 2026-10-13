import 'models.dart';

/// Everything the screens need from the backend. Implemented by [ApiRepository]
/// (sl-nurse-api) and [MockRepository] (demo mode and tests).
abstract interface class NurseRepository {
  Future<UserProfile> me();
  Future<UserProfile> updateProfile(Json changes);

  /// All shifts in [from]..[to] (inclusive), following pagination.
  Future<List<Shift>> shifts({
    required DateTime from,
    required DateTime to,
    ShiftStatus? status,
  });
  Future<Shift> createShift(ShiftDraft draft);
  Future<Shift> updateShift(String id, ShiftUpdate update);
  Future<void> deleteShift(String id);
  Future<BulkResult> bulkShifts(
    List<ShiftDraft> drafts, {
    bool overwrite = false,
  });

  Future<RosterScanResult> scanRoster({
    required int month,
    required int year,
    List<int>? imageBytes,
    String? filename,
    String? mimeType,
    String? rawText,
    String? rowLabel,
  });

  Future<SalaryForecast> forecast({required int month, required int year});
  Future<WorkTrends> workTrends({int months = 3});
  Future<SalaryConfig> salaryConfig();
  Future<SalaryConfig> updateSalaryConfig(SalaryConfig config);
}

/// Session operations, separate from data so the repository stays stateless.
abstract interface class AuthService {
  /// Returns the signed-in user if a stored session is still valid.
  Future<UserProfile?> restore();

  /// [emailOrPhone]: anything containing "@" is an email, otherwise a Sri Lankan mobile.
  Future<AuthResult> login(String emailOrPhone, String password);
  Future<AuthResult> register(RegisterRequest request);

  /// Exchanges a Google / Apple ID token (obtained on the device) for a session.
  Future<AuthResult> signInWithProvider(
    SignInProvider provider,
    String idToken, {
    String? fullName,
  });

  /// Providers the backend accepts (it needs client IDs configured). Empty if unknown.
  Future<Set<SignInProvider>> enabledProviders();
  Future<void> logout();
}
