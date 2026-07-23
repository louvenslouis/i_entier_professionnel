import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/appointment_repository.dart';
import '../data/professional_repository.dart';
import '../models/provider_profile.dart';
import '../theme/pro_theme.dart';
import 'appointments_screen.dart';
import 'registration_screen.dart';

class ProDashboardScreen extends StatefulWidget {
  final ProviderProfile profile;
  final ProfessionalRepository repository;
  final ProfessionalAppointmentRepository? appointmentRepository;
  final Future<void> Function()? onSignOut;

  const ProDashboardScreen({
    super.key,
    required this.profile,
    required this.repository,
    this.appointmentRepository,
    this.onSignOut,
  });

  @override
  State<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends State<ProDashboardScreen> {
  int _selectedIndex = 0;
  bool _updating = false;
  late final ProfessionalAppointmentRepository _appointmentRepository =
      widget.appointmentRepository ??
      FirestoreProfessionalAppointmentRepository();

  Future<void> _setVisibility(bool value) async {
    setState(() => _updating = true);
    try {
      await widget.repository.setVisibility(widget.profile, value);
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _setAvailability(bool value) async {
    setState(() => _updating = true);
    try {
      await widget.repository.setAvailability(widget.profile, value);
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La modification n’a pas été enregistrée.')),
    );
  }

  Future<void> _editProfile() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProRegistrationScreen(
        uid: widget.profile.ownerUid,
        accountEmail: widget.profile.email,
        accountName: widget.profile.displayName,
        repository: widget.repository,
        initialProfile: widget.profile,
      ),
    ),
  );

  Future<void> _signOut() =>
      widget.onSignOut?.call() ?? FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      final content = switch (_selectedIndex) {
        0 => _DashboardOverview(
          profile: widget.profile,
          updating: _updating,
          onVisibilityChanged: _setVisibility,
          onAvailabilityChanged: _setAvailability,
          onEdit: _editProfile,
        ),
        1 => ProAppointmentsScreen(
          profile: widget.profile,
          repository: _appointmentRepository,
        ),
        _ => _ProfilePreview(profile: widget.profile, onEdit: _editProfile),
      };
      return Scaffold(
        appBar: desktop
            ? null
            : AppBar(
                title: const ProBrand(),
                actions: [
                  IconButton(
                    tooltip: 'Déconnexion',
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
        body: SafeArea(
          child: Row(
            children: [
              if (desktop)
                _DashboardSidebar(
                  selectedIndex: _selectedIndex,
                  profile: widget.profile,
                  onSelected: (value) => setState(() => _selectedIndex = value),
                  onSignOut: _signOut,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 38 : 18,
                    desktop ? 34 : 22,
                    desktop ? 38 : 18,
                    48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: content,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: desktop
            ? null
            : NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) =>
                    setState(() => _selectedIndex = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Tableau de bord',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Rendez-vous',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge_rounded),
                    label: 'Ma fiche',
                  ),
                ],
              ),
      );
    },
  );
}

class _DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final ProviderProfile profile;
  final ValueChanged<int> onSelected;
  final VoidCallback onSignOut;

  const _DashboardSidebar({
    required this.selectedIndex,
    required this.profile,
    required this.onSelected,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 265,
    padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: ProColors.border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProBrand(),
        const SizedBox(height: 42),
        _SidebarItem(
          icon: Icons.dashboard_outlined,
          label: 'Tableau de bord',
          selected: selectedIndex == 0,
          onTap: () => onSelected(0),
        ),
        const SizedBox(height: 8),
        _SidebarItem(
          icon: Icons.calendar_month_outlined,
          label: 'Rendez-vous',
          selected: selectedIndex == 1,
          onTap: () => onSelected(1),
        ),
        const SizedBox(height: 8),
        _SidebarItem(
          icon: Icons.badge_outlined,
          label: 'Ma fiche publique',
          selected: selectedIndex == 2,
          onTap: () => onSelected(2),
        ),
        const Spacer(),
        const Divider(color: ProColors.border),
        const SizedBox(height: 10),
        Row(
          children: [
            InitialsAvatar(name: profile.displayName, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ProColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    profile.accountType.label,
                    style: const TextStyle(
                      color: ProColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Déconnexion',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 20),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? ProColors.primarySoft : Colors.transparent,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? ProColors.primary : ProColors.muted,
              size: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? ProColors.primaryDark : ProColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashboardOverview extends StatelessWidget {
  final ProviderProfile profile;
  final bool updating;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onEdit;

  const _DashboardOverview({
    required this.profile,
    required this.updating,
    required this.onVisibilityChanged,
    required this.onAvailabilityChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${firstName(profile.displayName)}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Voici l’état de votre présence sur i-ENTIER.',
                  style: TextStyle(color: ProColors.muted, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Modifier'),
          ),
        ],
      ),
      const SizedBox(height: 26),
      _VerificationBanner(profile: profile),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760 ? 3 : 1;
          const spacing = 14.0;
          final width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: width,
                child: _MetricCard(
                  icon: Icons.fact_check_outlined,
                  value: '${profile.completionPercent} %',
                  label: 'Profil complété',
                  accent: ProColors.primary,
                ),
              ),
              SizedBox(
                width: width,
                child: _MetricCard(
                  icon: Icons.visibility_outlined,
                  value: profile.isVisible ? 'Visible' : 'Masquée',
                  label: 'Fiche dans l’annuaire',
                  accent: const Color(0xFF6D55C7),
                ),
              ),
              SizedBox(
                width: width,
                child: _MetricCard(
                  icon: Icons.event_available_outlined,
                  value: profile.available ? 'Disponible' : 'Indisponible',
                  label: profile.accountType == ProviderAccountType.professional
                      ? 'Statut patient'
                      : 'Accueil du public',
                  accent: ProColors.success,
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, constraints) {
          final controls = _PresenceControls(
            profile: profile,
            updating: updating,
            onVisibilityChanged: onVisibilityChanged,
            onAvailabilityChanged: onAvailabilityChanged,
          );
          final summary = _ProfileSummary(profile: profile, onEdit: onEdit);
          if (constraints.maxWidth < 760) {
            return Column(
              children: [controls, const SizedBox(height: 16), summary],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: controls),
              const SizedBox(width: 16),
              Expanded(child: summary),
            ],
          );
        },
      ),
    ],
  );
}

class _VerificationBanner extends StatelessWidget {
  final ProviderProfile profile;

  const _VerificationBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final status = profile.verificationStatus;
    final approved = status == ProviderVerificationStatus.approved;
    final rejected = status == ProviderVerificationStatus.rejected;
    final background = approved
        ? const Color(0xFFE7F7EF)
        : rejected
        ? const Color(0xFFFFECE9)
        : const Color(0xFFFFF4DF);
    final color = approved
        ? ProColors.success
        : rejected
        ? const Color(0xFFB42318)
        : const Color(0xFF98610A);
    final icon = approved
        ? Icons.verified_rounded
        : rejected
        ? Icons.error_outline_rounded
        : Icons.hourglass_top_rounded;
    final message = approved
        ? 'Votre identité a été vérifiée. Vous pouvez publier ou masquer votre fiche.'
        : rejected
        ? (profile.rejectionReason.isEmpty
              ? 'Certaines informations doivent être corrigées avant validation.'
              : profile.rejectionReason)
        : 'Votre demande est enregistrée. La fiche restera privée pendant la vérification.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: color, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: ProColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: ProColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PresenceControls extends StatelessWidget {
  final ProviderProfile profile;
  final bool updating;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<bool> onAvailabilityChanged;

  const _PresenceControls({
    required this.profile,
    required this.updating,
    required this.onVisibilityChanged,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contrôler ma présence',
          style: TextStyle(
            color: ProColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Les changements sont appliqués à votre fiche annuaire.',
          style: TextStyle(color: ProColors.muted),
        ),
        const SizedBox(height: 20),
        _ControlSwitch(
          key: const ValueKey('directory-visibility-switch'),
          icon: Icons.travel_explore_outlined,
          title: 'Visible dans l’annuaire',
          subtitle: profile.isApproved
              ? 'Les patients peuvent trouver votre fiche.'
              : 'Disponible après validation du profil.',
          value: profile.isVisible,
          onChanged: profile.isApproved && !updating
              ? onVisibilityChanged
              : null,
        ),
        const Divider(height: 28, color: ProColors.border),
        _ControlSwitch(
          key: const ValueKey('provider-availability-switch'),
          icon: Icons.event_available_outlined,
          title: profile.accountType == ProviderAccountType.professional
              ? 'Disponible pour les patients'
              : 'Ouvert au public',
          subtitle: 'Affiche votre disponibilité actuelle.',
          value: profile.available,
          onChanged: updating ? null : onAvailabilityChanged,
        ),
        if (updating) ...[
          const SizedBox(height: 14),
          const LinearProgressIndicator(color: ProColors.primary),
        ],
      ],
    ),
  );
}

class _ControlSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ControlSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ProColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: ProColors.primary, size: 21),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ProColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: ProColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

class _ProfileSummary extends StatelessWidget {
  final ProviderProfile profile;
  final VoidCallback onEdit;

  const _ProfileSummary({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Résumé de la fiche',
                style: TextStyle(
                  color: ProColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(onPressed: onEdit, child: const Text('Modifier')),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryLine(icon: Icons.badge_outlined, label: profile.displayName),
        _SummaryLine(
          icon: Icons.medical_services_outlined,
          label: profile.category,
        ),
        _SummaryLine(icon: Icons.location_on_outlined, label: profile.address),
        _SummaryLine(icon: Icons.phone_outlined, label: profile.phone),
        _SummaryLine(icon: Icons.schedule_outlined, label: profile.schedule),
      ],
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ProColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label.isEmpty ? 'Non renseigné' : label,
            style: TextStyle(
              color: label.isEmpty ? ProColors.muted : ProColors.ink,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProfilePreview extends StatelessWidget {
  final ProviderProfile profile;
  final VoidCallback onEdit;

  const _ProfilePreview({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ma fiche publique',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Aperçu des informations présentées aux patients.',
                  style: TextStyle(color: ProColors.muted),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Modifier'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      ProPanel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE4F5F5), Color(0xFFF7FBF7)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  InitialsAvatar(name: profile.displayName, size: 72),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: ProColors.ink,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          profile.category,
                          style: const TextStyle(
                            color: ProColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MiniStatus(
                          label: profile.available
                              ? 'Disponible'
                              : 'Indisponible',
                          active: profile.available,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'À propos',
                    style: TextStyle(
                      color: ProColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.description,
                    style: const TextStyle(
                      color: ProColors.muted,
                      height: 1.55,
                    ),
                  ),
                  const Divider(height: 34, color: ProColors.border),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _PreviewInfo(
                        icon: Icons.medical_services_outlined,
                        label: 'Services',
                        value: profile.services,
                      ),
                      _PreviewInfo(
                        icon: Icons.schedule_outlined,
                        label: 'Horaires',
                        value: profile.schedule,
                      ),
                      _PreviewInfo(
                        icon: Icons.location_on_outlined,
                        label: 'Adresse',
                        value: profile.address,
                      ),
                      _PreviewInfo(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: profile.phone,
                      ),
                      _PreviewInfo(
                        icon: Icons.email_outlined,
                        label: 'E-mail',
                        value: profile.email,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PreviewInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PreviewInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 300,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F9F9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ProColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: ProColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? 'Non renseigné' : value,
                style: const TextStyle(
                  color: ProColors.ink,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const InitialsAvatar({super.key, required this.name, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: ProColors.primary,
      borderRadius: BorderRadius.circular(size * .3),
    ),
    child: Text(
      initials(name),
      style: TextStyle(
        color: Colors.white,
        fontSize: size * .28,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _MiniStatus extends StatelessWidget {
  final String label;
  final bool active;

  const _MiniStatus({required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE2F5EC) : const Color(0xFFECEFF1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? ProColors.success : ProColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String firstName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'bienvenue';
  if (<String>{'dr', 'dre', 'dr.'}.contains(parts.first.toLowerCase())) {
    return parts.length > 1 ? '${parts.first} ${parts[1]}' : parts.first;
  }
  return parts.first;
}

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'PRO';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(1, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
