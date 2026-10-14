import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'professional_vault.dart';

/// Disposes clinical dialogs as soon as the session is closed or revoked.
class VaultAccessBoundary extends StatelessWidget {
  final SupabaseClient client;
  final String appointmentId;
  final Widget Function() builder;
  const VaultAccessBoundary({
    super.key,
    required this.client,
    required this.appointmentId,
    required this.builder,
  });
  @override
  Widget build(BuildContext context) {
    final vault = ProfessionalVault(client);
    return AnimatedBuilder(
      animation: vault,
      builder: (context, _) {
        if (vault.active && vault.appointmentId == appointmentId) {
          return builder();
        }
        return AlertDialog(
          title: const Text('Accès fermé'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}
