import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_entier_professionnel/data/appointment_repository.dart';
import 'package:i_entier_professionnel/data/professional_repository.dart';
import 'package:i_entier_professionnel/models/appointment_request.dart';
import 'package:i_entier_professionnel/models/health_institution.dart';
import 'package:i_entier_professionnel/models/provider_profile.dart';
import 'package:i_entier_professionnel/screens/dashboard_screen.dart';
import 'package:i_entier_professionnel/screens/registration_screen.dart';
import 'package:i_entier_professionnel/screens/sign_in_screen.dart';
import 'package:i_entier_professionnel/theme/pro_theme.dart';

class FakeProfessionalRepository implements ProfessionalRepository {
  ProviderProfile? submitted;
  ProviderProfile? updated;
  bool? visibility;
  bool? availability;
  HealthInstitution? linkedInstitution;
  bool unlinked = false;
  List<HealthInstitution> institutions = const [];

  @override
  Future<void> linkInstitution(
    ProviderProfile profile,
    HealthInstitution institution,
  ) async {
    linkedInstitution = institution;
  }

  @override
  Future<void> setAvailability(ProviderProfile profile, bool available) async {
    availability = available;
  }

  @override
  Future<void> setVisibility(ProviderProfile profile, bool isVisible) async {
    visibility = isVisible;
  }

  @override
  Future<void> submitProfile(ProviderProfile profile) async {
    submitted = profile;
  }

  @override
  Future<void> updateProfile(ProviderProfile profile) async {
    updated = profile;
  }

  @override
  Future<void> unlinkInstitution(ProviderProfile profile) async {
    unlinked = true;
  }

  @override
  Stream<List<HealthInstitution>> watchInstitutions() =>
      Stream.value(institutions);

  @override
  Stream<ProviderProfile?> watchProfile(String uid) => Stream.value(submitted);
}

class FakeAppointmentRepository implements ProfessionalAppointmentRepository {
  final List<ProfessionalAppointment> appointments;
  ProfessionalAppointmentStatus? responseStatus;
  String? responseNote;

  FakeAppointmentRepository(this.appointments);

  @override
  Future<void> respond({
    required ProfessionalAppointment appointment,
    required ProfessionalAppointmentStatus status,
    required String responseNote,
  }) async {
    responseStatus = status;
    this.responseNote = responseNote;
  }

  @override
  Stream<List<ProfessionalAppointment>> watchForProvider(String providerId) =>
      Stream.value(appointments);
}

ProviderProfile profile({
  ProviderAccountType type = ProviderAccountType.professional,
  ProviderVerificationStatus status = ProviderVerificationStatus.pending,
  bool visible = false,
}) => ProviderProfile(
  ownerUid: 'provider-1',
  accountType: type,
  displayName: type == ProviderAccountType.professional
      ? 'Dr Marie Jean'
      : 'Clinique Espoir',
  category: type == ProviderAccountType.professional ? 'Pédiatre' : 'Clinique',
  registrationNumber: 'REG-123',
  contactPerson: 'Jean Paul, directeur',
  workplace: 'Clinique Espoir',
  phone: '+509 2222-0000',
  email: 'contact@example.ht',
  address: 'Pétion-Ville, Ouest',
  description: 'Des soins de proximité centrés sur chaque patient.',
  experience: '8 ans',
  qualifications: 'Médecine, pédiatrie',
  services: 'Consultation, vaccination',
  schedule: 'Lun–Ven, 8 h–16 h',
  available: true,
  isVisible: visible,
  verificationStatus: status,
  rejectionReason: '',
  termsAccepted: true,
);

Widget app(Widget home) => MaterialApp(theme: buildProTheme(), home: home);

ProfessionalAppointment appointment() => ProfessionalAppointment(
  id: 'appointment-1',
  patientId: 'patient-1',
  patientName: 'Jean Baptiste',
  providerId: 'provider-1',
  providerType: 'professional',
  providerName: 'Dr Marie Jean',
  service: 'Consultation',
  mode: ProfessionalAppointmentMode.video,
  scheduledAt: DateTime(2026, 8, 4, 9, 30),
  scheduleLabel: 'Lun–Ven, 8 h–16 h',
  status: ProfessionalAppointmentStatus.pending,
  patientNote: 'Consultation de suivi',
  responseNote: '',
  createdAt: DateTime(2026, 7, 22),
  updatedAt: DateTime(2026, 7, 22),
);

