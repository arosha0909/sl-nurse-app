import '../core/network/api_client.dart';
import 'models.dart';
import 'repository.dart';

class ApiRepository implements NurseRepository {
  ApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<UserProfile> me() async {
    final data = await _api.get('/auth/me') as Json;
    return UserProfile.fromJson(data['user'] as Json);
  }

  @override
  Future<UserProfile> updateProfile(Json changes) async {
    final data = await _api.patch('/auth/me', body: changes) as Json;
    return UserProfile.fromJson(data['user'] as Json);
  }

  @override
  Future<List<Shift>> shifts({
    required DateTime from,
    required DateTime to,
    ShiftStatus? status,
  }) async {
    const limit = 200;
    final result = <Shift>[];
    for (var page = 1; ; page++) {
      final data =
          await _api.get(
                '/shifts',
                query: {
                  'startDate': formatDay(from),
                  'endDate': formatDay(to),
                  'status': ?status?.api,
                  'page': '$page',
                  'limit': '$limit',
                },
              )
              as Json;
      final batch = [
        for (final s in data['shifts'] as List) Shift.fromJson(s as Json),
      ];
      result.addAll(batch);
      if (batch.length < limit) break;
    }
    return result;
  }

  @override
  Future<Shift> createShift(ShiftDraft draft) async {
    final data = await _api.post('/shifts', body: draft.toJson()) as Json;
    return Shift.fromJson(data['shift'] as Json);
  }

  @override
  Future<Shift> updateShift(String id, ShiftUpdate update) async {
    final data = await _api.put('/shifts/$id', body: update.toJson()) as Json;
    return Shift.fromJson(data['shift'] as Json);
  }

  @override
  Future<void> deleteShift(String id) => _api.delete('/shifts/$id');

  @override
  Future<BulkResult> bulkShifts(
    List<ShiftDraft> drafts, {
    bool overwrite = false,
  }) async {
    var total = const BulkResult(inserted: 0, updated: 0, skipped: 0);
    // The API accepts up to 200 rows per request.
    for (var i = 0; i < drafts.length; i += 200) {
      final chunk = drafts.sublist(i, (i + 200).clamp(0, drafts.length));
      final data =
          await _api.post(
                '/shifts/bulk',
                body: {
                  'shifts': [for (final d in chunk) d.toJson()],
                  'overwrite': overwrite,
                },
              )
              as Json;
      final r = BulkResult.fromJson(data);
      total = BulkResult(
        inserted: total.inserted + r.inserted,
        updated: total.updated + r.updated,
        skipped: total.skipped + r.skipped,
      );
    }
    return total;
  }

  @override
  Future<RosterScanResult> scanRoster({
    required int month,
    required int year,
    List<int>? imageBytes,
    String? filename,
    String? mimeType,
    String? rawText,
    String? rowLabel,
  }) async {
    final data =
        await _api.upload(
              '/roster/scan',
              fields: {
                'month': '$month',
                'year': '$year',
                if (rawText != null && rawText.isNotEmpty) 'rawText': rawText,
                if (rowLabel != null && rowLabel.isNotEmpty)
                  'rowLabel': rowLabel,
              },
              bytes: imageBytes,
              filename: filename,
              mimeType: mimeType,
            )
            as Json;
    return RosterScanResult.fromJson(data);
  }

  @override
  Future<SalaryForecast> forecast({
    required int month,
    required int year,
  }) async {
    final query = {'month': '$month', 'year': '$year'};
    try {
      final data =
          await _api.get('/analytics/predict-salary', query: query) as Json;
      return SalaryForecast.fromJson(data);
    } on ApiException catch (e) {
      // Plan without the smart forecast: the roster-based calculator is always available,
      // so the dashboard and salary tab never break for Free users.
      if (!e.isPlanLocked) rethrow;
      final data = await _api.get('/salary/predict', query: query) as Json;
      return SalaryForecast.basicFromJson(data, today: DateTime.now());
    }
  }

  @override
  Future<WorkTrends> workTrends({int months = 3}) async {
    final data =
        await _api.get('/analytics/work-trends', query: {'months': '$months'})
            as Json;
    return WorkTrends.fromJson(data);
  }

  @override
  Future<SalaryConfig> salaryConfig() async {
    final data = await _api.get('/salary/config') as Json;
    return SalaryConfig.fromJson(data['config'] as Json);
  }

  @override
  Future<SalaryConfig> updateSalaryConfig(SalaryConfig config) async {
    final data =
        await _api.put('/salary/config', body: config.toJson()) as Json;
    return SalaryConfig.fromJson(data['config'] as Json);
  }
}

class ApiAuthService implements AuthService {
  ApiAuthService(this._api);

  final ApiClient _api;

  @override
  Future<UserProfile?> restore() async {
    if (await _api.tokens.read() == null) return null;
    try {
      // Also exercises the refresh flow if the access token has expired.
      final data = await _api.get('/auth/me') as Json;
      return UserProfile.fromJson(data['user'] as Json);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return null;
      rethrow;
    }
  }

  @override
  Future<AuthResult> login(String emailOrPhone, String password) => _signIn(
    '/auth/login',
    {'identifier': emailOrPhone.trim(), 'password': password},
  );

  @override
  Future<AuthResult> register(RegisterRequest request) =>
      _signIn('/auth/register', request.toJson());

  @override
  Future<AuthResult> signInWithProvider(
    SignInProvider provider,
    String idToken, {
    String? fullName,
  }) => _signIn('/auth/oauth', {
    'provider': provider.api,
    'idToken': idToken,
    if (fullName != null && fullName.trim().isNotEmpty)
      'fullName': fullName.trim(),
  });

  @override
  Future<Set<SignInProvider>> enabledProviders() async {
    try {
      final data = await _api.get('/app/config', auth: false) as Json;
      final signIn = (data['signIn'] as Json?) ?? const {};
      return {
        for (final p in SignInProvider.values)
          if (signIn[p.api] == true) p,
      };
    } catch (_) {
      return const {}; // offline: the email/mobile form still works
    }
  }

  Future<AuthResult> _signIn(String path, Json body) async {
    final data = await _api.post(path, body: body, auth: false) as Json;
    await _api.tokens.write(ApiClient.readTokens(data['tokens'] as Json));
    return AuthResult(
      UserProfile.fromJson(data['user'] as Json),
      isNewUser: data['isNewUser'] == true,
    );
  }

  @override
  Future<void> logout() async {
    final tokens = await _api.tokens.read();
    await _api.tokens.clear();
    if (tokens == null) return;
    try {
      await _api.post(
        '/auth/logout',
        body: {'refreshToken': tokens.refreshToken},
        auth: false,
      );
    } catch (_) {
      // Signing out locally is what matters; the server session expires on its own.
    }
  }
}
