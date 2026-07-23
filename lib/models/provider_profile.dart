import 'package:cloud_firestore/cloud_firestore.dart';

enum ProviderAccountType { professional, institution }

extension ProviderAccountTypeText on ProviderAccountType {
  String get storageValue => switch (this) {
    ProviderAccountType.professional => 'professional',
    ProviderAccountType.institution => 'institution',
  };

  String get label => switch (this) {
    ProviderAccountType.professional => 'Personnel de santé',
    ProviderAccountType.institution => 'Institution de santé',
  };

  static ProviderAccountType fromStorage(String? value) =>
      value == 'institution'
      ? ProviderAccountType.institution
      : ProviderAccountType.professional;
}

enum ProviderVerificationStatus { pending, approved, rejected }

extension ProviderVerificationStatusText on ProviderVerificationStatus {
  String get storageValue => switch (this) {
    ProviderVerificationStatus.pending => 'pending',
    ProviderVerificationStatus.approved => 'approved',
    ProviderVerificationStatus.rejected => 'rejected',
  };

  String get label => switch (this) {
    ProviderVerificationStatus.pending => 'Validation en cours',
    ProviderVerificationStatus.approved => 'Profil vérifié',
    ProviderVerificationStatus.rejected => 'Informations à corriger',
  };

  static ProviderVerificationStatus fromStorage(String? value) =>
      switch (value) {
        'approved' => ProviderVerificationStatus.approved,
        'rejected' => ProviderVerificationStatus.rejected,
        _ => ProviderVerificationStatus.pending,
      };
}

class ProviderProfile {
  final String ownerUid;
  final ProviderAccountType accountType;
  final String displayName;
  final String category;
  final String registrationNumber;
  final String contactPerson;
  final String workplace;
  final String linkedInstitutionId;
  final String linkedInstitutionName;
  final String phone;
  final String email;
  final String address;
  final String description;
  final String experience;
  final String qualifications;
  final String services;
  final String schedule;
  final bool available;
  final bool isVisible;
  final ProviderVerificationStatus verificationStatus;
  final String rejectionReason;
  final bool termsAccepted;

  const ProviderProfile({
    required this.ownerUid,
    required this.accountType,
    required this.displayName,
    required this.category,
    required this.registrationNumber,
    required this.contactPerson,
    required this.workplace,
    this.linkedInstitutionId = '',
    this.linkedInstitutionName = '',
    required this.phone,
    required this.email,
    required this.address,
    required this.description,
    required this.experience,
    required this.qualifications,
    required this.services,
    required this.schedule,
    required this.available,
    required this.isVisible,
    required this.verificationStatus,
    required this.rejectionReason,
    required this.termsAccepted,
  });

  bool get isApproved =>
      verificationStatus == ProviderVerificationStatus.approved;

  int get completionPercent {
    final values = <String>[
      displayName,
      category,
      registrationNumber,
      phone,
      email,
      address,
      description,
      services,
      schedule,
      if (accountType == ProviderAccountType.professional) qualifications,
      if (accountType == ProviderAccountType.institution) contactPerson,
    ];
    return ((values.where((value) => value.trim().isNotEmpty).length /
                values.length) *
            100)
        .round();
  }

  ProviderProfile copyWith({
    String? displayName,
    String? category,
    String? registrationNumber,
    String? contactPerson,
    String? workplace,
    String? linkedInstitutionId,
    String? linkedInstitutionName,
    String? phone,
    String? email,
    String? address,
    String? description,
    String? experience,
    String? qualifications,
    String? services,
    String? schedule,
    bool? available,
    bool? isVisible,
    ProviderVerificationStatus? verificationStatus,
    String? rejectionReason,
    bool? termsAccepted,
  }) => ProviderProfile(
    ownerUid: ownerUid,
    accountType: accountType,
    displayName: displayName ?? this.displayName,
    category: category ?? this.category,
    registrationNumber: registrationNumber ?? this.registrationNumber,
    contactPerson: contactPerson ?? this.contactPerson,
    workplace: workplace ?? this.workplace,
    linkedInstitutionId: linkedInstitutionId ?? this.linkedInstitutionId,
    linkedInstitutionName: linkedInstitutionName ?? this.linkedInstitutionName,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    description: description ?? this.description,
    experience: experience ?? this.experience,
    qualifications: qualifications ?? this.qualifications,
    services: services ?? this.services,
    schedule: schedule ?? this.schedule,
    available: available ?? this.available,
    isVisible: isVisible ?? this.isVisible,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    termsAccepted: termsAccepted ?? this.termsAccepted,
  );

