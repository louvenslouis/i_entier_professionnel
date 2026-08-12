import 'dart:typed_data';

class TraditionalPractitionerApplication {
  final String providerId;
  final int experienceYears;
  final List<String> practiceDomains;
  final List<String> languages;
  final List<String> interventionZones;
  final String identityStatus;
  final String attestationStatus;
  final String validationStatus;
  final String reviewReason;
  final bool onlineAvailable;
  final int trustScore;

  const TraditionalPractitionerApplication({
    required this.providerId,
    required this.experienceYears,
    required this.practiceDomains,
    required this.languages,
    required this.interventionZones,
    required this.identityStatus,
    required this.attestationStatus,
    required this.validationStatus,
    required this.reviewReason,
    required this.onlineAvailable,
    required this.trustScore,
  });

  bool get isApproved => validationStatus == 'approved';
  bool get isSuspended => validationStatus == 'suspended';

  String get statusLabel => switch (validationStatus) {
    'approved' => 'Praticien vérifié',
    'rejected' => 'Dossier à corriger',
    'suspended' => 'Suspension préventive',
    _ => 'Validation I-Entier en cours',
  };

  factory TraditionalPractitionerApplication.fromRow(Map<String, dynamic> row) {
    List<String> list(String key) => (row[key] as List? ?? const [])
        .map((value) => value.toString())
        .toList(growable: false);
    return TraditionalPractitionerApplication(
      providerId: row['provider_id']?.toString() ?? '',
      experienceYears: (row['experience_years'] as num?)?.toInt() ?? 0,
      practiceDomains: list('practice_domains'),
      languages: list('languages'),
      interventionZones: list('intervention_zones'),
      identityStatus: row['identity_status']?.toString() ?? 'pending',
      attestationStatus: row['attestation_status']?.toString() ?? 'pending',
      validationStatus: row['validation_status']?.toString() ?? 'pending',
      reviewReason: row['review_reason']?.toString() ?? '',
      onlineAvailable: row['online_available'] == true,
      trustScore: (row['trust_score'] as num?)?.toInt() ?? 0,
    );
  }
}

class TraditionalPractitionerDocument {
  final String id;
  final String type;
  final String fileName;
  final String reviewStatus;
  final String reviewNote;

  const TraditionalPractitionerDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.reviewStatus,
    required this.reviewNote,
  });

  factory TraditionalPractitionerDocument.fromRow(Map<String, dynamic> row) =>
      TraditionalPractitionerDocument(
        id: row['document_id']?.toString() ?? '',
        type: row['document_type']?.toString() ?? 'other',
        fileName: row['original_file_name']?.toString() ?? '',
        reviewStatus: row['review_status']?.toString() ?? 'pending',
        reviewNote: row['review_note']?.toString() ?? '',
      );
}

class TraditionalCarePatient {
  final String id;
  final String name;

  const TraditionalCarePatient({required this.id, required this.name});
}

class PickedTraditionalDocument {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  const PickedTraditionalDocument({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });
}
