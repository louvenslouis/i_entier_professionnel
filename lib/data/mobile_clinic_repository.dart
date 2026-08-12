import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mobile_clinic.dart';
import '../models/provider_profile.dart';

abstract class MobileClinicRepository {
  Stream<List<MobileClinic>> watchClinics(String ownerId);

  Future<void> submitClinic(ProviderProfile owner, MobileClinicDraft draft);

  Future<void> updateClinic(
    ProviderProfile owner,
    MobileClinic clinic,
    MobileClinicDraft draft,
  );

  Future<void> setPublication(
    MobileClinic clinic, {
    required bool published,
    required bool deployed,
  });

  Stream<List<MobileClinicService>> watchServices(String clinicId);

  Stream<List<MobileClinicStaffMember>> watchStaff(String clinicId);

  Stream<List<MobileClinicTour>> watchTours(String clinicId);

  Stream<List<MobileClinicIntervention>> watchInterventions(String clinicId);

  Stream<List<MobileClinicAppointment>> watchAppointments(String clinicId);

  Future<void> addService({
    required String clinicId,
    required String name,
    required String description,
    required int durationMinutes,
    double? priceHtg,
  });

  Future<void> addStaffMember({
    required String clinicId,
    required String fullName,
    required String profession,
    required String licenseNumber,
    required String documentUrl,
  });

  Future<void> addTour({
    required String clinicId,
    required String zoneName,
    required String locationLabel,
    required String department,
    required String commune,
    double? latitude,
    double? longitude,
    required DateTime startsAt,
    required DateTime endsAt,
    required String dailySchedule,
    required String notes,
  });

  Future<void> recordIntervention({
    required String clinicId,
    String? tourId,
    required String serviceName,
    required DateTime interventionAt,
    required int beneficiariesCount,
    required String notes,
    required String createdBy,
  });
}

class SupabaseMobileClinicRepository implements MobileClinicRepository {
  final SupabaseClient client;

  SupabaseMobileClinicRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  @override
  Stream<List<MobileClinic>> watchClinics(String ownerId) => client
      .schema('ientier')
      .from('mobile_clinics')
      .stream(primaryKey: ['mobile_clinic_id'])
      .eq('owner_provider_id', ownerId)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(MobileClinic.fromRow).toList(growable: false));

  @override
  Future<void> submitClinic(
    ProviderProfile owner,
    MobileClinicDraft draft,
  ) async {
    if (!owner.isApproved) {
      throw StateError('Le profil doit être validé avant la demande.');
    }
    if (draft.creatorType.isProfessional !=
        (owner.accountType == ProviderAccountType.professional)) {
      throw StateError('Le type de créateur ne correspond pas au profil.');
    }
    await client
        .schema('ientier')
        .from('mobile_clinics')
        .insert(draft.toRow(owner.ownerUid, owner.accountType.storageValue));
  }

  @override
  Future<void> updateClinic(
    ProviderProfile owner,
    MobileClinic clinic,
    MobileClinicDraft draft,
  ) => client
      .schema('ientier')
      .from('mobile_clinics')
      .update(draft.toRow(owner.ownerUid, owner.accountType.storageValue))
      .eq('mobile_clinic_id', clinic.id);

  @override
  Future<void> setPublication(
    MobileClinic clinic, {
    required bool published,
    required bool deployed,
  }) async {
    if (!clinic.isApproved && (published || deployed)) {
      throw StateError('La clinique doit être certifiée.');
    }
    await client
        .schema('ientier')
        .from('mobile_clinics')
        .update({'is_published': published, 'is_deployed': deployed})
        .eq('mobile_clinic_id', clinic.id);
  }

  @override
  Stream<List<MobileClinicService>> watchServices(String clinicId) => client
      .schema('ientier')
      .from('mobile_clinic_services')
      .stream(primaryKey: ['mobile_clinic_service_id'])
      .eq('mobile_clinic_id', clinicId)
      .order('name')
      .map(
        (rows) => rows.map(MobileClinicService.fromRow).toList(growable: false),
      );

  @override
  Stream<List<MobileClinicStaffMember>> watchStaff(String clinicId) => client
      .schema('ientier')
      .from('mobile_clinic_staff')
      .stream(primaryKey: ['mobile_clinic_staff_id'])
      .eq('mobile_clinic_id', clinicId)
      .order('full_name')
      .map(
        (rows) =>
            rows.map(MobileClinicStaffMember.fromRow).toList(growable: false),
      );

  @override
  Stream<List<MobileClinicTour>> watchTours(String clinicId) => client
      .schema('ientier')
      .from('mobile_clinic_tours')
      .stream(primaryKey: ['mobile_clinic_tour_id'])
      .eq('mobile_clinic_id', clinicId)
      .order('starts_at', ascending: false)
      .map(
        (rows) => rows.map(MobileClinicTour.fromRow).toList(growable: false),
      );

  @override
  Stream<List<MobileClinicIntervention>> watchInterventions(String clinicId) =>
      client
          .schema('ientier')
          .from('mobile_clinic_interventions')
          .stream(primaryKey: ['mobile_clinic_intervention_id'])
          .eq('mobile_clinic_id', clinicId)
          .order('intervention_at', ascending: false)
          .map(
            (rows) => rows
                .map(MobileClinicIntervention.fromRow)
                .toList(growable: false),
          );

  @override
  Stream<List<MobileClinicAppointment>> watchAppointments(String clinicId) =>
      client
          .schema('ientier')
          .from('appointments')
          .stream(primaryKey: ['appointment_id'])
          .eq('mobile_clinic_id', clinicId)
          .order('scheduled_at', ascending: false)
          .map(
            (rows) => rows
                .map(MobileClinicAppointment.fromRow)
                .toList(growable: false),
          );

  @override
  Future<void> addService({
    required String clinicId,
    required String name,
    required String description,
    required int durationMinutes,
    double? priceHtg,
  }) => client.schema('ientier').from('mobile_clinic_services').insert({
    'mobile_clinic_id': clinicId,
    'name': name.trim(),
    'description': description.trim(),
    'duration_minutes': durationMinutes,
    'price_htg': priceHtg,
  });

  @override
  Future<void> addStaffMember({
    required String clinicId,
    required String fullName,
    required String profession,
    required String licenseNumber,
    required String documentUrl,
  }) => client.schema('ientier').from('mobile_clinic_staff').insert({
    'mobile_clinic_id': clinicId,
    'full_name': fullName.trim(),
    'profession': profession.trim(),
    'license_number': licenseNumber.trim(),
    'document_url': documentUrl.trim(),
  });

  @override
  Future<void> addTour({
    required String clinicId,
    required String zoneName,
    required String locationLabel,
    required String department,
    required String commune,
    double? latitude,
    double? longitude,
    required DateTime startsAt,
    required DateTime endsAt,
    required String dailySchedule,
    required String notes,
  }) => client.schema('ientier').from('mobile_clinic_tours').insert({
    'mobile_clinic_id': clinicId,
    'zone_name': zoneName.trim(),
    'location_label': locationLabel.trim(),
    'department': department.trim(),
    'commune': commune.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt.toUtc().toIso8601String(),
    'daily_schedule': dailySchedule.trim(),
    'notes': notes.trim(),
  });

  @override
  Future<void> recordIntervention({
    required String clinicId,
    String? tourId,
    required String serviceName,
    required DateTime interventionAt,
    required int beneficiariesCount,
    required String notes,
    required String createdBy,
  }) => client.schema('ientier').from('mobile_clinic_interventions').insert({
    'mobile_clinic_id': clinicId,
    'mobile_clinic_tour_id': tourId,
    'service_name': serviceName.trim(),
    'intervention_at': interventionAt.toUtc().toIso8601String(),
    'beneficiaries_count': beneficiariesCount,
    'notes': notes.trim(),
    'created_by': createdBy,
  });
}
