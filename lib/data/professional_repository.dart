import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/health_institution.dart';
import '../models/provider_profile.dart';

abstract class ProfessionalRepository {
  Stream<ProviderProfile?> watchProfile(String uid);

  Stream<List<HealthInstitution>> watchInstitutions();

  Future<void> submitProfile(ProviderProfile profile);

  Future<void> updateProfile(ProviderProfile profile);

  Future<void> setVisibility(ProviderProfile profile, bool isVisible);

  Future<void> setAvailability(ProviderProfile profile, bool available);

  Future<void> linkInstitution(
    ProviderProfile profile,
    HealthInstitution institution,
  );

  Future<void> unlinkInstitution(ProviderProfile profile);
}

class SupabaseProfessionalRepository implements ProfessionalRepository {
  final SupabaseClient client;

  SupabaseProfessionalRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  @override
  Stream<ProviderProfile?> watchProfile(String uid) => client
      .schema('ientier')
      .from('provider_profiles')
      .stream(primaryKey: ['provider_id'])
      .eq('provider_id', uid)
      .map((rows) => rows.isEmpty ? null : ProviderProfile.fromRow(rows.first));

  @override
  Stream<List<HealthInstitution>> watchInstitutions() => client
      .schema('ientier')
      .from('provider_profiles')
      .stream(primaryKey: ['provider_id'])
      .eq('account_type', 'institution')
      .order('display_name')
      .map(
        (rows) => rows
            .where(
              (row) =>
                  row['verification_status'] == 'approved' &&
                  row['is_visible'] == true,
            )
            .map(HealthInstitution.fromRow)
            .where((institution) => institution.name.isNotEmpty)
            .toList(growable: false),
      );

  @override
  Future<void> submitProfile(ProviderProfile profile) async {
    await client
        .schema('ientier')
        .from('provider_profiles')
        .insert(profile.toCreateMap());
  }

  @override
  Future<void> updateProfile(ProviderProfile profile) async {
    await client
        .schema('ientier')
        .from('provider_profiles')
        .update(profile.toEditableMap())
        .eq('provider_id', profile.ownerUid);
  }

  @override
  Future<void> setVisibility(ProviderProfile profile, bool isVisible) async {
    if (!profile.isApproved) {
      throw StateError('Le profil doit être validé avant sa publication.');
    }
    await client
        .schema('ientier')
        .from('provider_profiles')
        .update({
          'is_visible': isVisible,
          'linked_institution_id': profile.linkedInstitutionId.trim().isEmpty
              ? null
              : profile.linkedInstitutionId.trim(),
          'linked_institution_name_snapshot': profile.linkedInstitutionName
              .trim(),
        })
        .eq('provider_id', profile.ownerUid);
  }

  @override
  Future<void> setAvailability(ProviderProfile profile, bool available) async {
    await client
        .schema('ientier')
        .from('provider_profiles')
        .update({
          'available': available,
          'linked_institution_id': profile.linkedInstitutionId.trim().isEmpty
              ? null
              : profile.linkedInstitutionId.trim(),
          'linked_institution_name_snapshot': profile.linkedInstitutionName
              .trim(),
        })
        .eq('provider_id', profile.ownerUid);
  }

  @override
  Future<void> linkInstitution(
    ProviderProfile profile,
    HealthInstitution institution,
  ) async {
    if (profile.accountType != ProviderAccountType.professional) {
      throw StateError(
        'Seul un personnel de santé peut être lié à une institution.',
      );
    }
    final row = await client
        .schema('ientier')
        .from('provider_profiles')
        .select()
        .eq('provider_id', institution.id)
        .eq('account_type', 'institution')
        .eq('verification_status', 'approved')
        .eq('is_visible', true)
        .maybeSingle();
    if (row == null) {
      throw StateError('Cette institution n’existe plus.');
    }
    final verifiedInstitution = HealthInstitution.fromRow(row);
    if (verifiedInstitution.name.isEmpty) {
      throw StateError('Cette institution ne peut pas être liée.');
    }
    await _saveInstitutionLink(
      profile.ownerUid,
      verifiedInstitution.id,
      verifiedInstitution.name,
    );
  }

  @override
  Future<void> unlinkInstitution(ProviderProfile profile) =>
      _saveInstitutionLink(profile.ownerUid, null, '');

  Future<void> _saveInstitutionLink(
    String providerId,
    String? institutionId,
    String institutionName,
  ) async {
    await client
        .schema('ientier')
        .from('provider_profiles')
        .update({
          'linked_institution_id': institutionId,
          'linked_institution_name_snapshot': institutionName,
        })
        .eq('provider_id', providerId);
  }
}
