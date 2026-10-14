import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:i_entier_professionnel/privacy/professional_vault.dart';
import 'package:i_entier_professionnel/privacy/vault_crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'grant opens only for its appointment; revocation clears plaintext and key',
    () async {
      const patient = '10000000-0000-4000-8000-000000000001',
          provider = '20000000-0000-4000-8000-000000000001';
      final key = VaultCrypto.randomBytes(32), id = VaultCrypto.newId();
      final payload = await VaultCrypto.seal(
        {
          'patient_profiles': [
            {'patient_id': patient, 'blood_type': 'CONFIDENTIAL'},
          ],
        },
        key,
        'grant:$id:$patient:$provider:visit',
      );
      var revoked = false, expired = false;
      final requests = <http.Request>[];
      Map<String, dynamic>? published;
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          requests.add(r);
          http.Response respond(Object? body, [int status = 200]) =>
              http.Response(
                jsonEncode(body),
                status,
                headers: {'content-type': 'application/json'},
                request: r,
              );
          if (r.url.path == '/auth/v1/token') {
            final jwt =
                '${base64UrlEncode(utf8.encode('{"alg":"HS256"}'))}.${base64UrlEncode(utf8.encode(jsonEncode({'sub': provider, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})))}.test';
            return respond({
              'access_token': jwt,
              'refresh_token': 'refresh',
              'expires_in': 3600,
              'token_type': 'bearer',
              'user': {
                'id': provider,
                'aud': 'authenticated',
                'role': 'authenticated',
                'created_at': '2026-01-01T00:00:00Z',
                'app_metadata': {},
                'user_metadata': {},
              },
            });
          }
          if (r.url.path.endsWith('/vault_read_grant')) {
            if (revoked) {
              return respond({'message': 'not_allowed', 'code': '42501'}, 403);
            }
            return respond({
              'grant_id': id,
              'patient_id': patient,
              'provider_id': provider,
              'appointment_id': 'visit',
              'payload': payload,
              'server_time': DateTime.now().toUtc().toIso8601String(),
              'expires_at': DateTime.now()
                  .add(Duration(minutes: expired ? -1 : 30))
                  .toUtc()
                  .toIso8601String(),
            });
          }
          if (r.url.path.endsWith('/vault_publish')) {
            published = Map<String, dynamic>.from(jsonDecode(r.body));
            return http.Response('', 204, request: r);
          }
          throw StateError('Unexpected endpoint');
        }),
      );
      await client.auth.signInWithPassword(
        email: 'doctor@example.test',
        password: 'test',
      );
      final vault = ProfessionalVault(client);
      addTearDown(() async {
        vault.close();
        await client.dispose();
      });
      final code = 'IEA1.$id.${base64UrlEncode(key)}';
      await expectLater(
        vault.unlock(code, expectedAppointment: 'another-visit'),
        throwsFormatException,
      );
      expect(vault.active, false);
      await vault.unlock(code, expectedAppointment: 'visit');
      expect(
        vault.records('patient_profiles').single['blood_type'],
        'CONFIDENTIAL',
      );
      final doc = VaultCrypto.newId();
      await vault.publish(
        appointment: 'visit',
        id: doc,
        kind: 'diagnosis',
        payload: {'diagnosis': 'PRIVATE-DIAGNOSIS'},
      );
      expect(
        await VaultCrypto.open(
          Map<String, dynamic>.from(published!['p_payload']),
          key,
          'document:$doc:$id:$patient:$provider:visit',
        ),
        containsPair('kind', 'diagnosis'),
      );
      for (final r in requests.where((r) => r.url.path.startsWith('/rest/'))) {
        expect(r.body, isNot(contains('CONFIDENTIAL')));
        expect(r.body, isNot(contains('PRIVATE-DIAGNOSIS')));
        expect(r.body, isNot(contains(base64UrlEncode(key))));
      }
      revoked = true;
      await expectLater(vault.revalidate('visit'), throwsA(anything));
      expect(vault.active, false);
      expect(vault.snapshot, isEmpty);
      revoked = false;
      expired = true;
      await expectLater(
        vault.unlock(code, expectedAppointment: 'visit'),
        throwsFormatException,
      );
      expect(vault.active, false);
      await expectLater(
        vault.publish(
          appointment: 'visit',
          id: VaultCrypto.newId(),
          kind: 'diagnosis',
          payload: {},
        ),
        throwsFormatException,
      );
    },
  );
}
