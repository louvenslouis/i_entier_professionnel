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
  final String atProviderSchedule;
  final String homeVisitSchedule;
  final String videoSchedule;
  final String defaultPrice;
  final bool institutionPricesPublished;
  final String servicePrices;
  final String roomPrices;
  final Map<String, Map<String, dynamic>> availabilityConfigurations;
  final bool atProviderEnabled;
  final bool homeVisitEnabled;
  final bool videoEnabled;
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
    this.atProviderSchedule = '',
    this.homeVisitSchedule = '',
    this.videoSchedule = '',
    this.defaultPrice = '',
    this.institutionPricesPublished = false,
    this.servicePrices = '',
    this.roomPrices = '',
    this.availabilityConfigurations = const <String, Map<String, dynamic>>{},
    this.atProviderEnabled = false,
    this.homeVisitEnabled = false,
    this.videoEnabled = false,
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
    String? atProviderSchedule,
    String? homeVisitSchedule,
    String? videoSchedule,
    String? defaultPrice,
    bool? institutionPricesPublished,
    String? servicePrices,
    String? roomPrices,
    Map<String, Map<String, dynamic>>? availabilityConfigurations,
    bool? atProviderEnabled,
    bool? homeVisitEnabled,
    bool? videoEnabled,
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
    atProviderSchedule: atProviderSchedule ?? this.atProviderSchedule,
    homeVisitSchedule: homeVisitSchedule ?? this.homeVisitSchedule,
    videoSchedule: videoSchedule ?? this.videoSchedule,
    defaultPrice: defaultPrice ?? this.defaultPrice,
    institutionPricesPublished:
        institutionPricesPublished ?? this.institutionPricesPublished,
    servicePrices: servicePrices ?? this.servicePrices,
    roomPrices: roomPrices ?? this.roomPrices,
    availabilityConfigurations:
        availabilityConfigurations ?? this.availabilityConfigurations,
    atProviderEnabled: atProviderEnabled ?? this.atProviderEnabled,
    homeVisitEnabled: homeVisitEnabled ?? this.homeVisitEnabled,
    videoEnabled: videoEnabled ?? this.videoEnabled,
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
    Map<String, Map<String, dynamic>> availabilityConfigurations() {
      final value = data['availabilityConfigurations'];
      if (value is! Map) return const <String, Map<String, dynamic>>{};
      return {
        for (final entry in value.entries)
          if (entry.key is String && entry.value is Map)
            entry.key as String: Map<String, dynamic>.from(entry.value as Map),
      };
    }

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
      atProviderSchedule: text('atProviderSchedule'),
      homeVisitSchedule: text('homeVisitSchedule'),
      videoSchedule: text('videoSchedule'),
      defaultPrice: text('defaultPrice'),
      institutionPricesPublished: data['institutionPricesPublished'] == true,
      servicePrices: text('servicePrices'),
      roomPrices: text('roomPrices'),
      availabilityConfigurations: availabilityConfigurations(),
      atProviderEnabled: data['atProviderEnabled'] == true,
      homeVisitEnabled: data['homeVisitEnabled'] == true,
      videoEnabled: data['videoEnabled'] == true,
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
    'atProviderSchedule': atProviderSchedule.trim(),
    'homeVisitSchedule': homeVisitSchedule.trim(),
    'videoSchedule': videoSchedule.trim(),
    'defaultPrice': defaultPrice.trim(),
    'institutionPricesPublished':
        accountType == ProviderAccountType.institution &&
        institutionPricesPublished,
    'servicePrices': accountType == ProviderAccountType.institution
        ? servicePrices.trim()
        : '',
    'roomPrices': accountType == ProviderAccountType.institution
        ? roomPrices.trim()
        : '',
    'availabilityConfigurations': availabilityConfigurations,
    'atProviderEnabled': atProviderEnabled,
    'homeVisitEnabled': homeVisitEnabled,
    'videoEnabled': videoEnabled,
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
          'horairesParMode': {
            'inPerson': atProviderSchedule.trim(),
            'homeVisit': homeVisitSchedule.trim(),
            'video': videoSchedule.trim(),
          },
          'modesDeRendezVous': {
            'inPerson': atProviderEnabled,
            'homeVisit': homeVisitEnabled,
            'video': videoEnabled,
          },
          'disponibilitesParMode': availabilityConfigurations,
          'prixParDefaut': defaultPrice.trim(),
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
          'tarifsPublies': institutionPricesPublished,
          'tarifsServices': institutionPricesPublished
              ? servicePrices.trim()
              : '',
          'tarifsChambres': institutionPricesPublished ? roomPrices.trim() : '',
          'isPublished': true,
          'verificationStatus': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        };
}
