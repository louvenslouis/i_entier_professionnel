import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_entier_professionnel/data/professional_repository.dart';
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
  Stream<ProviderProfile?> watchProfile(String uid) => Stream.value(submitted);
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
}
