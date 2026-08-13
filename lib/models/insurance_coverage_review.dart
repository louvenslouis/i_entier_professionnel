class InsuranceCoverageReview {
  final String id;
  final String patientId;
  final String patientName;
  final String insurerCode;
  final String memberNumber;
  final String frontPath;
  final String backPath;
  final String status;
  final String reviewNote;
  final DateTime? validUntil;
  final DateTime submittedAt;

  const InsuranceCoverageReview({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.insurerCode,
    required this.memberNumber,
    required this.frontPath,
    required this.backPath,
    required this.status,
    required this.reviewNote,
    required this.validUntil,
    required this.submittedAt,
  });

  factory InsuranceCoverageReview.fromRow(Map<String, dynamic> row) =>
      InsuranceCoverageReview(
        id: row['coverage_id']?.toString() ?? '',
        patientId: row['patient_id']?.toString() ?? '',
        patientName: row['patient_name_snapshot']?.toString() ?? '',
        insurerCode: row['insurer_code']?.toString() ?? 'OFATMA',
        memberNumber: row['member_number']?.toString() ?? '',
        frontPath: row['card_front_path']?.toString() ?? '',
        backPath: row['card_back_path']?.toString() ?? '',
        status: row['status']?.toString() ?? 'pending',
        reviewNote: row['review_note']?.toString() ?? '',
        validUntil: _date(row['valid_until']),
        submittedAt: _date(row['submitted_at']) ?? DateTime.now(),
      );

  bool get pending => status == 'pending';
}

DateTime? _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();
