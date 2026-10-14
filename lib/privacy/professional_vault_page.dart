import 'dart:ui' as ui;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'professional_vault.dart';
import '../consultations/consultation_actions.dart';
import '../consultations/consultation_repository.dart';

class ProfessionalVaultPage extends StatefulWidget {
  final SupabaseClient client;
  final String? appointmentId;
  const ProfessionalVaultPage({
    super.key,
    required this.client,
    this.appointmentId,
  });
  @override
  State<ProfessionalVaultPage> createState() => _ProfessionalVaultPageState();
}

class _ProfessionalVaultPageState extends State<ProfessionalVaultPage>
    with WidgetsBindingObserver {
  late final vault = ProfessionalVault(widget.client);
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _code.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      vault.close();
    }
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await vault.unlock(_code.text, expectedAppointment: widget.appointmentId);
      _code.clear();
    } catch (_) {
      _error = 'Code invalide, expiré ou révoqué.';
    }
    if (mounted) setState(() => _busy = false);
  }

  static const _titles = {
    'appointment_notes': 'Notes de rendez-vous',
    'patient_profiles': 'Profil médical',
    'patient_medical_items': 'Antécédents et traitements',
    'health_measurements': 'Mesures de santé',
    'laboratory_results': 'Analyses',
    'laboratory_result_items': 'Résultats',
    'prescriptions': 'Ordonnances',
    'prescription_items': 'Médicaments',
    'consultation_documents': 'Consultations',
    'laboratory_exam_requests': 'Examens prescrits',
    'preventive_care_records': 'Prévention',
    'preventive_care_reminders': 'Rappels',
    'cycle_entries': 'Cycle',
    'cycle_entry_symptoms': 'Symptômes du cycle',
    'cycle_personal_contexts': 'Contexte du cycle',
    'mental_health_entries': 'Santé mentale',
    'mental_health_entry_feelings': 'Ressenti',
    'pregnancy_profiles': 'Grossesse',
    'pregnancy_reminders': 'Suivi de grossesse',
    'child_profiles': 'Enfants',
    'child_growth_records': 'Croissance',
    'child_vaccination_records': 'Vaccination',
    'symptom_assessments': 'Évaluations',
    'natural_health_journal_entries': 'Journal',
  };
  static const _labels = {
    'sex': 'Sexe',
    'birth_date': 'Date de naissance',
    'weight_kg': 'Poids (kg)',
    'height_cm': 'Taille (cm)',
    'blood_type': 'Groupe sanguin',
    'phone': 'Téléphone',
    'address': 'Adresse',
    'label': 'Nom',
    'details': 'Détails',
    'note': 'Note',
    'notes': 'Notes',
    'title': 'Titre',
    'special_needs': 'Besoins particuliers',
    'pregnancy_status': 'Grossesse',
    'primary_doctor': 'Médecin traitant',
    'insurance': 'Assurance',
    'value': 'Valeur',
    'secondary_value': 'Valeur secondaire',
    'unit': 'Unité',
    'measured_at': 'Mesuré le',
    'entry_date': 'Date',
    'mood': 'Humeur',
    'transcription': 'Ordonnance',
    'medication_name': 'Médicament',
    'dosage': 'Dose',
    'frequency': 'Fréquence',
    'instructions': 'Instructions',
    'duration_days': 'Durée (jours)',
    'name': 'Nom',
    'status': 'État',
    'summary': 'Résumé',
    'conclusion': 'Conclusion',
    'payload': 'Document',
    'items': 'Éléments',
    'created_at': 'Date',
    'feeling': 'Ressenti',
    'symptom': 'Symptôme',
  };
  String _value(dynamic value) {
    if (value is Map) {
      return value.entries
          .where((e) => !e.key.toString().endsWith('_id'))
          .map(
            (e) =>
                '${_labels[e.key] ?? e.key.toString().replaceAll('_', ' ')} : ${_value(e.value)}',
          )
          .join('\n');
    }
    if (value is List) {
      return value.map(_value).join('\n');
    }
    if (value is bool) return value ? 'Oui' : 'Non';
    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: vault,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Dossier autorisé'),
        actions: [
          if (vault.active)
            IconButton(
              tooltip: 'Fermer l’accès',
              onPressed: vault.close,
              icon: const Icon(Icons.lock),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (!vault.active ||
                  (widget.appointmentId != null &&
                      vault.appointmentId != widget.appointmentId)) ...[
                TextField(
                  controller: _code,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Code transmis par le patient',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _unlock,
                  child: const Text('Consulter'),
                ),
                if (_busy) const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ] else ...[
                Text(
                  'Accès jusqu’à ${vault.expiresAt!.hour.toString().padLeft(2, '0')}:${vault.expiresAt!.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 20),
                ConsultationActions(
                  repository: SupabaseConsultationRepository(
                    client: widget.client,
                    userId: widget.client.auth.currentUser!.id,
                  ),
                  appointmentId: vault.appointmentId!,
                  patientName: 'Patient',
                ),
                const SizedBox(height: 20),
                for (final file in vault.records('files'))
                  if (RegExp(
                    r'\.(pdf|png|jpe?g|webp)$',
                    caseSensitive: false,
                  ).hasMatch(file['path']?.toString() ?? ''))
                    ExpansionTile(
                      title: const Text('Ordonnance jointe'),
                      children: [
                        if (file['path'].toString().toLowerCase().endsWith(
                          '.pdf',
                        ))
                          _VaultPdf(encoded: file['bytes'] as String)
                        else
                          _VaultAttachment(encoded: file['bytes'] as String),
                      ],
                    ),
                for (final table in vault.snapshot.keys.where(
                  _titles.containsKey,
                ))
                  if (vault.records(table).isNotEmpty)
                    ExpansionTile(
                      title: Text(_titles[table]!),
                      children: [
                        for (final row in vault.records(table))
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final e in row.entries)
                                    if (!e.key.endsWith('_id') &&
                                        ![
                                          'updated_at',
                                          'storage_path',
                                          'request_fingerprint',
                                          'profile_complete',
                                        ].contains(e.key) &&
                                        e.value != null &&
                                        e.value.toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          '${_labels[e.key] ?? e.key.replaceAll('_', ' ')} : ${_value(e.value)}',
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _VaultAttachment extends StatefulWidget {
  final String encoded;
  const _VaultAttachment({required this.encoded});
  @override
  State<_VaultAttachment> createState() => _VaultAttachmentState();
}

class _VaultAttachmentState extends State<_VaultAttachment> {
  late final _image = MemoryImage(base64Decode(widget.encoded));
  @override
  void dispose() {
    _image.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Image(image: _image, gaplessPlayback: false);
}

/// Renders only the current PDF page locally, without a URL or a disk export.
/// RawImage keeps medical pages out of Flutter's shared image cache.
class _VaultPdf extends StatefulWidget {
  final String encoded;
  const _VaultPdf({required this.encoded});
  @override
  State<_VaultPdf> createState() => _VaultPdfState();
}

class _VaultPdfState extends State<_VaultPdf> {
  late final _bytes = base64Decode(widget.encoded);
  ui.Image? _image;
  int _page = 0;
  bool _busy = true, _last = false, _error = false;
  @override
  void initState() {
    super.initState();
    _load(0);
  }

  Future<void> _load(int page) async {
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      final raster = await Printing.raster(
        _bytes,
        pages: [page],
        dpi: 110,
      ).first;
      final image = await raster.toImage();
      if (!mounted) {
        image.dispose();
        return;
      }
      final old = _image;
      setState(() {
        _image = image;
        _page = page;
        _last = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    } catch (_) {
      if (mounted) {
        setState(() {
          if (page > _page && _image != null) {
            _last = true;
          } else {
            _error = true;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    _bytes.fillRange(0, _bytes.length, 0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_busy) const CircularProgressIndicator(),
      if (_error) const Text('Document illisible.'),
      if (_image != null) RawImage(image: _image, fit: BoxFit.contain),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Page précédente',
            onPressed: _busy || _page == 0 ? null : () => _load(_page - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${_page + 1}'),
          IconButton(
            tooltip: 'Page suivante',
            onPressed: _busy || _last ? null : () => _load(_page + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ],
  );
}
