import '../privacy/vault_access_boundary.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'consultation_document_view.dart';
import 'consultation_repository.dart';

Future<bool?> showConsultationEditor(
  BuildContext context, {
  required ConsultationRepository repository,
  required String appointmentId,
  required String patientName,
  required ConsultationKind kind,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => repository is SupabaseConsultationRepository
      ? VaultAccessBoundary(client: repository.client, appointmentId: appointmentId,
          builder: () => ConsultationEditor(repository: repository, appointmentId: appointmentId, patientName: patientName, kind: kind))
      : ConsultationEditor(repository: repository, appointmentId: appointmentId, patientName: patientName, kind: kind),
);

class ConsultationEditor extends StatefulWidget {
  final ConsultationRepository repository;
  final String appointmentId, patientName;
  final ConsultationKind kind;
  const ConsultationEditor({
    super.key,
    required this.repository,
    required this.appointmentId,
    required this.patientName,
    required this.kind,
  });
  @override
  State<ConsultationEditor> createState() => _ConsultationEditorState();
}

class _ConsultationEditorState extends State<ConsultationEditor> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _fields = <String, TextEditingController>{};
  final _medications = <_MedicationFields>[_MedicationFields()];
  final _exams = <_ExamFields>[_ExamFields()];
  final _requestId = newConsultationRequestId();
  List<ConsultationExam> _catalog = [];
  bool _loadingCatalog = false, _catalogError = false;
  bool _review = false, _sending = false, _uncertain = false, _dirty = false;
  String? _error;
  String _priority = 'routine', _mode = 'video';
  DateTime? _date;
  TimeOfDay? _time;
  Map<String, dynamic>? _pendingPayload;

  TextEditingController _field(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    if (widget.kind == ConsultationKind.exams) _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCatalog = true;
      _catalogError = false;
    });
    try {
      final catalog = await widget.repository.examCatalog(widget.appointmentId);
      if (mounted) setState(() => _catalog = catalog);
    } catch (_) {
      if (mounted) setState(() => _catalogError = true);
    } finally {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final field in _fields.values) {
      field.dispose();
    }
    for (final item in _medications) {
      item.dispose();
    }
    for (final item in _exams) {
      item.dispose();
    }
    super.dispose();
  }

  DateTime? get _scheduledAt => _date == null || _time == null
      ? null
      : DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time!.hour,
          _time!.minute,
        );

  Map<String, dynamic> _payload() => switch (widget.kind) {
    ConsultationKind.diagnosis => {
      for (final key in ['diagnosis', 'symptoms', 'observations', 'plan'])
        key: _field(key).text.trim(),
    },
    ConsultationKind.prescription => {
      'items': [for (final m in _medications) m.json],
      'notes': _field('notes').text.trim(),
    },
    ConsultationKind.exams => {
      'items': [for (final e in _exams) e.json],
      'priority': _priority,
      'indication': _field('indication').text.trim(),
    },
    ConsultationKind.followup => {
      'scheduled_at': _scheduledAt!.toUtc().toIso8601String(),
      'mode': _mode,
      'location': _field('location').text.trim(),
      'note': _field('note').text.trim(),
    },
  };

  void _preview() {
    if (!_form.currentState!.validate()) return;
    if (widget.kind == ConsultationKind.followup) {
      final date = _scheduledAt;
      final now = DateTime.now();
      if (date == null ||
          !date.isAfter(now.add(const Duration(minutes: 30))) ||
          !date.isBefore(now.add(const Duration(days: 365)))) {
        setState(
          () => _error =
              'Choisissez une date et une heure entre 30 minutes et un an à partir de maintenant.',
        );
        return;
      }
    }
    setState(() {
      _pendingPayload = _payload();
      _review = true;
      _error = null;
    });
    _scroll.jumpTo(0);
  }

  Future<void> _send() async {
    if (_sending || _pendingPayload == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.publish(
        appointmentId: widget.appointmentId,
        requestId: _requestId,
        kind: widget.kind,
        payload: Map<String, dynamic>.from(
          jsonDecode(jsonEncode(_pendingPayload)) as Map,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ConsultationException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _uncertain = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Envoi non confirmé. Réessayez pour vérifier la transmission.';
          _uncertain = true;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close() async {
    if (_sending) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_uncertain ? 'Fermer cet envoi ?' : 'Quitter la fiche ?'),
          content: Text(
            _uncertain
                ? 'La transmission n’a pas été confirmée. Vérifiez les documents envoyés avant de recommencer.'
                : 'Les modifications non envoyées seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool required = false,
    int max = 4000,
    int lines = 1,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      keyboardType: number
          ? TextInputType.number
          : (lines > 1 ? TextInputType.multiline : TextInputType.text),
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      maxLength: max,
      decoration: InputDecoration(labelText: label, counterText: ''),
      onChanged: (_) => _dirty = true,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Champ requis';
        }
        if (number &&
            ((int.tryParse(value ?? '') ?? 0) < 1 ||
                (int.tryParse(value ?? '') ?? 0) > 3650)) {
          return 'Entre 1 et 3650 jours';
        }
        return null;
      },
    ),
  );

  Widget _section(
    String title,
    List<Widget> children, {
    VoidCallback? onRemove,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FA),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2EBF0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'Retirer',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 364)),
    );
    if (day != null && mounted) {
      setState(() {
        _date = day;
        _dirty = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null && mounted) {
      setState(() {
        _time = time;
        _dirty = true;
      });
    }
  }

  List<Widget> _formFields() => switch (widget.kind) {
    ConsultationKind.diagnosis => [
      _input('Diagnostic', _field('diagnosis'), required: true, lines: 2),
      _input('Symptômes', _field('symptoms'), lines: 2),
      _input('Observations cliniques', _field('observations'), lines: 3),
      _input('Conduite à tenir', _field('plan'), lines: 3),
    ],
    ConsultationKind.prescription => [
      for (var i = 0; i < _medications.length; i++)
        _section(
          'Médicament ${i + 1}',
          [
            _input(
              'Médicament',
              _medications[i].name,
              required: true,
              max: 180,
            ),
            _input('Dosage', _medications[i].dosage, required: true, max: 120),
            _input(
              'Fréquence',
              _medications[i].frequency,
              required: true,
              max: 120,
            ),
            _input(
              'Durée en jours',
              _medications[i].duration,
              required: true,
              max: 4,
              number: true,
            ),
            _input('Voie d’administration', _medications[i].route, max: 80),
            _input(
              'Instructions',
              _medications[i].instructions,
              lines: 2,
              max: 500,
            ),
          ],
          onRemove: _medications.length > 1
              ? () {
                  final removed = _medications[i];
                  setState(() {
                    _medications.removeAt(i);
                    _dirty = true;
                  });
                  // Controllers are released after their form fields have left the tree.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => removed.dispose(),
                  );
                }
              : null,
        ),
      if (_medications.length < 20)
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _medications.add(_MedicationFields());
            _dirty = true;
          }),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter un médicament'),
        ),
      const SizedBox(height: 18),
      _input('Consignes générales', _field('notes'), lines: 2, max: 2000),
    ],
    ConsultationKind.exams => [
      if (_loadingCatalog) const LinearProgressIndicator(minHeight: 2),
      if (_catalogError)
        TextButton.icon(
          onPressed: _loadCatalog,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recharger le catalogue'),
        ),
      _input('Indication clinique', _field('indication'), lines: 2, max: 2000),
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: DropdownButtonFormField<String>(
          initialValue: _priority,
          decoration: const InputDecoration(labelText: 'Priorité'),
          items: const [
            DropdownMenuItem(value: 'routine', child: Text('Standard')),
            DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
          ],
          onChanged: (value) => setState(() {
            _priority = value!;
            _dirty = true;
          }),
        ),
      ),
      for (var i = 0; i < _exams.length; i++)
        _section(
          'Examen ${i + 1}',
          [
            if (_catalog.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                    'catalog-${identityHashCode(_exams[i])}-${_exams[i].catalogId}',
                  ),
                  initialValue: _exams[i].catalogId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Catalogue'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Autre examen'),
                    ),
                    for (final exam in _catalog)
                      DropdownMenuItem(
                        value: exam.id,
                        child: Text(exam.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (id) => setState(() {
                    _exams[i].catalogId = id!;
                    _exams[i].name.text = id.isEmpty
                        ? ''
                        : _catalog.firstWhere((e) => e.id == id).name;
                    _dirty = true;
                  }),
                ),
              ),
            if (_exams[i].catalogId.isEmpty)
              _input(
                'Nom de l’examen',
                _exams[i].name,
                required: true,
                max: 160,
              ),
            _input(
              'Instructions et préparation',
              _exams[i].instructions,
              max: 1500,
              lines: 2,
            ),
          ],
          onRemove: _exams.length > 1
              ? () {
                  final removed = _exams[i];
                  setState(() {
                    _exams.removeAt(i);
                    _dirty = true;
                  });
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => removed.dispose(),
                  );
                }
              : null,
        ),
      if (_exams.length < 20)
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _exams.add(_ExamFields());
            _dirty = true;
          }),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter un examen'),
        ),
    ],
    ConsultationKind.followup => [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              _date == null
                  ? 'Choisir la date'
                  : MaterialLocalizations.of(context).formatMediumDate(_date!),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule_rounded),
            label: Text(
              _time == null
                  ? 'Choisir l’heure'
                  : MaterialLocalizations.of(
                      context,
                    ).formatTimeOfDay(_time!, alwaysUse24HourFormat: true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(
        initialValue: _mode,
        decoration: const InputDecoration(labelText: 'Mode de consultation'),
        items: const [
          DropdownMenuItem(value: 'video', child: Text('Vidéo')),
          DropdownMenuItem(value: 'inPerson', child: Text('Sur place')),
          DropdownMenuItem(value: 'homeVisit', child: Text('À domicile')),
        ],
        onChanged: (value) => setState(() {
          _mode = value!;
          _dirty = true;
        }),
      ),
      const SizedBox(height: 18),
      if (_mode != 'video')
        _input(
          'Lieu',
          _field('location'),
          required: _mode == 'homeVisit',
          max: 300,
        ),
      _input('Note au patient', _field('note'), max: 500, lines: 3),
    ],
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending && !_dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 18),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Icon(
                    consultationIcon(widget.kind),
                    color: const Color(0xFF087F8C),
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.kind.title,
                          style: const TextStyle(
                            color: Color(0xFF142C49),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.patientName,
                          style: const TextStyle(color: Color(0xFF637381)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: _sending ? null : _close,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.all(22),
                child: _review
                    ? ConsultationDocumentView(
                        kind: widget.kind,
                        payload: _pendingPayload!,
                      )
                    : Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _formFields(),
                        ),
                      ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (_review && !_uncertain)
                    TextButton(
                      onPressed: _sending
                          ? null
                          : () => setState(() => _review = false),
                      child: const Text('Modifier'),
                    ),
                  FilledButton.icon(
                    onPressed: _sending
                        ? null
                        : _review
                        ? _send
                        : _preview,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _review
                                ? Icons.send_rounded
                                : Icons.visibility_outlined,
                          ),
                    label: Text(
                      _sending
                          ? 'Envoi…'
                          : _review
                          ? (_uncertain
                                ? 'Vérifier l’envoi'
                                : 'Envoyer au patient')
                          : 'Aperçu',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MedicationFields {
  final name = TextEditingController(),
      dosage = TextEditingController(),
      frequency = TextEditingController(),
      duration = TextEditingController(),
      route = TextEditingController(),
      instructions = TextEditingController();
  Map<String, dynamic> get json => {
    'medication_name': name.text.trim(),
    'dosage': dosage.text.trim(),
    'frequency': frequency.text.trim(),
    'duration_days': int.parse(duration.text),
    'administration_route': route.text.trim(),
    'instructions': instructions.text.trim(),
  };
  void dispose() {
    for (final field in [
      name,
      dosage,
      frequency,
      duration,
      route,
      instructions,
    ]) {
      field.dispose();
    }
  }
}

class _ExamFields {
  String catalogId = '';
  final name = TextEditingController(), instructions = TextEditingController();
  Map<String, dynamic> get json => {
    'exam_id': catalogId.isEmpty ? null : catalogId,
    'name': name.text.trim(),
    'instructions': instructions.text.trim(),
  };
  void dispose() {
    name.dispose();
    instructions.dispose();
  }
}
