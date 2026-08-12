import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/traditional_medicine_repository.dart';
import '../models/provider_profile.dart';
import '../models/traditional_medicine.dart';
import '../theme/pro_theme.dart';

typedef TraditionalDocumentPicker =
    Future<PickedTraditionalDocument?> Function(String documentType);

class TraditionalMedicineProfessionalScreen extends StatefulWidget {
  final ProviderProfile profile;
  final TraditionalMedicineProfessionalRepository repository;
  final TraditionalDocumentPicker? documentPicker;

  const TraditionalMedicineProfessionalScreen({
    super.key,
    required this.profile,
    required this.repository,
    this.documentPicker,
  });

  @override
  State<TraditionalMedicineProfessionalScreen> createState() =>
      _TraditionalMedicineProfessionalScreenState();
}

class _TraditionalMedicineProfessionalScreenState
    extends State<TraditionalMedicineProfessionalScreen> {
  late final Stream<TraditionalPractitionerApplication?> _application = widget
      .repository
      .watchApplication(widget.profile.ownerUid);
  bool _busy = false;

  Future<PickedTraditionalDocument?> _pickDocument(String type) async {
    if (widget.documentPicker != null) return widget.documentPicker!(type);
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (image == null) return null;
    final extension = image.name.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    return PickedTraditionalDocument(
      fileName: image.name,
      mimeType: mime,
      bytes: await image.readAsBytes(),
    );
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La modification n’a pas été enregistrée.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<TraditionalPractitionerApplication?>(
        stream: _application,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ProColors.primary),
            );
          }
          if (snapshot.hasError) {
            return const _ProFeedback(
              icon: Icons.cloud_off_outlined,
              title: 'Service momentanément indisponible',
              message: 'Réessayez dans quelques instants.',
            );
          }
          final application = snapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TraditionalHeader(),
              const SizedBox(height: 20),
              if (application == null)
                _EnrollmentForm(busy: _busy, onSubmit: _submitEnrollment)
              else ...[
                _StatusPanel(
                  application: application,
                  busy: _busy,
                  onAvailabilityChanged: application.isApproved
                      ? (value) => _run(
                          () => widget.repository.setOnlineAvailability(
                            widget.profile.ownerUid,
                            value,
                          ),
                          value
                              ? 'Vous êtes maintenant disponible.'
                              : 'Vous êtes maintenant hors ligne.',
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                _DocumentsPanel(
                  providerId: widget.profile.ownerUid,
                  repository: widget.repository,
                  busy: _busy,
                  onAdd: _addDocument,
                ),
                if (!application.isApproved && !application.isSuspended) ...[
                  const SizedBox(height: 16),
                  _EnrollmentForm(
                    application: application,
                    busy: _busy,
                    onSubmit: _updateEnrollment,
                  ),
                ],
                if (application.isApproved) ...[
                  const SizedBox(height: 20),
                  _CareTools(
                    providerId: widget.profile.ownerUid,
                    repository: widget.repository,
                    busy: _busy,
                    onRun: _run,
                  ),
                ],
              ],
            ],
          );
        },
      );

  Future<void> _submitEnrollment(_EnrollmentDraft draft) => _run(() async {
    await widget.repository.submitApplication(
      providerId: widget.profile.ownerUid,
      experienceYears: draft.experienceYears,
      practiceDomains: draft.practiceDomains,
      languages: draft.languages,
      interventionZones: draft.interventionZones,
    );
    final identity = await _pickDocument('identity');
    if (identity != null) {
      await widget.repository.uploadDocument(
        providerId: widget.profile.ownerUid,
        documentType: 'identity',
        document: identity,
      );
    }
    final attestation = await _pickDocument('attestation');
    if (attestation != null) {
      await widget.repository.uploadDocument(
        providerId: widget.profile.ownerUid,
        documentType: 'attestation',
        document: attestation,
      );
    }
  }, 'Dossier transmis à l’équipe I-Entier.');

  Future<void> _updateEnrollment(_EnrollmentDraft draft) => _run(
    () => widget.repository.submitApplication(
      providerId: widget.profile.ownerUid,
      experienceYears: draft.experienceYears,
      practiceDomains: draft.practiceDomains,
      languages: draft.languages,
      interventionZones: draft.interventionZones,
    ),
    'Informations professionnelles mises à jour.',
  );

  Future<void> _addDocument(String type) async {
    final document = await _pickDocument(type);
    if (document == null) return;
    await _run(
      () => widget.repository.uploadDocument(
        providerId: widget.profile.ownerUid,
        documentType: type,
        document: document,
      ),
      'Justificatif ajouté au dossier.',
    );
  }
}

