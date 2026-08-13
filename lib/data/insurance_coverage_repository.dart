import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/insurance_coverage_review.dart';
import '../supabase_config.dart';

abstract class InsuranceCoverageProfessionalRepository {
  Stream<List<InsuranceCoverageReview>> watchCoverages();

  Future<String> createCardUrl(String storagePath);

  Future<void> reviewCoverage({
    required String coverageId,
    required bool approve,
    required String reason,
    DateTime? validUntil,
  });
}

class SupabaseInsuranceCoverageProfessionalRepository
    implements InsuranceCoverageProfessionalRepository {
  final SupabaseClient client;

  SupabaseInsuranceCoverageProfessionalRepository({SupabaseClient? client})
    : client = client ?? SupabaseConfig.client;

  @override
  Stream<List<InsuranceCoverageReview>> watchCoverages() => client
      .schema('ientier')
      .from('medical_insurance_coverages')
      .stream(primaryKey: ['coverage_id'])
      .order('submitted_at')
      .map(
        (rows) =>
            rows.map(InsuranceCoverageReview.fromRow).toList(growable: false),
      );

  @override
  Future<String> createCardUrl(String storagePath) =>
      client.storage.from('insurance-cards').createSignedUrl(storagePath, 600);

  @override
  Future<void> reviewCoverage({
    required String coverageId,
    required bool approve,
    required String reason,
    DateTime? validUntil,
  }) => client
      .schema('ientier')
      .rpc(
        'review_medical_insurance_coverage',
        params: {
          'p_coverage_id': coverageId,
          'p_approve': approve,
          'p_reason': reason,
          'p_valid_until': validUntil == null
              ? null
              : '${validUntil.year.toString().padLeft(4, '0')}-${validUntil.month.toString().padLeft(2, '0')}-${validUntil.day.toString().padLeft(2, '0')}',
        },
      );
}
