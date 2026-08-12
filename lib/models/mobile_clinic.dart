enum MobileClinicCreatorType {
  doctor,
  nurse,
  midwife,
  dentist,
  otherCertifiedProfessional,
  hospital,
  privateClinic,
  healthCenter,
  ngo,
  publicHealthInstitution,
  company,
}

extension MobileClinicCreatorTypeText on MobileClinicCreatorType {
  String get storageValue => switch (this) {
    MobileClinicCreatorType.doctor => 'doctor',
    MobileClinicCreatorType.nurse => 'nurse',
    MobileClinicCreatorType.midwife => 'midwife',
    MobileClinicCreatorType.dentist => 'dentist',
    MobileClinicCreatorType.otherCertifiedProfessional =>
      'other_certified_professional',
    MobileClinicCreatorType.hospital => 'hospital',
    MobileClinicCreatorType.privateClinic => 'private_clinic',
    MobileClinicCreatorType.healthCenter => 'health_center',
    MobileClinicCreatorType.ngo => 'ngo',
    MobileClinicCreatorType.publicHealthInstitution =>
      'public_health_institution',
    MobileClinicCreatorType.company => 'company',
  };

  String get label => switch (this) {
    MobileClinicCreatorType.doctor => 'Médecin',
    MobileClinicCreatorType.nurse => 'Infirmier(ère)',
    MobileClinicCreatorType.midwife => 'Sage-femme',
    MobileClinicCreatorType.dentist => 'Dentiste',
    MobileClinicCreatorType.otherCertifiedProfessional =>
      'Autre professionnel certifié',
    MobileClinicCreatorType.hospital => 'Hôpital',
    MobileClinicCreatorType.privateClinic => 'Clinique privée',
    MobileClinicCreatorType.healthCenter => 'Centre de santé',
    MobileClinicCreatorType.ngo => 'ONG / organisation humanitaire',
    MobileClinicCreatorType.publicHealthInstitution =>
      'Institution publique de santé',
    MobileClinicCreatorType.company => 'Entreprise / campagne médicale',
  };

  bool get isProfessional => index <= 4;

  static MobileClinicCreatorType fromStorage(String? value) =>
      MobileClinicCreatorType.values.firstWhere(
        (item) => item.storageValue == value,
        orElse: () => MobileClinicCreatorType.otherCertifiedProfessional,
      );
}

enum MobileClinicStatus { pending, approved, rejected }

extension MobileClinicStatusText on MobileClinicStatus {
  String get label => switch (this) {
    MobileClinicStatus.pending => 'Vérification administrative',
    MobileClinicStatus.approved => 'Clinique certifiée',
    MobileClinicStatus.rejected => 'Corrections requises',
  };

  static MobileClinicStatus fromStorage(String? value) => switch (value) {
    'approved' => MobileClinicStatus.approved,
    'rejected' => MobileClinicStatus.rejected,
    _ => MobileClinicStatus.pending,
  };
}

class MobileClinicDraft {
  final MobileClinicCreatorType creatorType;
  final String name;
  final String responsibleName;
  final String phone;
  final String email;
  final String description;
  final String baseAddress;
  final String department;
  final String commune;
  final double? latitude;
  final double? longitude;
  final String identityDocumentUrl;
  final String professionalLicenseUrl;
  final String operatingAuthorizationUrl;
  final List<String> partnerDocumentUrls;

  const MobileClinicDraft({
    required this.creatorType,
    required this.name,
    required this.responsibleName,
    required this.phone,
    required this.email,
    required this.description,
    required this.baseAddress,
    required this.department,
    required this.commune,
    this.latitude,
    this.longitude,
    required this.identityDocumentUrl,
    required this.professionalLicenseUrl,
    required this.operatingAuthorizationUrl,
    this.partnerDocumentUrls = const [],
  });