  factory ProviderProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    String text(String key) => data[key]?.toString().trim() ?? '';
    return ProviderProfile(
      ownerUid: text('ownerUid').isEmpty ? document.id : text('ownerUid'),
      accountType: ProviderAccountTypeText.fromStorage(text('accountType')),
      displayName: text('displayName'),
      category: text('category'),
      registrationNumber: text('registrationNumber'),
      contactPerson: text('contactPerson'),
      workplace: text('workplace'),
      linkedInstitutionId: text('linkedInstitutionId'),
      linkedInstitutionName: text('linkedInstitutionName'),
      phone: text('phone'),
      email: text('email'),
      address: text('address'),
      description: text('description'),
      experience: text('experience'),
      qualifications: text('qualifications'),
      services: text('services'),
      schedule: text('schedule'),
      available: data['available'] != false,
      isVisible: data['isVisible'] == true,
      verificationStatus: ProviderVerificationStatusText.fromStorage(
        text('verificationStatus'),
      ),
      rejectionReason: text('rejectionReason'),
      termsAccepted: data['termsAccepted'] == true,
    );
  }

  Map<String, dynamic> toCreateMap() => {
    ...toEditableMap(),
    'ownerUid': ownerUid,
    'accountType': accountType.storageValue,
    'verificationStatus': ProviderVerificationStatus.pending.storageValue,
    'rejectionReason': '',
    'isVisible': false,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toEditableMap() => {
    'displayName': displayName.trim(),
    'category': category.trim(),
    'registrationNumber': registrationNumber.trim(),
    'contactPerson': contactPerson.trim(),
    'workplace': workplace.trim(),
    'linkedInstitutionId': accountType == ProviderAccountType.professional
        ? linkedInstitutionId.trim()
        : '',
    'linkedInstitutionName': accountType == ProviderAccountType.professional
        ? linkedInstitutionName.trim()
        : '',
    'phone': phone.trim(),
    'email': email.trim(),
    'address': address.trim(),
    'description': description.trim(),
    'experience': experience.trim(),
    'qualifications': qualifications.trim(),
    'services': services.trim(),
    'schedule': schedule.trim(),
    'available': available,
    'isVisible': isApproved && isVisible,
    'termsAccepted': termsAccepted,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toDirectoryMap() =>
      accountType == ProviderAccountType.professional
      ? {
          'ownerUid': ownerUid,
          'nomComplet': displayName.trim(),
          'specialite': category.trim(),
          'etablissement': workplace.trim(),
          'institutionId': linkedInstitutionId.trim(),
          'institutionName': linkedInstitutionName.trim(),
          'biographie': description.trim(),
          'experience': experience.trim(),
          'qualification': qualifications.trim(),
          'services': services.trim(),
          'horaires': schedule.trim(),
          'adresse': address.trim(),
          'telephone': phone.trim(),
          'email': email.trim(),
          'disponible': available,
          'isPublished': true,
          'verificationStatus': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        }
      : {
          'ownerUid': ownerUid,
          'nom': displayName.trim(),
          'type': category.trim(),
          'description': description.trim(),
          'services': services.trim(),
          'horaires': schedule.trim(),
          'adresse': address.trim(),
          'telephone': phone.trim(),
          'email': email.trim(),
          'disponible': available,
          'isPublished': true,
          'verificationStatus': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        };
}
