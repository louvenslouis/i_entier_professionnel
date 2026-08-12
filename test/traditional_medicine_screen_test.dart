import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_entier_professionnel/data/traditional_medicine_repository.dart';
import 'package:i_entier_professionnel/models/provider_profile.dart';
import 'package:i_entier_professionnel/models/traditional_medicine.dart';
import 'package:i_entier_professionnel/screens/traditional_medicine_screen.dart';
import 'package:i_entier_professionnel/theme/pro_theme.dart';

ProviderProfile _profile() => const ProviderProfile(
  ownerUid: 'provider-1',
  accountType: ProviderAccountType.professional,
  displayName: 'Man Rose Pierre',
  category: 'Praticienne traditionnelle',
  registrationNumber: 'TRAD-001',
  contactPerson: '',
  workplace: 'Cabinet Rose',
  phone: '+509 2222-0000',
  email: 'rose@example.ht',
  address: 'Delmas',
  description: 'Accompagnement traditionnel.',
  experience: '18 ans',
  qualifications: 'Attestation communautaire',
  services: 'Prévention et bien-être',
  schedule: 'Lundi au vendredi',
  available: true,
  isVisible: true,
  verificationStatus: ProviderVerificationStatus.approved,
  rejectionReason: '',
  termsAccepted: true,
);

class _FakeRepository implements TraditionalMedicineProfessionalRepository {
  TraditionalPractitionerApplication? application;
  int submitCount = 0;
  final List<String> uploadedTypes = [];
  bool? availability;
  String? recommendationPatient;
  String? orientationPatient;

  _FakeRepository(this.application);

  @override
  Stream<TraditionalPractitionerApplication?> watchApplication(
    String providerId,
  ) => Stream.value(application);

  @override
  Stream<List<TraditionalPractitionerDocument>> watchDocuments(
    String providerId,
  ) => Stream.value(const []);

  @override
  Stream<List<TraditionalCarePatient>> watchCarePatients(String providerId) =>
      Stream.value(const [
        TraditionalCarePatient(id: 'patient-1', name: 'Marie Patient'),
      ]);

  @override
  Future<void> submitApplication({
    required String providerId,
    required int experienceYears,
    required List<String> practiceDomains,
    required List<String> languages,
    required List<String> interventionZones,
  }) async => submitCount++;

  @override
  Future<void> uploadDocument({
    required String providerId,
    required String documentType,
    required PickedTraditionalDocument document,
  }) async => uploadedTypes.add(documentType);

  @override
  Future<void> setOnlineAvailability(String providerId, bool available) async =>
      availability = available;

  @override
  Future<void> sendPreventionRecommendation({
    required String providerId,
    required String patientId,
    required String type,
    required String title,
    required String content,
    DateTime? reminderAt,
  }) async => recommendationPatient = patientId;

  @override
  Future<void> createOrientation({
    required String providerId,
    required String patientId,
    required String targetType,
    required String targetName,
    required String reason,
    required String urgency,
  }) async => orientationPatient = patientId;
}

void main() {
  testWidgets('soumet le profil avec identité et attestation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository(null);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildProTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TraditionalMedicineProfessionalScreen(
              profile: _profile(),
              repository: repository,
              documentPicker: (type) async => PickedTraditionalDocument(
                fileName: '$type.jpg',
                mimeType: 'image/jpeg',
                bytes: Uint8List.fromList([1, 2, 3]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('traditional-pro-experience')),
      '18',
    );
    await tester.enterText(
      find.byKey(const Key('traditional-pro-domains')),
      'Prévention, plantes traditionnelles',
    );
    await tester.enterText(
      find.byKey(const Key('traditional-pro-zones')),
      'Delmas, Pétion-Ville',
    );
    await tester.tap(find.byKey(const Key('traditional-pro-scope')));
    await tester.tap(find.byKey(const Key('traditional-pro-submit')));
    await tester.pumpAndSettle();

    expect(repository.submitCount, 1);
    expect(repository.uploadedTypes, ['identity', 'attestation']);
  });

  testWidgets('active les outils uniquement pour un praticien approuvé', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository(
      const TraditionalPractitionerApplication(
        providerId: 'provider-1',
        experienceYears: 18,
        practiceDomains: ['Prévention'],
        languages: ['Créole haïtien'],
        interventionZones: ['Delmas'],
        identityStatus: 'verified',
        attestationStatus: 'verified',
        validationStatus: 'approved',
        reviewReason: '',
        onlineAvailable: false,
        trustScore: 82,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildProTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TraditionalMedicineProfessionalScreen(
              profile: _profile(),
              repository: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Praticien vérifié'), findsOneWidget);
    expect(find.text('Accompagnement sécurisé'), findsOneWidget);
    expect(find.text('Orientation intelligente'), findsOneWidget);

    await tester.tap(find.byKey(const Key('traditional-pro-availability')));
    await tester.pumpAndSettle();
    expect(repository.availability, isTrue);

    await tester.enterText(
      find.byKey(const Key('traditional-pro-orientation-name')),
      'Hôpital partenaire',
    );
    await tester.enterText(
      find.byKey(const Key('traditional-pro-orientation-reason')),
      'Évaluation médicale complémentaire',
    );
    await tester.ensureVisible(
      find.byKey(const Key('traditional-pro-send-orientation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('traditional-pro-send-orientation')));
    await tester.pumpAndSettle();
    expect(repository.orientationPatient, 'patient-1');
  });
}