  Map<String, dynamic> toRow(String ownerId, String accountType) => {
    'owner_provider_id': ownerId,
    'owner_account_type': accountType,
    'creator_type': creatorType.storageValue,
    'name': name.trim(),
    'responsible_name': responsibleName.trim(),
    'phone': phone.trim(),
    'email': email.trim().isEmpty ? null : email.trim(),
    'description': description.trim(),
    'base_address': baseAddress.trim(),
    'department': department.trim(),
    'commune': commune.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'identity_document_url': identityDocumentUrl.trim(),
    'professional_license_url': professionalLicenseUrl.trim(),
    'operating_authorization_url': operatingAuthorizationUrl.trim(),
    'partner_document_urls': partnerDocumentUrls,
  };
}

class MobileClinic {
  final String id;
  final String ownerId;
  final MobileClinicCreatorType creatorType;
  final String name;
  final String responsibleName;
  final String phone;
  final String email;
  final String description;
  final String baseAddress;
  final String department;
  final String commune;
  final double? latitude;
  final double? longitude;
  final String identityDocumentUrl;
  final String professionalLicenseUrl;
  final String operatingAuthorizationUrl;
  final List<String> partnerDocumentUrls;
  final MobileClinicStatus status;
  final String rejectionReason;
  final String badge;
  final bool isPublished;
  final bool isDeployed;
  final DateTime? certifiedAt;

  const MobileClinic({
    required this.id,
    required this.ownerId,
    required this.creatorType,
    required this.name,
    required this.responsibleName,
    required this.phone,
    required this.email,
    required this.description,
    required this.baseAddress,
    required this.department,
    required this.commune,
    required this.latitude,
    required this.longitude,
    required this.identityDocumentUrl,
    required this.professionalLicenseUrl,
    required this.operatingAuthorizationUrl,
    required this.partnerDocumentUrls,
    required this.status,
    required this.rejectionReason,
    required this.badge,
    required this.isPublished,
    required this.isDeployed,
    this.certifiedAt,
  });

  bool get isApproved => status == MobileClinicStatus.approved;

  String get area => '$commune, $department';

  MobileClinicDraft toDraft() => MobileClinicDraft(
    creatorType: creatorType,
    name: name,
    responsibleName: responsibleName,
    phone: phone,
    email: email,
    description: description,
    baseAddress: baseAddress,
    department: department,
    commune: commune,
    latitude: latitude,
    longitude: longitude,
    identityDocumentUrl: identityDocumentUrl,
    professionalLicenseUrl: professionalLicenseUrl,
    operatingAuthorizationUrl: operatingAuthorizationUrl,
    partnerDocumentUrls: partnerDocumentUrls,
  );

  factory MobileClinic.fromRow(Map<String, dynamic> row) => MobileClinic(
    id: _text(row, 'mobile_clinic_id'),
    ownerId: _text(row, 'owner_provider_id'),
    creatorType: MobileClinicCreatorTypeText.fromStorage(
      _text(row, 'creator_type'),
    ),
    name: _text(row, 'name'),
    responsibleName: _text(row, 'responsible_name'),
    phone: _text(row, 'phone'),
    email: _text(row, 'email'),
    description: _text(row, 'description'),
    baseAddress: _text(row, 'base_address'),
    department: _text(row, 'department'),
    commune: _text(row, 'commune'),
    latitude: _number(row['latitude']),
    longitude: _number(row['longitude']),
    identityDocumentUrl: _text(row, 'identity_document_url'),
    professionalLicenseUrl: _text(row, 'professional_license_url'),
    operatingAuthorizationUrl: _text(row, 'operating_authorization_url'),
    partnerDocumentUrls: row['partner_document_urls'] is List
        ? List<String>.from(row['partner_document_urls'] as List)
        : const [],
    status: MobileClinicStatusText.fromStorage(
      _text(row, 'verification_status'),
    ),
    rejectionReason: _text(row, 'rejection_reason'),
    badge: _text(row, 'certification_badge'),
    isPublished: row['is_published'] == true,
    isDeployed: row['is_deployed'] == true,
    certifiedAt: _nullableDate(row['certified_at']),
  );
}

class MobileClinicService {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double? priceHtg;
  final bool active;

  const MobileClinicService({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.priceHtg,
    required this.active,
  });

