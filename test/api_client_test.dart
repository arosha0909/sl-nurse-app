import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nurse_companion/core/network/api_client.dart';
import 'package:nurse_companion/core/network/token_store.dart';
import 'package:nurse_companion/data/api_repository.dart';

http.Response json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late MemoryTokenStore tokens;

  setUp(() async {
    tokens = MemoryTokenStore();
    await tokens.write(
      const AuthTokens(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );
  });

  ApiClient client(Future<http.Response> Function(http.Request) handler) =>
      ApiClient(
        baseUrl: 'http://api.test',
        tokens: tokens,
        httpClient: MockClient(handler),
      );

  test('unwraps the success envelope and sends the bearer token', () async {
    String? auth;
    final api = client((req) async {
      auth = req.headers['Authorization'];
      expect(
        req.url.toString(),
        'http://api.test/api/v1/shifts?startDate=2026-10-01',
      );
      return json(200, {
        'success': true,
        'data': {'shifts': []},
      });
    });
    final data = await api.get('/shifts', query: {'startDate': '2026-10-01'});
    expect(data, {'shifts': []});
    expect(auth, 'Bearer old-access');
  });

  test('maps validation errors to field messages', () async {
    final api = client(
      (_) async => json(422, {
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Validation failed',
          'details': [
            {
              'path': 'phone',
              'message': 'Enter a valid Sri Lankan phone number',
            },
          ],
        },
      }),
    );
    await expectLater(
      api.post('/auth/register', body: {}, auth: false),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 422)
            .having(
              (e) => e.fieldErrors['phone'],
              'phone error',
              'Enter a valid Sri Lankan phone number',
            ),
      ),
    );
  });

  test('refreshes once on 401 and retries with the new token', () async {
    var refreshCalls = 0;
    final api = client((req) async {
      if (req.url.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        expect(jsonDecode(req.body), {'refreshToken': 'old-refresh'});
        return json(200, {
          'success': true,
          'data': {
            'tokens': {
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
            },
          },
        });
      }
      return req.headers['Authorization'] == 'Bearer new-access'
          ? json(200, {
              'success': true,
              'data': {'ok': true},
            })
          : json(401, {
              'success': false,
              'error': {'code': 'UNAUTHORIZED', 'message': 'Token expired'},
            });
    });

    // Three parallel requests share a single refresh.
    final results = await Future.wait([
      api.get('/a'),
      api.get('/b'),
      api.get('/c'),
    ]);
    expect(results, everyElement({'ok': true}));
    expect(refreshCalls, 1);
    expect((await tokens.read())!.refreshToken, 'new-refresh');
  });

  test('ends the session when the refresh token is rejected', () async {
    var expired = false;
    final api = client(
      (req) async => json(401, {
        'success': false,
        'error': {'code': 'UNAUTHORIZED', 'message': 'Session expired'},
      }),
    )..onSessionExpired = () => expired = true;

    await expectLater(
      api.get('/auth/me'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.isUnauthorized,
          'unauthorized',
          true,
        ),
      ),
    );
    expect(expired, isTrue);
    expect(await tokens.read(), isNull);
  });

  test('reports network failures in plain language', () async {
    final api = client(
      (_) async => throw http.ClientException('connection refused'),
    );
    await expectLater(
      api.get('/auth/me'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isNetwork, 'network', true)
            .having((e) => e.message, 'msg', contains("Can't reach")),
      ),
    );
  });

  test(
    'falls back to the roster calculator when the plan locks the smart forecast',
    () async {
      final paths = <String>[];
      final api = client((req) async {
        paths.add(req.url.path);
        if (req.url.path.endsWith('/analytics/predict-salary')) {
          return json(402, {
            'success': false,
            'error': {
              'code': 'PLAN_UPGRADE_REQUIRED',
              'message': 'Salary forecast is not included in your Free plan',
            },
          });
        }
        return json(200, {
          'success': true,
          'data': {
            'salaryIsEstimate': true,
            'period': {
              'month': 10,
              'year': 2026,
              'daysInMonth': 31,
              'isPastMonth': false,
              'isFutureMonth': false,
            },
            'earnings': {
              'baseSalary': 55000,
              'allowancesTotal': 0,
              'nightAllowance': {
                'shifts': 2,
                'ratePerShift': 500,
                'amount': 1000,
              },
              'overtime': {
                'completedHours': 4,
                'plannedHours': 2,
                'totalHours': 6,
                'hourlyRate': 343.75,
                'amount': 2062.5,
              },
              'gross': 58062.5,
            },
            'deductions': {
              'configuredTotal': 0,
              'noPay': {'amount': 0},
              'total': 0,
            },
            'netSalary': 58062.5,
            'earnedToDate': {'overtime': 1375, 'nightAllowance': 500},
            'assumptions': [
              'Using a typical basic salary of LKR 55,000 until you add yours.',
            ],
            'warnings': [],
          },
        });
      });
      final f = await ApiRepository(api).forecast(month: 10, year: 2026);
      expect(paths, [
        '/api/v1/analytics/predict-salary',
        '/api/v1/salary/predict',
      ]);
      expect(f.isBasic, isTrue);
      expect(f.salaryIsEstimate, isTrue);
      expect(f.projectedNet, 58062.5);
      expect(f.otTotal, 6);
      expect(f.nightShifts, 2);
      expect(f.rangeLow, f.rangeHigh);
    },
  );

  test('other forecast errors are not masked by the fallback', () async {
    final api = client(
      (_) async => json(500, {
        'success': false,
        'error': {'code': 'INTERNAL_ERROR', 'message': 'boom'},
      }),
    );
    await expectLater(
      ApiRepository(api).forecast(month: 10, year: 2026),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
    );
  });
}
