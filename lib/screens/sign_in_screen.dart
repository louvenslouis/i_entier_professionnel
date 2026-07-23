import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/pro_theme.dart';

class ProSignInScreen extends StatefulWidget {
  const ProSignInScreen({super.key});

  @override
  State<ProSignInScreen> createState() => _ProSignInScreenState();
}

class _ProSignInScreenState extends State<ProSignInScreen> {
  bool _signingIn = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      _error = switch (error.code) {
        'popup-closed-by-user' => 'La fenêtre de connexion a été fermée.',
        'network-request-failed' => 'Vérifiez votre connexion Internet.',
        _ => 'Connexion impossible pour le moment. Réessayez.',
      };
    } catch (_) {
      _error = 'La connexion Google n’a pas abouti. Réessayez.';
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ProColors.navy,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const _Backdrop(),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 880;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: desktop ? 56 : 22,
                  vertical: desktop ? 42 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 1160,
                      minHeight: constraints.maxHeight - (desktop ? 84 : 48),
                    ),
                    child: desktop
                        ? Row(
                            children: [
                              const Expanded(child: _SignInStory()),
                              const SizedBox(width: 70),
                              Expanded(
                                child: _SignInCard(
                                  signingIn: _signingIn,
                                  error: _error,
                                  onSignIn: _signIn,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const ProBrand(light: true),
                              const SizedBox(height: 34),
                              _SignInCard(
                                signingIn: _signingIn,
                                error: _error,
                                onSignIn: _signIn,
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF082F39), Color(0xFF075B63)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -120,
          top: -130,
          child: Container(
            width: 360,
            height: 360,
            decoration: const BoxDecoration(
              color: Color(0x1FFFF0D4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -90,
          bottom: -170,
          child: Container(
            width: 420,
            height: 420,
            decoration: const BoxDecoration(
              color: Color(0x1400D5C6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SignInStory extends StatelessWidget {
  const _SignInStory();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ProBrand(light: true),
      SizedBox(height: 48),
      Text(
        'Votre expertise,\nplus proche des patients.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 44,
          height: 1.08,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
        ),
      ),
      SizedBox(height: 20),
      SizedBox(
        width: 500,
        child: Text(
          'Créez et pilotez la présence de votre cabinet, de votre pratique ou de votre institution dans l’annuaire i-ENTIER.',
          style: TextStyle(
            color: Color(0xFFD4E8E9),
            fontSize: 17,
            height: 1.55,
          ),
        ),
      ),
      SizedBox(height: 34),
      _Benefit(
        icon: Icons.verified_user_outlined,
        text: 'Profil vérifié et informations maîtrisées',
      ),
      SizedBox(height: 14),
      _Benefit(
        icon: Icons.visibility_outlined,
        text: 'Visibilité et disponibilité modifiables à tout moment',
      ),
      SizedBox(height: 14),
      _Benefit(
        icon: Icons.groups_outlined,
        text: 'Une porte d’entrée simple pour les patients',
      ),
    ],
  );
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFFD59F), size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _SignInCard extends StatelessWidget {
  final bool signingIn;
  final String? error;
  final VoidCallback onSignIn;

  const _SignInCard({
    required this.signingIn,
    required this.error,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3500161C),
          blurRadius: 45,
          offset: Offset(0, 20),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ProColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            color: ProColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Bienvenue dans votre espace professionnel',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: ProColors.ink,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Connectez-vous pour inscrire votre activité ou administrer votre fiche i-ENTIER.',
          style: TextStyle(color: ProColors.muted, height: 1.5),
        ),
        if (error != null) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              error!,
              style: const TextStyle(color: Color(0xFFA92B23)),
            ),
          ),
        ],
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('pro-google-sign-in'),
            onPressed: signingIn ? null : onSignIn,
            icon: signingIn
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded, size: 20),
            label: Text(signingIn ? 'Connexion…' : 'Continuer avec Google'),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'L’inscription est soumise à une vérification avant publication dans l’annuaire.',
          style: TextStyle(color: ProColors.muted, fontSize: 12.5, height: 1.4),
        ),
      ],
    ),
  );
}
