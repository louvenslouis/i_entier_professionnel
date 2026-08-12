import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/traditional_medicine.dart';
import '../supabase_config.dart';

abstract class TraditionalMedicineProfessionalRepository {
  Stream<TraditionalPractitionerApplication?> watchApplication(
    String providerId,
  );
  Stream<List<TraditionalPractitionerDocument>> watchDocuments(
    String providerId,
  );
  Stream<List<TraditionalCarePatient>> watchCarePatients(String providerId);

  Future<void> submitApplication({
    required String providerId,
    required int experienceYears,
    required List<String> practiceDomains,
    required List<String> languages,
    required List<String> interventionZones,
  });

  Future<void> uploadDocument({
    required String providerId,
    required String documentType,
    required PickedTraditionalDocument document,
  });

  Future<void> setOnlineAvailability(String providerId, bool available);

  Future<void> sendPreventionRecommendation({
    required String providerId,
    required String patientId,
    required String type,
    required String title,
    required String content,
    DateTime? reminderAt,
  });

  Future<void> createOrientation({
    required String providerId,
    required String patientId,
    required String targetType,
    required String targetName,
    required String reason,
    required String urgency,
  });
}

class SupabaseTraditionalMedicineProfessionalRepository
    implements TraditionalMedicineProfessionalRepository {
  final SupabaseClient client;

  SupabaseTraditionalMedicineProfessionalRepository({SupabaseClient? client})
    : client = client ?? SupabaseConfig.client;

  @override
  Stream<TraditionalPractitionerApplication?> watchApplication(
    String providerId,
  ) => client
      .schema('ientier')
      .from('traditional_practitioner_profiles')
      .stream(primaryKey: ['provider_id'])
      .eq('provider_id', providerId)
      .map(
        (rows) => rows.isEmpty
            ? null
            : TraditionalPractitionerApplication.fromRow(rows.first),
      );

  @override
  Stream<List<TraditionalPractitionerDocument>> watchDocuments(
    String providerId,
  ) => client
      .schema('ientier')
      .from('traditional_practitioner_documents')
      .stream(primaryKey: ['document_id'])
      .eq('provider_id', providerId)
      .order('created_at', ascending: false)
      .map(
        (rows) => rows
            .map(TraditionalPractitionerDocument.fromRow)
            .toList(growable: false),
      );

  @override
  Stream<List<TraditionalCarePatient>> watchCarePatients(String providerId) =>
      client
          .schema('ientier')
          .from('appointments')
          .stream(primaryKey: ['appointment_id'])
          .eq('provider_id', providerId)
          .map((rows) {
            final patients = <String, TraditionalCarePatient>{};
            for (final row in rows) {
              final id = row['patient_id']?.toString() ?? '';
              if (id.isEmpty) continue;
              patients[id] = TraditionalCarePatient(
                id: id,
                name: row['patient_name_snapshot']?.toString() ?? 'Patient',
              );
            }
            final result = patients.values.toList(growable: false);
            result.sort((a, b) => a.name.compareTo(b.name));
            return result;
          });

  @override
  Future<void> submitApplication({
    required String providerId,
    required int experienceYears,
    required List<String> practiceDomains,
    required List<String> languages,
    required List<String> interventionZones,
  }) => client
      .schema('ientier')
      .from('traditional_practitioner_profiles')
      .upsert({
        'provider_id': providerId,
        'experience_years': experienceYears,
        'practice_domains': practiceDomains,
        'languages': languages,
        'intervention_zones': interventionZones,
      }, onConflict: 'provider_id');

  @override
  Future<void> uploadDocument({
    required String providerId,
    required String documentType,
    required PickedTraditionalDocument document,
  }) async {
    final safeName = document.fileName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    final path =
        '$providerId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await client.storage
        .from('traditional-practitioner-documents')
        .uploadBinary(
          path,
          document.bytes,
          fileOptions: FileOptions(contentType: document.mimeType),
        );
    try {
      await client
          .schema('ientier')
          .from('traditional_practitioner_documents')
          .insert({
            'provider_id': providerId,
            'document_type': documentType,
            'original_file_name': document.fileName,
            'storage_path': path,
            'mime_type': document.mimeType,
          });
    } catch (_) {
      await client.storage.from('traditional-practitioner-documents').remove([
        path,
      ]);
      rethrow;
    }
  }

  @override
  Future<void> setOnlineAvailability(String providerId, bool available) =>
      client
          .schema('ientier')
          .from('traditional_practitioner_profiles')
          .update({'online_available': available})
          .eq('provider_id', providerId);

  @override
  Future<void> sendPreventionRecommendation({
    required String providerId,
    required String patientId,
    required String type,
    required String title,
    required String content,
    DateTime? reminderAt,
  }) => client
      .schema('ientier')
      .from('traditional_prevention_recommendations')
      .insert({
        'patient_id': patientId,
        'practitioner_id': providerId,
        'recommendation_type': type,
        'title': title,
        'content': content,
        'reminder_at': reminderAt?.toUtc().toIso8601String(),
        'clinical_scope_acknowledged': true,
      });

  @override
  Future<void> createOrientation({
    required String providerId,
    required String patientId,
    required String targetType,
    required String targetName,
    required String reason,
    required String urgency,
  }) => client.schema('ientier').from('traditional_care_orientations').insert({
    'patient_id': patientId,
    'practitioner_id': providerId,
    'target_type': targetType,
    'target_name': targetName,
    'reason': reason,
    'urgency': urgency,
  });
}
