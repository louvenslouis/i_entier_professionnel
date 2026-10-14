import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vault_crypto.dart';

class ProfessionalVault extends ChangeNotifier with WidgetsBindingObserver {
  ProfessionalVault._(this.client) {
    WidgetsBinding.instance.addObserver(this);
    client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut ||
          event.session?.user.id != _metadata?['provider_id']) {
        close();
      }
    });
  }
  static final _instances = Expando<ProfessionalVault>();
  factory ProfessionalVault(SupabaseClient client) =>
      _instances[client] ??= ProfessionalVault._(client);
  final SupabaseClient client;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      close();
    }
  }

  Uint8List? _key;
  Map<String, dynamic>? _metadata;
  Map<String, dynamic> _snapshot = {};
  final _pending = <String, (String, Map<String, dynamic>)>{};
  final _sent = <Map<String, dynamic>>[];
  Timer? _expiry, _poll;
  int _generation = 0;
  bool _refreshing = false;
  String? get appointmentId => _metadata?['appointment_id'];
  DateTime? get expiresAt => _metadata == null
      ? null
      : DateTime.parse(_metadata!['expires_at']).toLocal();
  bool get active =>
      _key != null && _metadata?['provider_id'] == client.auth.currentUser?.id;
  Map<String, dynamic> get snapshot => active ? _snapshot : const {};
  void close() {
    _generation++;
    _expiry?.cancel();
    _poll?.cancel();
    _key?.fillRange(0, _key!.length, 0);
    _key = null;
    _metadata = null;
    _snapshot = {};
    _pending.clear();
    _sent.clear();
    notifyListeners();
  }

  Future<void> unlock(String code, {String? expectedAppointment}) async {
    close();
    final started = Stopwatch()..start();
    final generation = _generation;
    final userId = client.auth.currentUser?.id;
    final parts = code.replaceAll(RegExp(r'\s'), '').split('.');
    if (parts.length != 3 || parts[0] != 'IEA1' || userId == null) {
      throw const FormatException('Code invalide');
    }
    final key = base64Url.decode(parts[2]);
    if (key.length != 32) throw const FormatException('Code invalide');
    try {
      final meta = Map<String, dynamic>.from(
        await client
            .schema('ientier')
            .rpc('vault_read_grant', params: {'p_grant_id': parts[1]})
            .timeout(const Duration(seconds: 8)),
      );
      if (meta['provider_id'] != userId ||
          (expectedAppointment != null &&
              meta['appointment_id'] != expectedAppointment)) {
        throw const FormatException('Autorisation invalide');
      }
      final data = Map<String, dynamic>.from(
        await VaultCrypto.open(
          Map<String, dynamic>.from(meta['payload']),
          key,
          'grant:${meta['grant_id']}:${meta['patient_id']}:${meta['provider_id']}:${meta['appointment_id']}',
        ),
      );
      if (_generation != generation || client.auth.currentUser?.id != userId) {
        throw const FormatException('Session terminée');
      }
      _key = key;
      _metadata = meta;
      _snapshot = data;
      _armExpiry(meta, started.elapsed);
      if (!active) throw const FormatException('Autorisation expirée');
      _poll = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
      notifyListeners();
    } catch (_) {
      key.fillRange(0, key.length, 0);
      rethrow;
    }
  }

  void _armExpiry(Map<String, dynamic> meta, Duration elapsed) {
    final remaining =
        DateTime.parse(
          meta['expires_at'],
        ).difference(DateTime.parse(meta['server_time'])) -
        elapsed;
    _expiry?.cancel();
    if (remaining <= Duration.zero) {
      close();
      return;
    }
    _expiry = Timer(remaining, close);
  }

  Future<void> _refresh() async {
    if (_refreshing || !active) return;
    _refreshing = true;
    try {
      await revalidate(appointmentId!);
    } catch (_) {
      close();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> revalidate(String appointment) async {
    if (!active || appointmentId != appointment) {
      throw const FormatException('Autorisation du patient requise');
    }
    final started = Stopwatch()..start();
    final generation = _generation;
    try {
      final meta = Map<String, dynamic>.from(
        await client
            .schema('ientier')
            .rpc(
              'vault_read_grant',
              params: {'p_grant_id': _metadata!['grant_id'], 'p_probe': true},
            )
            .timeout(const Duration(seconds: 8)),
      );
      if (generation != _generation || !active) {
        throw const FormatException('Session terminée');
      }
      _armExpiry(meta, started.elapsed);
      if (!active) throw const FormatException('Autorisation expirée');
    } catch (_) {
      if (generation == _generation) close();
      rethrow;
    }
  }

  List<Map<String, dynamic>> records(String table) =>
      (snapshot[table] as List? ?? const [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();

  Future<Map<String, dynamic>?> patientDetails(String appointment) async {
    await revalidate(appointment);
    final profiles = records('patient_profiles');
    if (profiles.isEmpty) return null;
    return {
      ...profiles.first,
      ...?records(
        'appointment_notes',
      ).where((r) => r['appointment_id'] == appointment).firstOrNull,
      'medical_items': records('patient_medical_items')
          .map(
            (r) => {
              'type': r['item_type'],
              'label': r['label'],
              'details': r['details'],
            },
          )
          .toList(),
    };
  }

  Future<List<Map<String, dynamic>>> documents(String appointment) async {
    await revalidate(appointment);
    return [
      ...records(
        'consultation_documents',
      ).where((r) => r['appointment_id'] == appointment),
      ..._sent.where((r) => r['kind'] != 'record'),
    ];
  }

  Future<void> publishRecord({
    required String patientId,
    required String collection,
    required Map<String, dynamic> row,
  }) async {
    if (!active || _metadata!['patient_id'] != patientId) {
      throw const FormatException('Autorisation du patient requise');
    }
    if (![
      'traditional_prevention_recommendations',
      'traditional_care_orientations',
    ].contains(collection)) {
      throw const FormatException('Document invalide');
    }
    await publish(
      appointment: appointmentId!,
      id: VaultCrypto.newId(),
      kind: 'record',
      payload: {'collection': collection, 'row': row},
    );
  }

  Future<Map<String, dynamic>> publish({
    required String appointment,
    required String id,
    required String kind,
    required Map<String, dynamic> payload,
  }) async {
    await revalidate(appointment);
    final generation = _generation;
    final meta = _metadata!;
    final fingerprint = jsonEncode({'kind': kind, 'payload': payload});
    final pending = _pending[id];
    if (pending != null && pending.$1 != fingerprint) {
      throw const FormatException('Envoi déjà préparé');
    }
    final row = {
      'document_id': id,
      'patient_id': meta['patient_id'],
      'provider_id': meta['provider_id'],
      'appointment_id': appointment,
      'kind': kind,
      'payload': payload,
      'patient_name': meta['patient_name'] ?? 'Patient',
      'provider_name': meta['provider_name'] ?? 'Professionnel de santé',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    final sealed =
        pending?.$2 ??
        await VaultCrypto.seal(
          row,
          _key!,
          'document:$id:${meta['grant_id']}:${meta['patient_id']}:${meta['provider_id']}:$appointment',
        );
    if (generation != _generation || !active) {
      throw const FormatException('Session terminée');
    }
    _pending[id] = (fingerprint, sealed);
    await client
        .schema('ientier')
        .rpc(
          'vault_publish',
          params: {
            'p_grant_id': meta['grant_id'],
            'p_document_id': id,
            'p_payload': sealed,
            'p_followup': kind == 'followup'
                ? {
                    'scheduled_at': payload['scheduled_at'],
                    'mode': payload['mode'],
                    'location': payload['location'],
                  }
                : null,
          },
        );
    if (generation != _generation || !active) {
      throw const FormatException('Session terminée');
    }
    _sent.removeWhere((r) => r['document_id'] == id);
    _sent.add(row);
    return row;
  }
}
