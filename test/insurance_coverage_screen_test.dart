import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_entier_professionnel/data/insurance_coverage_repository.dart';
import 'package:i_entier_professionnel/models/insurance_coverage_review.dart';
import 'package:i_entier_professionnel/models/provider_profile.dart';
import 'package:i_entier_professionnel/screens/insurance_coverage_screen.dart';
import 'package:i_entier_professionnel/theme/pro_theme.dart';

void main() {
  testWidgets('permet à un professionnel vérifié de refuser une carte OFATMA', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeCoverageRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildProTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: InsuranceCoverageValidationScreen(
              profile: _approvedProfessional,
              repository: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Couvertures médicales'), findsOneWidget);
    expect(find.text('Marie Jean'), findsOneWidget);
    expect(find.text('Voir le recto'), findsOneWidget);
    expect(find.text('Voir le verso'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reject-coverage-coverage-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Le verso de la carte est illisible.',
    );
    await tester.pump();
    await tester.tap(find.text('Confirmer le refus'));
    await tester.pumpAndSettle();

    expect(repository.reviewedCoverageId, 'coverage-1');
    expect(repository.approved, isFalse);
    expect(repository.reason, 'Le verso de la carte est illisible.');
  });

  testWidgets('bloque la file pour un profil encore en attente', (
    tester,
  ) async {
    final repository = _FakeCoverageRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildProTheme(),
        home: Scaffold(
          body: InsuranceCoverageValidationScreen(
            profile: _approvedProfessional.copyWith(
              verificationStatus: ProviderVerificationStatus.pending,
            ),
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Validation non disponible'), findsOneWidget);
    expect(repository.watchCalls, 0);
  });
}

class _FakeCoverageRepository
    implements InsuranceCoverageProfessionalRepository {
  int watchCalls = 0;
  String? reviewedCoverageId;
  bool? approved;
  String? reason;

  @override
  Stream<List<InsuranceCoverageReview>> watchCoverages() {
    watchCalls++;
    return Stream.value([
      InsuranceCoverageReview(
        id: 'coverage-1',
        patientId: 'patient-1',
        patientName: 'Marie Jean',
        insurerCode: 'OFATMA',
        memberNumber: 'OF-1234',
        frontPath: 'patient-1/front.jpg',
        backPath: 'patient-1/back.jpg',
        status: 'pending',
        reviewNote: '',
        validUntil: null,
        submittedAt: DateTime(2026, 8, 13),
      ),
    ]);
  }

  @override
  Future<String> createCardUrl(String storagePath) async =>
      'https://example.test/card.jpg';

  @override
  Future<void> reviewCoverage({
    required String coverageId,
    required bool approve,
    required String reason,
    DateTime? validUntil,
  }) async {
    reviewedCoverageId = coverageId;
    approved = approve;
    this.reason = reason;
  }
}

const _approvedProfessional = ProviderProfile(
  ownerUid: 'provider-1',
  accountType: ProviderAccountType.professional,
  displayName: 'Dr Paul Joseph',
  category: 'Médecin généraliste',
  registrationNumber: 'REG-123',
  contactPerson: '',
  workplace: 'Clinique Espoir',
  phone: '+509 2222-0000',
  email: 'paul@example.ht',
  address: 'Delmas',
  description: 'Médecine générale',
  experience: '8 ans',
  qualifications: 'Doctorat en médecine',
  services: 'Consultation',
  schedule: 'Lun-Ven',
  available: true,
  isVisible: true,
  verificationStatus: ProviderVerificationStatus.approved,
  rejectionReason: '',
  termsAccepted: true,
);
