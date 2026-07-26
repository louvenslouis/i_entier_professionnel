import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment_request.dart';

abstract class ProfessionalAppointmentRepository {
  Stream<List<ProfessionalAppointment>> watchForProvider(String providerId);

  Future<void> respond({
    required ProfessionalAppointment appointment,
    required ProfessionalAppointmentStatus status,
    required String responseNote,
  });
}

class SupabaseProfessionalAppointmentRepository
    implements ProfessionalAppointmentRepository {
  final SupabaseClient client;

  SupabaseProfessionalAppointmentRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  @override
  Stream<List<ProfessionalAppointment>> watchForProvider(String providerId) =>
      client
          .schema('ientier')
          .from('appointments')
          .stream(primaryKey: ['appointment_id'])
          .eq('provider_id', providerId)
          .order('scheduled_at')
          .map(
            (rows) => rows
                .map(ProfessionalAppointment.fromRow)
                .toList(growable: false),
          );

  @override
  Future<void> respond({
    required ProfessionalAppointment appointment,
    required ProfessionalAppointmentStatus status,
    required String responseNote,
  }) async {
    if (status == ProfessionalAppointmentStatus.pending) return;
    await client
        .schema('ientier')
        .rpc(
          'respond_to_appointment',
          params: {
            'p_appointment_id': appointment.id,
            'p_provider_id': appointment.providerId,
            'p_new_status': status.storageValue,
            'p_response_note': responseNote.trim(),
          },
        );
  }
}
