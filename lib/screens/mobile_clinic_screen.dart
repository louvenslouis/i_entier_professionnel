import 'package:flutter/material.dart';

import '../data/mobile_clinic_repository.dart';
import '../models/mobile_clinic.dart';
import '../models/provider_profile.dart';
import '../theme/pro_theme.dart';

enum _ClinicSection { profile, staff, services, tours, appointments, history }

class MobileClinicScreen extends StatefulWidget {
  final ProviderProfile profile;
  final MobileClinicRepository? repository;

  const MobileClinicScreen({super.key, required this.profile, this.repository});

  @override
  State<MobileClinicScreen> createState() => _MobileClinicScreenState();
}

class _MobileClinicScreenState extends State<MobileClinicScreen> {
  late final MobileClinicRepository _repository =
      widget.repository ?? SupabaseMobileClinicRepository();
  String? _selectedClinicId;
  _ClinicSection _section = _ClinicSection.profile;
  bool _saving = false;

  Future<void> _openApplication([MobileClinic? clinic]) async {
    final draft = await showDialog<MobileClinicDraft>(
      context: context,
      builder: (context) => _MobileClinicApplicationDialog(
        profile: widget.profile,
        initial: clinic,
      ),
    );
    if (draft == null) return;
    setState(() => _saving = true);
    try {
      if (clinic == null) {
        await _repository.submitClinic(widget.profile, draft);
      } else {
        await _repository.updateClinic(widget.profile, clinic, draft);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              clinic == null
                  ? 'Demande transmise à l’administration i-ENTIER.'
                  : 'Profil de la clinique mis à jour.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) _showError('La demande n’a pas pu être enregistrée.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setPublication(
    MobileClinic clinic, {
    bool? published,
    bool? deployed,
  }) async {
    setState(() => _saving = true);
    try {
      await _repository.setPublication(
        clinic,
        published: published ?? clinic.isPublished,
        deployed: deployed ?? clinic.isDeployed,
      );
    } catch (_) {
      if (mounted) _showError('Le statut de diffusion n’a pas été modifié.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.isApproved) {
      return const _ClinicLockedPanel();
    }
    return StreamBuilder<List<MobileClinic>>(
      stream: _repository.watchClinics(widget.profile.ownerUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ClinicFeedback(
            icon: Icons.cloud_off_outlined,
            title: 'Cliniques mobiles indisponibles',
            message: 'Vérifiez la connexion et les politiques Supabase.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: ProColors.primary),
          );
        }
        final clinics = snapshot.data!;
        if (clinics.isEmpty) {
          return _ClinicWelcome(onCreate: _saving ? null : _openApplication);
        }
        final selected = clinics.firstWhere(
          (clinic) => clinic.id == _selectedClinicId,
          orElse: () => clinics.first,
        );
        return Column(
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
                        'Clinique Mobile',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Créez et déployez des unités de soins connectées dans les zones difficiles d’accès.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _openApplication(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nouvelle clinique'),
                ),
              ],
            ),
            if (clinics.length > 1) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final clinic in clinics)
                    ChoiceChip(
                      selected: clinic.id == selected.id,
                      label: Text(clinic.name),
                      onSelected: (_) => setState(() {
                        _selectedClinicId = clinic.id;
                        _section = _ClinicSection.profile;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            _ClinicHeader(
              clinic: selected,
              saving: _saving,
              onEdit: () => _openApplication(selected),
              onPublishedChanged: (value) => _setPublication(
                selected,
                published: value,
                deployed: value ? selected.isDeployed : false,
              ),
              onDeployedChanged: (value) => _setPublication(
                selected,
                published: value ? true : selected.isPublished,
                deployed: value,
              ),
            ),
            const SizedBox(height: 18),
            if (!selected.isApproved)
              _ClinicVerificationWorkflow(clinic: selected)
            else ...[
              _ClinicSectionPicker(
                selected: _section,
                onSelected: (value) => setState(() => _section = value),
              ),
              const SizedBox(height: 16),
              _sectionContent(selected),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionContent(MobileClinic clinic) => switch (_section) {
    _ClinicSection.profile => _ClinicProfileSection(
      clinic: clinic,
      onEdit: () => _openApplication(clinic),
    ),
    _ClinicSection.staff => _ClinicStaffSection(
      clinic: clinic,
      repository: _repository,
    ),
    _ClinicSection.services => _ClinicServicesSection(
      clinic: clinic,
      repository: _repository,
    ),
    _ClinicSection.tours => _ClinicToursSection(
      clinic: clinic,
      repository: _repository,
    ),
    _ClinicSection.appointments => _ClinicAppointmentsSection(
      clinic: clinic,
      repository: _repository,
    ),
    _ClinicSection.history => _ClinicHistorySection(
      clinic: clinic,
      profile: widget.profile,
      repository: _repository,
    ),
  };
}

class _ClinicWelcome extends StatelessWidget {
  final VoidCallback? onCreate;

  const _ClinicWelcome({required this.onCreate});

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: ProColors.primarySoft,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: ProColors.primary,
            size: 43,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Déployez une clinique mobile certifiée',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: ProColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: const Text(
            'Soumettez les documents administratifs, obtenez le badge i-ENTIER puis gérez votre équipe, vos services, vos tournées et vos interventions.',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _FeaturePill(icon: Icons.verified_outlined, label: 'Certification'),
            _FeaturePill(icon: Icons.groups_outlined, label: 'Équipe'),
            _FeaturePill(icon: Icons.route_outlined, label: 'Tournées'),
            _FeaturePill(
              icon: Icons.calendar_month_outlined,
              label: 'Rendez-vous',
            ),
          ],
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          key: const ValueKey('create-mobile-clinic'),
          onPressed: onCreate,
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('Soumettre une demande'),
        ),
      ],
    ),
  );
}

class _ClinicLockedPanel extends StatelessWidget {
  const _ClinicLockedPanel();

  @override
  Widget build(BuildContext context) => const _ClinicFeedback(
    icon: Icons.lock_outline_rounded,
    title: 'Profil validé requis',
    message:
        'La création d’une clinique mobile est réservée aux professionnels et institutions de santé approuvés par i-ENTIER.',
  );
}

class _ClinicHeader extends StatelessWidget {
  final MobileClinic clinic;
  final bool saving;
  final VoidCallback onEdit;
  final ValueChanged<bool> onPublishedChanged;
  final ValueChanged<bool> onDeployedChanged;

  const _ClinicHeader({
    required this.clinic,
    required this.saving,
    required this.onEdit,
    required this.onPublishedChanged,
    required this.onDeployedChanged,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: ProColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: ProColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        clinic.name,
                        style: const TextStyle(
                          color: ProColors.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      _ClinicStatusBadge(status: clinic.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('${clinic.creatorType.label} · ${clinic.area}'),
                  if (clinic.isApproved) ...[
                    const SizedBox(height: 9),
                    const _CertifiedBadge(),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Modifier le profil',
              onPressed: saving ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        if (clinic.isApproved) ...[
          const SizedBox(height: 17),
          const Divider(color: ProColors.border),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: clinic.isPublished,
            onChanged: saving ? null : onPublishedChanged,
            title: const Text(
              'Visible dans l’application communautaire',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Les patients peuvent consulter les tournées et réserver.',
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: clinic.isDeployed,
            onChanged: saving ? null : onDeployedChanged,
            title: const Text(
              'Clinique actuellement déployée',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Affiche un signal de disponibilité immédiate à la communauté.',
            ),
          ),
        ],
      ],
    ),
  );
}

class _ClinicVerificationWorkflow extends StatelessWidget {
  final MobileClinic clinic;

  const _ClinicVerificationWorkflow({required this.clinic});

  @override
  Widget build(BuildContext context) {
    final rejected = clinic.status == MobileClinicStatus.rejected;
    return ProPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rejected ? 'Demande à corriger' : 'Processus de certification',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (rejected) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                clinic.rejectionReason.isEmpty
                    ? 'L’administration demande une mise à jour du dossier.'
                    : clinic.rejectionReason,
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _WorkflowStep(
            number: '1',
            title: 'Demande soumise',
            detail: 'Profil et responsable enregistrés',
            state: rejected ? _StepState.warning : _StepState.complete,
          ),
          _WorkflowStep(
            number: '2',
            title: 'Vérification administrative',
            detail: 'Identité, licence, autorisation et documents partenaires',
            state: rejected ? _StepState.warning : _StepState.active,
          ),
          const _WorkflowStep(
            number: '3',
            title: 'Validation i-ENTIER',
            detail: 'Décision d’un administrateur habilité',
            state: _StepState.waiting,
          ),
          const _WorkflowStep(
            number: '4',
            title: 'Badge certifié',
            detail: 'Attribution automatique après approbation',
            state: _StepState.waiting,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _ClinicSectionPicker extends StatelessWidget {
  final _ClinicSection selected;
  final ValueChanged<_ClinicSection> onSelected;

  const _ClinicSectionPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final item in const [
          (_ClinicSection.profile, Icons.storefront_outlined, 'Profil'),
          (_ClinicSection.staff, Icons.groups_outlined, 'Équipe'),
          (
            _ClinicSection.services,
            Icons.medical_services_outlined,
            'Services',
          ),
          (_ClinicSection.tours, Icons.route_outlined, 'Tournées'),
          (
            _ClinicSection.appointments,
            Icons.calendar_month_outlined,
            'Rendez-vous',
          ),
          (_ClinicSection.history, Icons.history_rounded, 'Interventions'),
        ]) ...[
          ChoiceChip(
            showCheckmark: false,
            avatar: Icon(item.$2, size: 18),
            selected: selected == item.$1,
            label: Text(item.$3),
            onSelected: (_) => onSelected(item.$1),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

class _ClinicProfileSection extends StatelessWidget {
  final MobileClinic clinic;
  final VoidCallback onEdit;

  const _ClinicProfileSection({required this.clinic, required this.onEdit});

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Profil de la clinique',
          actionLabel: 'Modifier',
          onAction: onEdit,
        ),
        const SizedBox(height: 16),
        _DataRow(label: 'Responsable', value: clinic.responsibleName),
        _DataRow(label: 'Téléphone', value: clinic.phone),
        _DataRow(label: 'Courriel', value: clinic.email),
        _DataRow(label: 'Adresse de base', value: clinic.baseAddress),
        _DataRow(label: 'Zone', value: clinic.area),
        _DataRow(label: 'Description', value: clinic.description),
        _DataRow(
          label: 'Coordonnées',
          value: clinic.latitude == null
              ? 'Non renseignées'
              : '${clinic.latitude}, ${clinic.longitude}',
        ),
      ],
    ),
  );
}

class _ClinicStaffSection extends StatelessWidget {
  final MobileClinic clinic;
  final MobileClinicRepository repository;

  const _ClinicStaffSection({required this.clinic, required this.repository});

  Future<void> _add(BuildContext context) async {
    final result = await showDialog<(String, String, String, String)>(
      context: context,
      builder: (_) => const _StaffDialog(),
    );
    if (result == null) return;
    try {
      await repository.addStaffMember(
        clinicId: clinic.id,
        fullName: result.$1,
        profession: result.$2,
        licenseNumber: result.$3,
        documentUrl: result.$4,
      );
    } catch (_) {
      if (context.mounted) _error(context);
    }
  }

  @override
  Widget build(BuildContext context) =>
      _CollectionPanel<MobileClinicStaffMember>(
        title: 'Professionnels de santé',
        emptyMessage: 'Ajoutez les membres qui participeront aux tournées.',
        stream: repository.watchStaff(clinic.id),
        onAdd: () => _add(context),
        itemBuilder: (member) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: ProColors.primarySoft,
            child: Icon(Icons.person_outline_rounded, color: ProColors.primary),
          ),
          title: Text(
            member.fullName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            member.licenseNumber.isEmpty
                ? member.profession
                : '${member.profession} · Licence ${member.licenseNumber}',
          ),
          trailing: Icon(
            member.active
                ? Icons.check_circle_rounded
                : Icons.pause_circle_outline,
            color: member.active ? ProColors.success : ProColors.muted,
          ),
        ),
      );
}

class _ClinicServicesSection extends StatelessWidget {
  final MobileClinic clinic;
  final MobileClinicRepository repository;

  const _ClinicServicesSection({
    required this.clinic,
    required this.repository,
  });

  Future<void> _add(BuildContext context) async {
    final result = await showDialog<(String, String, int, double?)>(
      context: context,
      builder: (_) => const _ServiceDialog(),
    );
    if (result == null) return;
    try {
      await repository.addService(
        clinicId: clinic.id,
        name: result.$1,
        description: result.$2,
        durationMinutes: result.$3,
        priceHtg: result.$4,
      );
    } catch (_) {
      if (context.mounted) _error(context);
    }
  }

  @override
  Widget build(BuildContext context) => _CollectionPanel<MobileClinicService>(
    title: 'Services disponibles',
    emptyMessage: 'Publiez les soins proposés pendant les tournées.',
    stream: repository.watchServices(clinic.id),
    onAdd: () => _add(context),
    itemBuilder: (service) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: ProColors.primarySoft,
        child: Icon(Icons.medical_services_outlined, color: ProColors.primary),
      ),
      title: Text(
        service.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${service.durationMinutes} min${service.description.isEmpty ? '' : ' · ${service.description}'}',
      ),
      trailing: service.priceHtg == null
          ? null
          : Text(
              '${service.priceHtg!.toStringAsFixed(0)} HTG',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
    ),
  );
}

class _ClinicToursSection extends StatelessWidget {
  final MobileClinic clinic;
  final MobileClinicRepository repository;

  const _ClinicToursSection({required this.clinic, required this.repository});

  Future<void> _add(BuildContext context) async {
    final draft = await showDialog<_TourDraft>(
      context: context,
      builder: (_) => _TourDialog(clinic: clinic),
    );
    if (draft == null) return;
    try {
      await repository.addTour(
        clinicId: clinic.id,
        zoneName: draft.zoneName,
        locationLabel: draft.locationLabel,
        department: draft.department,
        commune: draft.commune,
        latitude: draft.latitude,
        longitude: draft.longitude,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        dailySchedule: draft.dailySchedule,
        notes: draft.notes,
      );
    } catch (_) {
      if (context.mounted) _error(context);
    }
  }

  @override
  Widget build(BuildContext context) => _CollectionPanel<MobileClinicTour>(
    title: 'Planification des tournées',
    emptyMessage: 'Planifiez le premier passage de cette clinique mobile.',
    stream: repository.watchTours(clinic.id),
    onAdd: () => _add(context),
    itemBuilder: (tour) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: ProColors.primarySoft,
        child: Icon(Icons.route_outlined, color: ProColors.primary),
      ),
      title: Text(
        tour.zoneName,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${_date(tour.startsAt)} – ${_date(tour.endsAt)}\n${tour.locationLabel} · ${tour.dailySchedule}',
      ),
      isThreeLine: true,
      trailing: _TourStatus(status: tour.status),
    ),
  );
}

class _ClinicAppointmentsSection extends StatelessWidget {
  final MobileClinic clinic;
  final MobileClinicRepository repository;

