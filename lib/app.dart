import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'data/professional_repository.dart';
import 'models/provider_profile.dart';
import 'screens/dashboard_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/sign_in_screen.dart';
import 'theme/pro_theme.dart';

class IEntierProfessionnelApp extends StatelessWidget {
  final ProfessionalRepository? repository;

  const IEntierProfessionnelApp({super.key, this.repository});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'i-ENTIER Professionnel',
    debugShowCheckedModeBanner: false,
    theme: buildProTheme(),
    home: ProfessionalAuthGate(
      repository: repository ?? FirestoreProfessionalRepository(),
    ),
  );
}

class ProfessionalAuthGate extends StatelessWidget {
  final ProfessionalRepository repository;

  const ProfessionalAuthGate({super.key, required this.repository});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const ProLoadingScreen();
      }
      final user = snapshot.data;
      if (user == null) return const ProSignInScreen();
      return ProviderProfileGate(user: user, repository: repository);
    },
  );
}

class ProviderProfileGate extends StatelessWidget {
  final User user;
  final ProfessionalRepository repository;

  const ProviderProfileGate({
    super.key,
    required this.user,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<ProviderProfile?>(
    stream: repository.watchProfile(user.uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const ProLoadingScreen();
      }
      if (snapshot.hasError) {
        return const ProErrorScreen(
          title: 'Impossible d’ouvrir votre espace',
          message:
              'Vérifiez la connexion et les règles Firestore de providerProfiles.',
        );
      }
      final profile = snapshot.data;
      if (profile == null) {
        return ProRegistrationScreen(
          uid: user.uid,
          accountEmail: user.email ?? '',
          accountName: user.displayName ?? '',
          repository: repository,
        );
      }
      return ProDashboardScreen(profile: profile, repository: repository);
    },
  );
}

class ProLoadingScreen extends StatelessWidget {
  const ProLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: ProColors.primary)),
  );
}

class ProErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const ProErrorScreen({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ProPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: ProColors.primary,
                  size: 42,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                TextButton.icon(
                  onPressed: FirebaseAuth.instance.signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Changer de compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
