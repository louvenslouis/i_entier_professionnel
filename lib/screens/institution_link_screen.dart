import 'package:flutter/material.dart';

import '../data/professional_repository.dart';
import '../models/health_institution.dart';
import '../models/provider_profile.dart';
import '../theme/pro_theme.dart';

class InstitutionLinkScreen extends StatefulWidget {
  final ProviderProfile profile;
  final ProfessionalRepository repository;

  const InstitutionLinkScreen({
    super.key,
    required this.profile,
    required this.repository,
  });

  @override
  State<InstitutionLinkScreen> createState() => _InstitutionLinkScreenState();
}

class _InstitutionLinkScreenState extends State<InstitutionLinkScreen> {
  final _searchController = TextEditingController();
  late final Stream<List<HealthInstitution>> _institutionsStream = widget
      .repository
      .watchInstitutions();
  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _link(HealthInstitution institution) async {
    setState(() => _saving = true);
    try {
      await widget.repository.linkInstitution(widget.profile, institution);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous êtes maintenant lié à ${institution.name}.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La liaison n’a pas pu être enregistrée. Réessayez plus tard.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _unlink() async {
    setState(() => _saving = true);
    try {
      await widget.repository.unlinkInstitution(widget.profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La liaison a été supprimée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer la liaison actuellement.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Mon institution',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 6),
      const Text(
        'Recherchez une institution déjà inscrite sur i-ENTIER et associez-la à votre profil.',
        style: TextStyle(color: ProColors.muted, fontSize: 16),
      ),
      const SizedBox(height: 24),
      if (widget.profile.linkedInstitutionId.isNotEmpty)
        _CurrentInstitutionCard(
          institutionName: widget.profile.linkedInstitutionName,
          saving: _saving,
          onUnlink: _unlink,
        )
      else
        const _NoInstitutionCard(),
      const SizedBox(height: 22),
      TextField(
        key: const ValueKey('institution-search-field'),
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          labelText: 'Rechercher une institution',
          hintText: 'Nom, type ou adresse',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
      const SizedBox(height: 16),
      StreamBuilder<List<HealthInstitution>>(
        stream: _institutionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: ProColors.primary),
              ),
            );
          }
          if (snapshot.hasError) {
            return const _SearchMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Institutions indisponibles',
              message: 'Vérifiez votre connexion puis réessayez.',
            );
          }
          final institutions = (snapshot.data ?? const <HealthInstitution>[])
              .where((institution) => institution.matches(_query))
              .toList();
          if (institutions.isEmpty) {
            return _SearchMessage(
              icon: Icons.search_off_rounded,
              title: _query.trim().isEmpty
                  ? 'Aucune institution inscrite'
                  : 'Aucun résultat',
              message: _query.trim().isEmpty
                  ? 'Les institutions publiées apparaîtront ici.'
                  : 'Essayez un autre nom, type ou lieu.',
            );
          }
          return Column(
            children: [
              for (final institution in institutions) ...[
                _InstitutionResultCard(
                  institution: institution,
                  selected:
                      institution.id == widget.profile.linkedInstitutionId,
                  saving: _saving,
                  onLink: () => _link(institution),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    ],
  );
}

class _CurrentInstitutionCard extends StatelessWidget {
  final String institutionName;
  final bool saving;
  final VoidCallback onUnlink;

  const _CurrentInstitutionCard({
    required this.institutionName,
    required this.saving,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ProColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.domain_rounded, color: ProColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Institution liée',
                style: TextStyle(color: ProColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                institutionName.isEmpty
                    ? 'Institution sélectionnée'
                    : institutionName,
                style: const TextStyle(
                  color: ProColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: saving ? null : onUnlink,
          child: const Text('Dissocier'),
        ),
      ],
    ),
  );
}

class _NoInstitutionCard extends StatelessWidget {
  const _NoInstitutionCard();

  @override
  Widget build(BuildContext context) => ProPanel(
    child: const Row(
      children: [
        Icon(Icons.link_off_rounded, color: ProColors.muted, size: 28),
        SizedBox(width: 13),
        Expanded(
          child: Text(
            'Votre profil n’est lié à aucune institution pour le moment.',
            style: TextStyle(color: ProColors.muted),
          ),
        ),
      ],
    ),
  );
}

class _InstitutionResultCard extends StatelessWidget {
  final HealthInstitution institution;
  final bool selected;
  final bool saving;
  final VoidCallback onLink;

  const _InstitutionResultCard({
    required this.institution,
    required this.selected,
    required this.saving,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    padding: const EdgeInsets.all(18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InstitutionAvatar(name: institution.name),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                institution.name,
                style: const TextStyle(
                  color: ProColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (institution.type.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  institution.type,
                  style: const TextStyle(
                    color: ProColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (institution.address.isNotEmpty) ...[
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: ProColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        institution.address,
                        style: const TextStyle(
                          color: ProColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        selected
            ? const Chip(
                avatar: Icon(Icons.check_rounded, size: 17),
                label: Text('Liée'),
              )
            : FilledButton(
                key: ValueKey('link-institution-${institution.id}'),
                onPressed: saving ? null : onLink,
                child: const Text('Lier'),
              ),
      ],
    ),
  );
}

class _InstitutionAvatar extends StatelessWidget {
  final String name;

  const _InstitutionAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final value = parts.isEmpty
        ? 'IN'
        : parts.length == 1
        ? parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ProColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: ProColors.muted, size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: ProColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ProColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