class _TraditionalHeader extends StatelessWidget {
  const _TraditionalHeader();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0E5A49), Color(0xFF18856A)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 29,
          backgroundColor: Color(0x26FFFFFF),
          child: Icon(Icons.spa_rounded, color: Colors.white, size: 31),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I-Entier Médecine Traditionnelle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Créez votre registre vérifié, accompagnez la prévention et orientez sans délai vers le réseau de santé.',
                style: TextStyle(color: Color(0xFFD7F4EA), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EnrollmentDraft {
  final int experienceYears;
  final List<String> practiceDomains;
  final List<String> languages;
  final List<String> interventionZones;

  const _EnrollmentDraft({
    required this.experienceYears,
    required this.practiceDomains,
    required this.languages,
    required this.interventionZones,
  });
}

class _EnrollmentForm extends StatefulWidget {
  final TraditionalPractitionerApplication? application;
  final bool busy;
  final ValueChanged<_EnrollmentDraft> onSubmit;

  const _EnrollmentForm({
    this.application,
    required this.busy,
    required this.onSubmit,
  });

  @override
  State<_EnrollmentForm> createState() => _EnrollmentFormState();
}

class _EnrollmentFormState extends State<_EnrollmentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _experience = TextEditingController(
    text: widget.application?.experienceYears.toString() ?? '',
  );
  late final TextEditingController _domains = TextEditingController(
    text: widget.application?.practiceDomains.join(', ') ?? '',
  );
  late final TextEditingController _languages = TextEditingController(
    text: widget.application?.languages.join(', ') ?? 'Créole haïtien',
  );
  late final TextEditingController _zones = TextEditingController(
    text: widget.application?.interventionZones.join(', ') ?? '',
  );
  bool _scopeAccepted = false;

  List<String> _list(TextEditingController controller) => controller.text
      .split(RegExp(r'[,;\n]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  @override
  void dispose() {
    _experience.dispose();
    _domains.dispose();
    _languages.dispose();
    _zones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.application == null
                ? 'Rejoindre le registre sécurisé'
                : 'Mettre à jour mon dossier',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Vos informations et justificatifs seront examinés avant toute publication.',
            style: TextStyle(color: ProColors.muted),
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey('traditional-pro-experience'),
            controller: _experience,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Années d’expérience'),
            validator: (value) {
              final years = int.tryParse(value?.trim() ?? '');
              return years == null || years < 0 || years > 80
                  ? 'Entrez un nombre entre 0 et 80.'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('traditional-pro-domains'),
            controller: _domains,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Domaines de pratique',
              hintText: 'Prévention, massages, plantes, accompagnement…',
            ),
            validator: (value) =>
                _list(_domains).isEmpty ? 'Ajoutez au moins un domaine.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('traditional-pro-languages'),
            controller: _languages,
            decoration: const InputDecoration(
              labelText: 'Langues parlées',
              hintText: 'Créole haïtien, Français',
            ),
            validator: (value) => _list(_languages).isEmpty
                ? 'Ajoutez au moins une langue.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('traditional-pro-zones'),
            controller: _zones,
            decoration: const InputDecoration(
              labelText: 'Zones d’intervention',
              hintText: 'Port-au-Prince, Delmas…',
            ),
            validator: (value) =>
                _list(_zones).isEmpty ? 'Ajoutez au moins une zone.' : null,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            key: const ValueKey('traditional-pro-scope'),
            contentPadding: EdgeInsets.zero,
            value: _scopeAccepted,
            onChanged: (value) =>
                setState(() => _scopeAccepted = value == true),
            title: const Text(
              'Je m’engage à ne poser aucun diagnostic médical et à ne prescrire aucun médicament.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('traditional-pro-submit'),
            onPressed: widget.busy
                ? null
                : () {
                    if (_formKey.currentState?.validate() != true) return;
                    if (!_scopeAccepted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Confirmez les règles de sécurité.'),
                        ),
                      );
                      return;
                    }
                    widget.onSubmit(
                      _EnrollmentDraft(
                        experienceYears: int.parse(_experience.text.trim()),
                        practiceDomains: _list(_domains),
                        languages: _list(_languages),
                        interventionZones: _list(_zones),
                      ),
                    );
                  },
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(
              widget.application == null
                  ? 'Soumettre avec mes justificatifs'
                  : 'Enregistrer les modifications',
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusPanel extends StatelessWidget {
  final TraditionalPractitionerApplication application;
  final bool busy;
  final ValueChanged<bool>? onAvailabilityChanged;

  const _StatusPanel({
    required this.application,
    required this.busy,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (application.validationStatus) {
      'approved' => ProColors.success,
      'rejected' || 'suspended' => const Color(0xFFC9362B),
      _ => const Color(0xFFB66A06),
    };
    return ProPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: color, size: 29),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.statusLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Identité : ${application.identityStatus} • Attestations : ${application.attestationStatus}',
                      style: const TextStyle(color: ProColors.muted),
                    ),
                  ],
                ),
              ),
              if (application.isApproved)
                Text(
                  '${application.trustScore}/100',
                  style: const TextStyle(
                    color: ProColors.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          if (application.reviewReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(application.reviewReason, style: TextStyle(color: color)),
          ],
          if (application.isApproved) ...[
            const Divider(height: 30),
            SwitchListTile.adaptive(
              key: const ValueKey('traditional-pro-availability'),
              contentPadding: EdgeInsets.zero,
              value: application.onlineAvailable,
              onChanged: busy ? null : onAvailabilityChanged,
              title: const Text(
                'Disponibilité en temps réel',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'Les patients voient immédiatement votre statut.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentsPanel extends StatelessWidget {
  final String providerId;
  final TraditionalMedicineProfessionalRepository repository;
  final bool busy;
  final ValueChanged<String> onAdd;

  const _DocumentsPanel({
    required this.providerId,
    required this.repository,
    required this.busy,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Identité et attestations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            PopupMenuButton<String>(
              key: const ValueKey('traditional-pro-add-document'),
              enabled: !busy,
              onSelected: onAdd,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'identity',
                  child: Text('Pièce d’identité'),
                ),
                PopupMenuItem(value: 'attestation', child: Text('Attestation')),
                PopupMenuItem(value: 'training', child: Text('Formation')),
              ],
              child: const Chip(
                avatar: Icon(Icons.add_rounded, size: 18),
                label: Text('Ajouter'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<TraditionalPractitionerDocument>>(
          stream: repository.watchDocuments(providerId),
          builder: (context, snapshot) {
            final documents = snapshot.data ?? const [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (documents.isEmpty) {
              return const Text(
                'Ajoutez une pièce d’identité et au moins une attestation.',
                style: TextStyle(color: ProColors.muted),
              );
            }
            return Column(
              children: documents
                  .map(
                    (document) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(document.fileName),
                      subtitle: Text(
                        '${document.type} • ${document.reviewStatus}',
                      ),
                      trailing: Icon(
                        document.reviewStatus == 'verified'
                            ? Icons.verified_rounded
                            : document.reviewStatus == 'rejected'
                            ? Icons.error_outline
                            : Icons.schedule_rounded,
                        color: document.reviewStatus == 'verified'
                            ? ProColors.success
                            : document.reviewStatus == 'rejected'
                            ? const Color(0xFFC9362B)
                            : const Color(0xFFB66A06),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    ),
  );
}

class _CareTools extends StatelessWidget {
  final String providerId;
  final TraditionalMedicineProfessionalRepository repository;
  final bool busy;
  final Future<void> Function(Future<void> Function(), String) onRun;

  const _CareTools({
    required this.providerId,
    required this.repository,
    required this.busy,
    required this.onRun,
  });

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<TraditionalCarePatient>>(
    stream: repository.watchCarePatients(providerId),
    builder: (context, snapshot) {
      final patients = snapshot.data ?? const [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accompagnement sécurisé',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Conseils de prévention, suivi périodique et orientation vers le réseau clinique.',
            style: TextStyle(color: ProColors.muted),
          ),
          const SizedBox(height: 16),
          if (patients.isEmpty)
            const _ProFeedback(
              icon: Icons.people_outline,
              title: 'Aucun patient accompagné',
              message:
                  'Les patients ayant demandé une consultation apparaîtront ici.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: 470,
                  child: _RecommendationPanel(
                    providerId: providerId,
                    patients: patients,
                    repository: repository,
                    busy: busy,
                    onRun: onRun,
                  ),
                ),
                SizedBox(
                  width: 470,
                  child: _OrientationPanel(
                    providerId: providerId,
                    patients: patients,
                    repository: repository,
                    busy: busy,
                    onRun: onRun,
                  ),
                ),
              ],
            ),
        ],
      );
    },
  );
}

class _RecommendationPanel extends StatefulWidget {
  final String providerId;
  final List<TraditionalCarePatient> patients;
  final TraditionalMedicineProfessionalRepository repository;
  final bool busy;
  final Future<void> Function(Future<void> Function(), String) onRun;

  const _RecommendationPanel({
    required this.providerId,
    required this.patients,
    required this.repository,
    required this.busy,
    required this.onRun,
  });
  @override
  State<_RecommendationPanel> createState() => _RecommendationPanelState();
}

class _RecommendationPanelState extends State<_RecommendationPanel> {
  late String _patientId = widget.patients.first.id;
  final _title = TextEditingController();
  final _content = TextEditingController();
  String _type = 'prevention';
  DateTime? _reminderAt;
  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conseil & rappel',
          style: TextStyle(
            color: ProColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _patientId,
          decoration: const InputDecoration(labelText: 'Patient'),
          items: widget.patients
              .map(
                (patient) => DropdownMenuItem(
                  value: patient.id,
                  child: Text(patient.name),
                ),
              )
              .toList(),
          onChanged: (value) => _patientId = value ?? _patientId,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: const [
            DropdownMenuItem(value: 'prevention', child: Text('Prévention')),
            DropdownMenuItem(value: 'wellbeing', child: Text('Bien-être')),
            DropdownMenuItem(
              value: 'follow_up',
              child: Text('Suivi périodique'),
            ),
            DropdownMenuItem(value: 'hygiene', child: Text('Hygiène')),
          ],
          onChanged: (value) => _type = value ?? _type,
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('traditional-pro-recommendation-title'),
          controller: _title,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Titre'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('traditional-pro-recommendation-content'),
          controller: _content,
          onChanged: (_) => setState(() {}),
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Conseil de prévention',
            alignLabelWithHint: true,
          ),
        ),
        SwitchListTile.adaptive(
          key: const ValueKey('traditional-pro-reminder-toggle'),
          contentPadding: EdgeInsets.zero,
          value: _reminderAt != null,
          onChanged: (value) => setState(
            () => _reminderAt = value
                ? DateTime.now().add(const Duration(days: 7))
                : null,
          ),
          title: const Text(
            'Ajouter un rappel personnalisé',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: _reminderAt == null
              ? const Text('Le patient recevra le conseil immédiatement.')
              : Text(
                  'Rappel le ${_reminderAt!.day.toString().padLeft(2, '0')}/'
                  '${_reminderAt!.month.toString().padLeft(2, '0')}/'
                  '${_reminderAt!.year}',
                ),
          secondary: _reminderAt == null
              ? null
              : IconButton(
                  tooltip: 'Modifier la date',
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _reminderAt!,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      setState(() => _reminderAt = selected);
                    }
                  },
                  icon: const Icon(Icons.edit_calendar_outlined),
                ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('traditional-pro-send-recommendation'),
          onPressed:
              widget.busy ||
                  _title.text.trim().isEmpty ||
                  _content.text.trim().length < 4
              ? null
              : () => widget.onRun(
                  () => widget.repository.sendPreventionRecommendation(
                    providerId: widget.providerId,
                    patientId: _patientId,
                    type: _type,
                    title: _title.text.trim(),
                    content: _content.text.trim(),
                    reminderAt: _reminderAt,
                  ),
                  'Conseil envoyé au patient.',
                ),
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Envoyer'),
        ),
      ],
    ),
  );
}

class _OrientationPanel extends StatefulWidget {
  final String providerId;
  final List<TraditionalCarePatient> patients;
  final TraditionalMedicineProfessionalRepository repository;
  final bool busy;
  final Future<void> Function(Future<void> Function(), String) onRun;

  const _OrientationPanel({
    required this.providerId,
    required this.patients,
    required this.repository,
    required this.busy,
    required this.onRun,
  });
  @override
  State<_OrientationPanel> createState() => _OrientationPanelState();
}

class _OrientationPanelState extends State<_OrientationPanel> {
  late String _patientId = widget.patients.first.id;
  String _targetType = 'doctor';
  String _urgency = 'routine';
  final _targetName = TextEditingController();
  final _reason = TextEditingController();
  @override
  void dispose() {
    _targetName.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Orientation intelligente',
          style: TextStyle(
            color: ProColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _patientId,
          decoration: const InputDecoration(labelText: 'Patient'),
          items: widget.patients
              .map(
                (patient) => DropdownMenuItem(
                  value: patient.id,
                  child: Text(patient.name),
                ),
              )
              .toList(),
          onChanged: (value) => _patientId = value ?? _patientId,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _targetType,
          decoration: const InputDecoration(labelText: 'Orienter vers'),
          items: const [
            DropdownMenuItem(value: 'doctor', child: Text('Médecin')),
            DropdownMenuItem(value: 'nurse', child: Text('Infirmière')),
            DropdownMenuItem(value: 'midwife', child: Text('Sage-femme')),
            DropdownMenuItem(value: 'psychologist', child: Text('Psychologue')),
            DropdownMenuItem(
              value: 'mobile_clinic',
              child: Text('Clinique mobile'),
            ),
            DropdownMenuItem(value: 'hospital', child: Text('Hôpital')),
          ],
          onChanged: (value) => _targetType = value ?? _targetType,
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('traditional-pro-orientation-name'),
          controller: _targetName,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Nom du professionnel ou de la structure',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('traditional-pro-orientation-reason'),
          controller: _reason,
          onChanged: (_) => setState(() {}),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motif de l’orientation',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'routine', label: Text('Normale')),
            ButtonSegment(value: 'priority', label: Text('Prioritaire')),
            ButtonSegment(value: 'emergency', label: Text('Urgence')),
          ],
          selected: {_urgency},
          onSelectionChanged: (value) => setState(() => _urgency = value.first),
        ),
        if (_urgency == 'emergency') ...[
          const SizedBox(height: 10),
          const Text(
            'Le patient recevra une alerte immédiate vers les services d’urgence.',
            style: TextStyle(
              color: Color(0xFFC9362B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('traditional-pro-send-orientation'),
          onPressed:
              widget.busy ||
                  _targetName.text.trim().length < 2 ||
                  _reason.text.trim().length < 4
              ? null
              : () => widget.onRun(
                  () => widget.repository.createOrientation(
                    providerId: widget.providerId,
                    patientId: _patientId,
                    targetType: _targetType,
                    targetName: _targetName.text.trim(),
                    reason: _reason.text.trim(),
                    urgency: _urgency,
                  ),
                  'Orientation envoyée et patient notifié.',
                ),
          icon: const Icon(Icons.alt_route_rounded),
          label: const Text('Orienter maintenant'),
        ),
      ],
    ),
  );
}

class _ProFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _ProFeedback({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      children: [
        Icon(icon, color: ProColors.primary, size: 39),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ProColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ProColors.muted),
        ),
      ],
    ),
  );
}