  factory MobileClinicService.fromRow(Map<String, dynamic> row) =>
      MobileClinicService(
        id: _text(row, 'mobile_clinic_service_id'),
        name: _text(row, 'name'),
        description: _text(row, 'description'),
        durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 30,
        priceHtg: _number(row['price_htg']),
        active: row['active'] != false,
      );
}

class MobileClinicStaffMember {
  final String id;
  final String fullName;
  final String profession;
  final String licenseNumber;
  final String documentUrl;
  final bool active;

  const MobileClinicStaffMember({
    required this.id,
    required this.fullName,
    required this.profession,
    required this.licenseNumber,
    required this.documentUrl,
    required this.active,
  });

  factory MobileClinicStaffMember.fromRow(Map<String, dynamic> row) =>
      MobileClinicStaffMember(
        id: _text(row, 'mobile_clinic_staff_id'),
        fullName: _text(row, 'full_name'),
        profession: _text(row, 'profession'),
        licenseNumber: _text(row, 'license_number'),
        documentUrl: _text(row, 'document_url'),
        active: row['active'] != false,
      );
}

class MobileClinicTour {
  final String id;
  final String zoneName;
  final String locationLabel;
  final String department;
  final String commune;
  final double? latitude;
  final double? longitude;
  final DateTime startsAt;
  final DateTime endsAt;
  final String dailySchedule;
  final String status;
  final String notes;

  const MobileClinicTour({
    required this.id,
    required this.zoneName,
    required this.locationLabel,
    required this.department,
    required this.commune,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.endsAt,
    required this.dailySchedule,
    required this.status,
    required this.notes,
  });

  factory MobileClinicTour.fromRow(Map<String, dynamic> row) =>
      MobileClinicTour(
        id: _text(row, 'mobile_clinic_tour_id'),
        zoneName: _text(row, 'zone_name'),
        locationLabel: _text(row, 'location_label'),
        department: _text(row, 'department'),
        commune: _text(row, 'commune'),
        latitude: _number(row['latitude']),
        longitude: _number(row['longitude']),
        startsAt: _date(row['starts_at']),
        endsAt: _date(row['ends_at']),
        dailySchedule: _text(row, 'daily_schedule'),
        status: _text(row, 'status'),
        notes: _text(row, 'notes'),
      );
}

class MobileClinicIntervention {
  final String id;
  final String serviceName;
  final DateTime interventionAt;
  final int beneficiariesCount;
  final String notes;

  const MobileClinicIntervention({
    required this.id,
    required this.serviceName,
    required this.interventionAt,
    required this.beneficiariesCount,
    required this.notes,
  });

  factory MobileClinicIntervention.fromRow(Map<String, dynamic> row) =>
      MobileClinicIntervention(
        id: _text(row, 'mobile_clinic_intervention_id'),
        serviceName: _text(row, 'service_name'),
        interventionAt: _date(row['intervention_at']),
        beneficiariesCount: (row['beneficiaries_count'] as num?)?.toInt() ?? 1,
        notes: _text(row, 'notes'),
      );
}

class MobileClinicAppointment {
  final String id;
  final String patientName;
  final String serviceName;
  final DateTime scheduledAt;
  final String status;
  final String location;

  const MobileClinicAppointment({
    required this.id,
    required this.patientName,
    required this.serviceName,
    required this.scheduledAt,
    required this.status,
    required this.location,
  });

  factory MobileClinicAppointment.fromRow(Map<String, dynamic> row) =>
      MobileClinicAppointment(
        id: _text(row, 'appointment_id'),
        patientName: _text(row, 'patient_name_snapshot'),
        serviceName: _text(row, 'service_name_snapshot'),
        scheduledAt: _date(row['scheduled_at']),
        status: _text(row, 'status'),
        location: _text(row, 'location'),
      );
}

String _text(Map<String, dynamic> row, String key) =>
    row[key]?.toString().trim() ?? '';

double? _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

DateTime _date(Object? value) =>
    _nullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

DateTime? _nullableDate(Object? value) {
  if (value is DateTime) return value.toLocal();
  return DateTime.tryParse(value?.toString() ?? '')?.toLocal();
}