void main() {
  testWidgets('affiche le portail professionnel distinct', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const ProSignInScreen()));

    expect(find.text('i-ENTIER'), findsOneWidget);
    expect(find.text('PROFESSIONNEL'), findsOneWidget);
    expect(
      find.text('Bienvenue dans votre espace professionnel'),
      findsOneWidget,
    );
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('propose les parcours personnel et institution', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeProfessionalRepository();

    await tester.pumpWidget(
      app(
        ProRegistrationScreen(
          uid: 'provider-1',
          accountEmail: 'pro@example.ht',
          accountName: 'Marie Jean',
          repository: repository,
        ),
      ),
    );

    expect(find.text('Personnel de santé'), findsOneWidget);
    expect(find.text('Institution de santé'), findsOneWidget);
    expect(find.text('Identité professionnelle'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('type-institution')));
    await tester.pump();

    expect(find.text('Identité de l’institution'), findsOneWidget);
    expect(find.text('Responsable du compte *'), findsOneWidget);
    expect(find.text('Numéro d’enregistrement *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bloque la publication tant que le profil est en attente', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeProfessionalRepository();

    await tester.pumpWidget(
      app(
        ProDashboardScreen(
          profile: profile(),
          repository: repository,
          onSignOut: () async {},
        ),
      ),
    );

    expect(find.text('Validation en cours'), findsOneWidget);
    final visibilitySwitch = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const ValueKey('directory-visibility-switch')),
        matching: find.byType(Switch),
      ),
    );
    expect(visibilitySwitch.onChanged, isNull);
    expect(find.text('Disponible après validation du profil.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permet à un profil validé de gérer sa visibilité', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeProfessionalRepository();

    await tester.pumpWidget(
      app(
        ProDashboardScreen(
          profile: profile(status: ProviderVerificationStatus.approved),
          repository: repository,
          onSignOut: () async {},
        ),
      ),
    );

    expect(find.text('Profil vérifié'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('directory-visibility-switch')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pump();

    expect(repository.visibility, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recherche et lie le personnel à une institution existante', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeProfessionalRepository()
      ..institutions = const [
        HealthInstitution(
          id: 'institution-1',
          name: 'Clinique Espoir',
          type: 'Clinique',
          address: 'Pétion-Ville, Ouest',
          phone: '+509 2222-0000',
        ),
        HealthInstitution(
          id: 'institution-2',
          name: 'Hôpital Saint Marc',
          type: 'Hôpital',
          address: 'Saint-Marc, Artibonite',
          phone: '+509 3333-0000',
        ),
      ];

    await tester.pumpWidget(
      app(
        ProDashboardScreen(
          profile: profile(status: ProviderVerificationStatus.approved),
          repository: repository,
          onSignOut: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Mon institution'));
    await tester.pumpAndSettle();

    expect(find.text('Rechercher une institution'), findsOneWidget);
    expect(find.text('Clinique Espoir'), findsOneWidget);
    expect(find.text('Hôpital Saint Marc'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('institution-search-field')),
      'saint marc',
    );
    await tester.pump();

    expect(find.text('Clinique Espoir'), findsNothing);
    expect(find.text('Hôpital Saint Marc'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('link-institution-institution-2')),
    );
    await tester.pumpAndSettle();

    expect(repository.linkedInstitution?.id, 'institution-2');
    expect(find.textContaining('maintenant lié'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permet de valider une demande et notifier le patient', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeProfessionalRepository();
    final appointments = FakeAppointmentRepository([appointment()]);

    await tester.pumpWidget(
      app(
        ProDashboardScreen(
          profile: profile(status: ProviderVerificationStatus.approved),
          repository: repository,
          appointmentRepository: appointments,
          onSignOut: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Rendez-vous'));
    await tester.pumpAndSettle();

    expect(find.text('Jean Baptiste'), findsOneWidget);
    expect(find.text('Consultation de suivi'), findsOneWidget);
    expect(find.text('Visioconférence'), findsOneWidget);
    expect(find.text('En attente'), findsWidgets);

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Valider le rendez-vous'), findsOneWidget);
    expect(
      find.text('Lien ou instructions de visioconférence'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField),
      'Votre rendez-vous est confirmé.',
    );
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(
      appointments.responseStatus,
      ProfessionalAppointmentStatus.confirmed,
    );
    expect(appointments.responseNote, 'Votre rendez-vous est confirmé.');
    expect(find.textContaining('patient notifié'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('publie aussi la disponibilité des institutions', () {
    final institution = profile(
      type: ProviderAccountType.institution,
      status: ProviderVerificationStatus.approved,
      visible: true,
    );

    expect(institution.toDirectoryMap()['disponible'], isTrue);
  });
}