  const _ClinicAppointmentsSection({
    required this.clinic,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Rendez-vous de la clinique'),
        const SizedBox(height: 6),
        const Text(
          'Ces demandes apparaissent aussi dans la section Rendez-vous principale, où vous pouvez les confirmer ou les refuser.',
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<MobileClinicAppointment>>(
          stream: repository.watchAppointments(clinic.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Synchronisation impossible.');
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) {
              return const _EmptyLine('Aucune réservation communautaire.');
            }
            return Column(
              children: [
                for (final appointment in snapshot.data!)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: ProColors.primarySoft,
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: ProColors.primary,
                      ),
                    ),
                    title: Text(
                      appointment.patientName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${appointment.serviceName}\n${_dateTime(appointment.scheduledAt)} · ${appointment.location}',
                    ),
                    isThreeLine: true,
                    trailing: _AppointmentStatus(status: appointment.status),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _ClinicHistorySection extends StatelessWidget {
  final MobileClinic clinic;
  final ProviderProfile profile;
  final MobileClinicRepository repository;

  const _ClinicHistorySection({
    required this.clinic,
    required this.profile,
    required this.repository,
  });

  Future<void> _add(BuildContext context) async {
    final result = await showDialog<(String, DateTime, int, String)>(
      context: context,
      builder: (_) => const _InterventionDialog(),
    );
    if (result == null) return;
    try {
      await repository.recordIntervention(
        clinicId: clinic.id,
        serviceName: result.$1,
        interventionAt: result.$2,
        beneficiariesCount: result.$3,
        notes: result.$4,
        createdBy: profile.ownerUid,
      );
    } catch (_) {
      if (context.mounted) _error(context);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => _CollectionPanel<MobileClinicIntervention>(
    title: 'Historique des interventions',
    emptyMessage: 'Consignez les actions réalisées et leurs bénéficiaires.',
    stream: repository.watchInterventions(clinic.id),
    onAdd: () => _add(context),
    itemBuilder: (intervention) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: ProColors.primarySoft,
        child: Icon(Icons.history_rounded, color: ProColors.primary),
      ),
      title: Text(
        intervention.serviceName,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${_dateTime(intervention.interventionAt)}${intervention.notes.isEmpty ? '' : '\n${intervention.notes}'}',
      ),
      trailing: Text(
        '${intervention.beneficiariesCount}\nbénéficiaire${intervention.beneficiariesCount > 1 ? 's' : ''}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _CollectionPanel<T> extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final Stream<List<T>> stream;
  final VoidCallback onAdd;
  final Widget Function(T item) itemBuilder;

  const _CollectionPanel({
    required this.title,
    required this.emptyMessage,
    required this.stream,
    required this.onAdd,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, actionLabel: 'Ajouter', onAction: onAdd),
        const SizedBox(height: 12),
        StreamBuilder<List<T>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Synchronisation impossible.');
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) return _EmptyLine(emptyMessage);
            return Column(children: snapshot.data!.map(itemBuilder).toList());
          },
        ),
      ],
    ),
  );
}

class _MobileClinicApplicationDialog extends StatefulWidget {
  final ProviderProfile profile;
  final MobileClinic? initial;

  const _MobileClinicApplicationDialog({required this.profile, this.initial});

  @override
  State<_MobileClinicApplicationDialog> createState() =>
      _MobileClinicApplicationDialogState();
}

class _MobileClinicApplicationDialogState
    extends State<_MobileClinicApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  late MobileClinicCreatorType _creatorType;
  late final Map<String, TextEditingController> _fields;

  List<MobileClinicCreatorType> get _allowedTypes => MobileClinicCreatorType
      .values
      .where(
        (type) =>
            type.isProfessional ==
            (widget.profile.accountType == ProviderAccountType.professional),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _creatorType = initial?.creatorType ?? _allowedTypes.first;
    _fields = {
      'name': TextEditingController(text: initial?.name ?? ''),
      'responsible': TextEditingController(
        text: initial?.responsibleName ?? widget.profile.displayName,
      ),
      'phone': TextEditingController(
        text: initial?.phone ?? widget.profile.phone,
      ),
      'email': TextEditingController(
        text: initial?.email ?? widget.profile.email,
      ),
      'description': TextEditingController(text: initial?.description ?? ''),
      'address': TextEditingController(
        text: initial?.baseAddress ?? widget.profile.address,
      ),
      'department': TextEditingController(text: initial?.department ?? ''),
      'commune': TextEditingController(text: initial?.commune ?? ''),
      'latitude': TextEditingController(
        text: initial?.latitude?.toString() ?? '',
      ),
      'longitude': TextEditingController(
        text: initial?.longitude?.toString() ?? '',
      ),
      'identity': TextEditingController(
        text: initial?.identityDocumentUrl ?? '',
      ),
      'license': TextEditingController(
        text: initial?.professionalLicenseUrl ?? '',
      ),
      'authorization': TextEditingController(
        text: initial?.operatingAuthorizationUrl ?? '',
      ),
      'partners': TextEditingController(
        text: initial?.partnerDocumentUrls.join('\n') ?? '',
      ),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      MobileClinicDraft(
        creatorType: _creatorType,
        name: _fields['name']!.text,
        responsibleName: _fields['responsible']!.text,
        phone: _fields['phone']!.text,
        email: _fields['email']!.text,
        description: _fields['description']!.text,
        baseAddress: _fields['address']!.text,
        department: _fields['department']!.text,
        commune: _fields['commune']!.text,
        latitude: double.tryParse(_fields['latitude']!.text.trim()),
        longitude: double.tryParse(_fields['longitude']!.text.trim()),
        identityDocumentUrl: _fields['identity']!.text,
        professionalLicenseUrl: _fields['license']!.text,
        operatingAuthorizationUrl: _fields['authorization']!.text,
        partnerDocumentUrls: _fields['partners']!.text
            .split('\n')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initial == null
          ? 'Demande de Clinique Mobile'
          : 'Modifier la clinique',
    ),
    content: SizedBox(
      width: 720,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FormHeading('Identité et profil'),
              const SizedBox(height: 10),
              DropdownButtonFormField<MobileClinicCreatorType>(
                initialValue: _creatorType,
                decoration: const InputDecoration(
                  labelText: 'Type de créateur',
                ),
                items: [
                  for (final type in _allowedTypes)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: widget.initial == null
                    ? (value) => setState(() => _creatorType = value!)
                    : null,
              ),
              const SizedBox(height: 10),
              _RequiredField(
                controller: _fields['name']!,
                label: 'Nom de la clinique',
              ),
              const SizedBox(height: 10),
              _RequiredField(
                controller: _fields['responsible']!,
                label: 'Responsable',
              ),
              const SizedBox(height: 10),
              _RequiredField(controller: _fields['phone']!, label: 'Téléphone'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fields['email'],
                decoration: const InputDecoration(labelText: 'Courriel'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fields['description'],
                minLines: 3,
                maxLines: 5,
                maxLength: 1200,
                decoration: const InputDecoration(
                  labelText: 'Mission et description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              const _FormHeading('Zone et localisation'),
              const SizedBox(height: 10),
              _RequiredField(
                controller: _fields['address']!,
                label: 'Adresse de base',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _RequiredField(
                      controller: _fields['department']!,
                      label: 'Département',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RequiredField(
                      controller: _fields['commune']!,
                      label: 'Commune',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fields['latitude'],
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _fields['longitude'],
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _FormHeading('Documents de vérification'),
              const SizedBox(height: 5),
              const Text(
                'Ajoutez des liens sécurisés vers les documents PDF ou images.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              _DocumentField(
                controller: _fields['identity']!,
                label: 'Pièce d’identité du responsable *',
              ),
              const SizedBox(height: 10),
              if (_creatorType.isProfessional) ...[
                _DocumentField(
                  controller: _fields['license']!,
                  label: 'Diplôme ou licence professionnelle *',
                ),
                const SizedBox(height: 10),
              ],
              _DocumentField(
                controller: _fields['authorization']!,
                label: 'Autorisation de fonctionnement *',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fields['partners'],
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Documents des partenaires',
                  hintText: 'Un lien par ligne',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        key: const ValueKey('submit-mobile-clinic-application'),
        onPressed: _submit,
        child: Text(widget.initial == null ? 'Soumettre' : 'Enregistrer'),
      ),
    ],
  );
}

class _StaffDialog extends StatefulWidget {
  const _StaffDialog();
  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _profession = TextEditingController();
  final _license = TextEditingController();
  final _document = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _profession.dispose();
    _license.dispose();
    _document.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ajouter un professionnel'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RequiredField(controller: _name, label: 'Nom complet'),
            const SizedBox(height: 10),
            _RequiredField(controller: _profession, label: 'Profession'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _license,
              decoration: const InputDecoration(labelText: 'Numéro de licence'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _document,
              decoration: const InputDecoration(labelText: 'Lien du document'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() == true) {
            Navigator.pop(context, (
              _name.text,
              _profession.text,
              _license.text,
              _document.text,
            ));
          }
        },
        child: const Text('Ajouter'),
      ),
    ],
  );
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog();
  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _duration = TextEditingController(text: '30');
  final _price = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ajouter un service'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RequiredField(controller: _name, label: 'Nom du service'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _duration,
                    decoration: const InputDecoration(labelText: 'Durée (min)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      return number == null || number < 10 || number > 480
                          ? '10 à 480 min'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Prix HTG'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() == true) {
            Navigator.pop(context, (
              _name.text,
              _description.text,
              int.parse(_duration.text),
              double.tryParse(_price.text),
            ));
          }
        },
        child: const Text('Ajouter'),
      ),
    ],
  );
}

class _TourDraft {
  final String zoneName;
  final String locationLabel;
  final String department;
  final String commune;
  final double? latitude;
  final double? longitude;
  final DateTime startsAt;
  final DateTime endsAt;
  final String dailySchedule;
  final String notes;

  const _TourDraft({
    required this.zoneName,
    required this.locationLabel,
    required this.department,
    required this.commune,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.endsAt,
    required this.dailySchedule,
    required this.notes,
  });
}

class _TourDialog extends StatefulWidget {
  final MobileClinic clinic;
  const _TourDialog({required this.clinic});
  @override
  State<_TourDialog> createState() => _TourDialogState();
}

class _TourDialogState extends State<_TourDialog> {
  final _formKey = GlobalKey<FormState>();
  final _zone = TextEditingController();
  final _location = TextEditingController();
  late final _department = TextEditingController(
    text: widget.clinic.department,
  );
  late final _commune = TextEditingController(text: widget.clinic.commune);
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _schedule = TextEditingController(text: 'Tous les jours 08h-16h');
  final _notes = TextEditingController();
  late DateTime _start = DateTime.now().add(const Duration(days: 7));
  late DateTime _end = _start.add(const Duration(days: 2));

  @override
  void dispose() {
    for (final controller in [
      _zone,
      _location,
      _department,
      _commune,
      _latitude,
      _longitude,
      _schedule,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final initial = start ? _start : _end;
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _start = DateTime(value.year, value.month, value.day, 8);
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(days: 1));
      } else {
        _end = DateTime(value.year, value.month, value.day, 17);
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Planifier une tournée'),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _RequiredField(controller: _zone, label: 'Nom de la zone'),
              const SizedBox(height: 10),
              _RequiredField(controller: _location, label: 'Lieu précis'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _RequiredField(
                      controller: _department,
                      label: 'Département',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RequiredField(
                      controller: _commune,
                      label: 'Commune',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitude,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _longitude,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.event_outlined),
                      label: Text('Début · ${_date(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text('Fin · ${_date(_end)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _RequiredField(
                controller: _schedule,
                label: 'Horaires quotidiens',
                hint: 'Tous les jours 08h-16h',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes logistiques',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() != true) return;
          if (!_end.isAfter(_start)) return;
          Navigator.pop(
            context,
            _TourDraft(
              zoneName: _zone.text,
              locationLabel: _location.text,
              department: _department.text,
              commune: _commune.text,
              latitude: double.tryParse(_latitude.text),
              longitude: double.tryParse(_longitude.text),
              startsAt: _start,
              endsAt: _end,
              dailySchedule: _schedule.text,
              notes: _notes.text,
            ),
          );
        },
        child: const Text('Planifier'),
      ),
    ],
  );
}

class _InterventionDialog extends StatefulWidget {
  const _InterventionDialog();
  @override
  State<_InterventionDialog> createState() => _InterventionDialogState();
}

class _InterventionDialogState extends State<_InterventionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = TextEditingController();
  final _beneficiaries = TextEditingController(text: '1');
  final _notes = TextEditingController();
  DateTime _dateValue = DateTime.now();

  @override
  void dispose() {
    _service.dispose();
    _beneficiaries.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Consigner une intervention'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RequiredField(controller: _service, label: 'Service réalisé'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _beneficiaries,
              decoration: const InputDecoration(labelText: 'Bénéficiaires'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final number = int.tryParse(value ?? '');
                return number == null || number < 1 ? 'Valeur requise' : null;
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final value = await showDatePicker(
                  context: context,
                  initialDate: _dateValue,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (value != null) setState(() => _dateValue = value);
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(_date(_dateValue)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() == true) {
            Navigator.pop(context, (
              _service.text,
              _dateValue,
              int.parse(_beneficiaries.text),
              _notes.text,
            ));
          }
        },
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

class _RequiredField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  const _RequiredField({
    required this.controller,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: '$label *', hintText: hint),
    validator: (value) => value == null || value.trim().length < 2
        ? 'Ce champ est requis.'
        : null,
  );
}

class _DocumentField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DocumentField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: 'https://documents.exemple.ht/...',
      prefixIcon: const Icon(Icons.attach_file_rounded),
    ),
    keyboardType: TextInputType.url,
    validator: (value) {
      final uri = Uri.tryParse(value?.trim() ?? '');
      return uri == null || !uri.hasScheme || !uri.hasAuthority
          ? 'Ajoutez un lien valide.'
          : null;
    },
  );
}

class _FormHeading extends StatelessWidget {
  final String text;
  const _FormHeading(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ProColors.primaryDark,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({this.title = '', this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (actionLabel != null)
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(actionLabel!),
        ),
    ],
  );
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              color: ProColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: ProColors.primarySoft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ProColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: ProColors.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CertifiedBadge extends StatelessWidget {
  const _CertifiedBadge();
  @override
  Widget build(BuildContext context) => const _FeaturePill(
    icon: Icons.verified_rounded,
    label: 'Clinique Mobile Certifiée I-Entier',
  );
}

class _ClinicStatusBadge extends StatelessWidget {
  final MobileClinicStatus status;
  const _ClinicStatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MobileClinicStatus.approved => ProColors.success,
      MobileClinicStatus.rejected => const Color(0xFFC2410C),
      MobileClinicStatus.pending => const Color(0xFFB56A00),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

enum _StepState { complete, active, warning, waiting }

class _WorkflowStep extends StatelessWidget {
  final String number;
  final String title;
  final String detail;
  final _StepState state;
  final bool last;

  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.detail,
    required this.state,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.complete => ProColors.success,
      _StepState.active => ProColors.primary,
      _StepState.warning => const Color(0xFFC2410C),
      _StepState.waiting => ProColors.muted,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: state == _StepState.complete
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 17,
                        )
                      : Text(
                          number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: ProColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourStatus extends StatelessWidget {
  final String status;
  const _TourStatus({required this.status});
  @override
  Widget build(BuildContext context) => Text(
    switch (status) {
      'active' => 'En cours',
      'completed' => 'Terminée',
      'cancelled' => 'Annulée',
      _ => 'Planifiée',
    },
    style: const TextStyle(
      color: ProColors.primary,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _AppointmentStatus extends StatelessWidget {
  final String status;
  const _AppointmentStatus({required this.status});
  @override
  Widget build(BuildContext context) => Text(
    switch (status) {
      'confirmed' => 'Confirmé',
      'cancelled' => 'Annulé',
      _ => 'En attente',
    },
    style: TextStyle(
      color: status == 'confirmed' ? ProColors.success : ProColors.primary,
      fontSize: 11,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _EmptyLine extends StatelessWidget {
  final String message;
  const _EmptyLine(this.message);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: ProColors.canvas,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, textAlign: TextAlign.center),
  );
}

class _ClinicFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _ClinicFeedback({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      children: [
        Icon(icon, color: ProColors.primary, size: 42),
        const SizedBox(height: 13),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

void _error(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('L’opération n’a pas pu être enregistrée.')),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTime(DateTime value) =>
    '${_date(value)} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
