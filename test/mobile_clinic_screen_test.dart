import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_entier_professionnel/data/mobile_clinic_repository.dart';
import 'package:i_entier_professionnel/models/mobile_clinic.dart';
import 'package:i_entier_professionnel/models/provider_profile.dart';
import 'package:i_entier_professionnel/screens/mobile_clinic_screen.dart';
import 'package:i_entier_professionnel/theme/pro_theme.dart';

void main() {
  testWidgets('bloque la création tant que le profil n’est pas validé', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen(
        profile: _profile(status: ProviderVerificationStatus.pending),
        repository: _FakeMobileClinicRepository(const []),
      ),
    );

    expect(find.text('Profil validé requis'), findsOneWidget);
    expect(find.textContaining('réservée aux professionnels'), findsOneWidget);
  });

  testWidgets('propose le workflow de demande aux acteurs validés', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen(
        profile: _profile(status: ProviderVerificationStatus.approved),
        repository: _FakeMobileClinicRepository(const []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Déployez une clinique mobile certifiée'), findsOneWidget);
    expect(find.text('Certification'), findsOneWidget);
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('Tournées'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-mobile-clinic')));
    await tester.pumpAndSettle();

    expect(find.text('Demande de Clinique Mobile'), findsOneWidget);
    expect(find.text('Type de créateur'), findsOneWidget);
    expect(find.text('Documents de vérification'), findsOneWidget);
    expect(find.text('Pièce d’identité du responsable *'), findsOneWidget);
    expect(find.text('Diplôme ou licence professionnelle *'), findsOneWidget);
  });

  testWidgets('affiche le badge et les outils après certification', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _screen(
        profile: _profile(status: ProviderVerificationStatus.approved),
        repository: _FakeMobileClinicRepository([_clinic]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clinique Mobile Espoir'), findsOneWidget);
    expect(find.text('Clinique Mobile Certifiée I-Entier'), findsOneWidget);
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Rendez-vous'), findsOneWidget);
    expect(find.text('Interventions'), findsOneWidget);
  });

  test(
    'sépare correctement les créateurs professionnels et institutionnels',
    () {
      expect(MobileClinicCreatorType.doctor.isProfessional, isTrue);
      expect(MobileClinicCreatorType.dentist.isProfessional, isTrue);
      expect(MobileClinicCreatorType.ngo.isProfessional, isFalse);
      expect(MobileClinicCreatorType.company.isProfessional, isFalse);
    },
  );
}

Widget _screen({
  required ProviderProfile profile,
  required MobileClinicRepository repository,
}) => MaterialApp(
  theme: buildProTheme(),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MobileClinicScreen(profile: profile, repository: repository),
    ),
  ),
);

ProviderProfile _profile({required ProviderVerificationStatus status}) =>
    ProviderProfile.fromRow({
      'provider_id': 'provider-1',
      'account_type': 'professional',
      'display_name': 'Dr Marie Jean',
      'category': 'Médecin',
      'registration_number': 'MED-101',
      'phone': '+509 3700 0000',
      'email': 'marie@ientier.ht',
      'address': 'Jacmel',
      'description': 'Médecin généraliste',
      'qualifications': 'Doctorat en médecine',
      'services_summary': 'Médecine générale',
      'schedule_summary': 'Lundi au vendredi 08h-16h',
      'verification_status': status.storageValue,
      'terms_accepted': true,
    });

final _clinic = MobileClinic.fromRow({
  'mobile_clinic_id': 'clinic-1',
  'owner_provider_id': 'provider-1',
  'creator_type': 'doctor',
  'name': 'Clinique Mobile Espoir',
  'responsible_name': 'Dr Marie Jean',
  'phone': '+509 3700 0000',
  'email': 'marie@ientier.ht',
  'description': 'Soins de proximité',
  'base_address': 'Jacmel',
  'department': 'Sud-Est',
  'commune': 'Jacmel',
  'identity_document_url': 'https://docs.test/identity.pdf',
  'professional_license_url': 'https://docs.test/license.pdf',
  'operating_authorization_url': 'https://docs.test/auth.pdf',
  'verification_status': 'approved',
  'certification_badge': 'Clinique Mobile Certifiée I-Entier',
  'is_published': true,
  'is_deployed': false,
});

class _FakeMobileClinicRepository implements MobileClinicRepository {
  final List<MobileClinic> clinics;

  _FakeMobileClinicRepository(this.clinics);

  @override
  Stream<List<MobileClinic>> watchClinics(String ownerId) =>
      Stream.value(clinics);

  @override
  Stream<List<MobileClinicAppointment>> watchAppointments(String clinicId) =>
      Stream.value(const []);

  @override
  Stream<List<MobileClinicIntervention>> watchInterventions(String clinicId) =>
      Stream.value(const []);

  @override
  Stream<List<MobileClinicService>> watchServices(String clinicId) =>
      Stream.value(const []);

  @override
  Stream<List<MobileClinicStaffMember>> watchStaff(String clinicId) =>
      Stream.value(const []);

  @override
  Stream<List<MobileClinicTour>> watchTours(String clinicId) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
