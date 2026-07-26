enum ProfessionalAppointmentStatus { pending, confirmed, cancelled }

enum ProfessionalAppointmentMode { atProvider, homeVisit, video }

extension ProfessionalAppointmentModeText on ProfessionalAppointmentMode {
  String get storageValue => switch (this) {
    ProfessionalAppointmentMode.atProvider => 'inPerson',
    ProfessionalAppointmentMode.homeVisit => 'homeVisit',
    ProfessionalAppointmentMode.video => 'video',
  };

  String get label => switch (this) {
    ProfessionalAppointmentMode.atProvider => 'Sur place',
    ProfessionalAppointmentMode.homeVisit => 'Visite à domicile',
    ProfessionalAppointmentMode.video => 'Visioconférence',
  };

  static ProfessionalAppointmentMode fromStorage(Object? value) =>
      switch (value) {
        'homeVisit' => ProfessionalAppointmentMode.homeVisit,
        'video' => ProfessionalAppointmentMode.video,
        _ => ProfessionalAppointmentMode.atProvider,
      };
}

extension ProfessionalAppointmentStatusText on ProfessionalAppointmentStatus {
  String get storageValue => switch (this) {
    ProfessionalAppointmentStatus.pending => 'pending',
    ProfessionalAppointmentStatus.confirmed => 'confirmed',
    ProfessionalAppointmentStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    ProfessionalAppointmentStatus.pending => 'En attente',
    ProfessionalAppointmentStatus.confirmed => 'Confirmé',
    ProfessionalAppointmentStatus.cancelled => 'Annulé',
  };

  static ProfessionalAppointmentStatus fromStorage(Object? value) =>
      switch (value) {
        'confirmed' => ProfessionalAppointmentStatus.confirmed,
        'cancelled' => ProfessionalAppointmentStatus.cancelled,
        _ => ProfessionalAppointmentStatus.pending,
      };
}

class ProfessionalAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String providerId;
  final String providerType;
  final String providerName;
  final String service;
  final ProfessionalAppointmentMode mode;
  final String location;
  final DateTime scheduledAt;
  final String scheduleLabel;
  final ProfessionalAppointmentStatus status;
  final String patientNote;
  final String responseNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;

  const ProfessionalAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.providerId,
    required this.providerType,
    required this.providerName,
    required this.service,
    this.mode = ProfessionalAppointmentMode.atProvider,
    this.location = '',
    required this.scheduledAt,
    required this.scheduleLabel,
    required this.status,
    required this.patientNote,
    required this.responseNote,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
  });

  factory ProfessionalAppointment.fromRow(Map<String, dynamic> data) {
    String text(String key) => data[key]?.toString().trim() ?? '';
    DateTime date(String key, [DateTime? fallback]) {
      final value = data[key];
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value)?.toLocal() ??
            fallback ??
            DateTime.now();
      }
      return fallback ?? DateTime.now();
    }

    final createdAt = date('created_at');
    return ProfessionalAppointment(
      id: text('appointment_id'),
      patientId: text('patient_id'),
      patientName: text('patient_name_snapshot'),
      providerId: text('provider_id'),
      providerType: text('provider_type_snapshot'),
      providerName: text('provider_name_snapshot'),
      service: text('service_name_snapshot'),
      mode: ProfessionalAppointmentModeText.fromStorage(data['mode']),
      location: text('location'),
      scheduledAt: date('scheduled_at'),
      scheduleLabel: text('schedule_label'),
      status: ProfessionalAppointmentStatusText.fromStorage(data['status']),
      patientNote: text('patient_note'),
      responseNote: text('response_note'),
      createdAt: createdAt,
      updatedAt: date('updated_at', createdAt),
      respondedAt: data['responded_at'] == null ? null : date('responded_at'),
    );
  }
}
