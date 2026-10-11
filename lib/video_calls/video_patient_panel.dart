import 'package:flutter/material.dart';

import 'video_call_repository.dart';
import '../consultations/consultation_actions.dart';

class VideoPatientPanel extends StatefulWidget {
  final VideoCallRepository repository;
  final String appointmentId;
  final String name;
  final bool dark;

  const VideoPatientPanel({
    super.key,
    required this.repository,
    required this.appointmentId,
    required this.name,
    this.dark = false,
  });

  @override
  State<VideoPatientPanel> createState() => _VideoPatientPanelState();
}

class _VideoPatientPanelState extends State<VideoPatientPanel> {
  late Future<VideoPatientDetails?> _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VideoPatientPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointmentId != widget.appointmentId ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  void _load() {
    _details = widget.repository.patientDetails(widget.appointmentId);
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.dark ? Colors.white : const Color(0xFF142C49);
    final muted = widget.dark ? Colors.white60 : const Color(0xFF65758A);
    final accent = widget.dark
        ? const Color(0xFF8ACBFF)
        : const Color(0xFF1976D2);
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: ink),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: .12),
                  child: Icon(Icons.person_outline_rounded, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.repository.consultations case final repository?) ...[
              ConsultationActions(
                repository: repository,
                appointmentId: widget.appointmentId,
                patientName: widget.name,
                dark: widget.dark,
              ),
              const SizedBox(height: 24),
            ],
            FutureBuilder<VideoPatientDetails?>(
              future: _details,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Données patient indisponibles',
                        style: TextStyle(color: muted),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(_load),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  );
                }
                final patient = snapshot.data;
                if (patient == null) {
                  return Text(
                    'Données patient indisponibles',
                    style: TextStyle(color: muted),
                  );
                }
                final age = patient.ageAt(DateTime.now());
                final metrics = <(IconData, String)>[
                  if (age != null) (Icons.cake_outlined, '$age ans'),
                  if (patient.text('sex').isNotEmpty)
                    (Icons.person_outline, patient.text('sex')),
                  if (patient.text('blood_type').isNotEmpty)
                    (Icons.water_drop_outlined, patient.text('blood_type')),
                  if (patient.text('weight_kg').isNotEmpty)
                    (
                      Icons.monitor_weight_outlined,
                      '${patient.text('weight_kg')} kg',
                    ),
                  if (patient.text('height_cm').isNotEmpty)
                    (Icons.height_rounded, '${patient.text('height_cm')} cm'),
                ];
                Widget section(
                  String title,
                  String value, {
                  bool alert = false,
                }) => Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: alert
                              ? (widget.dark
                                    ? const Color(0xFFFFBAAA)
                                    : const Color(0xFFB94432))
                              : muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SelectableText(
                        value,
                        style: TextStyle(color: ink, height: 1.45),
                      ),
                    ],
                  ),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (metrics.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final metric in metrics)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(metric.$1, size: 16, color: accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    metric.$2,
                                    style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    for (final entry in const {
                      'patient_note': 'Motif de consultation',
                      'service': 'Consultation',
                    }.entries)
                      if (patient.text(entry.key).isNotEmpty)
                        section(entry.value, patient.text(entry.key)),
                    for (final entry in const {
                      'allergy': 'Allergies',
                      'condition': 'Antécédents',
                      'medication': 'Traitements',
                      'surgery': 'Interventions',
                    }.entries)
                      if (patient.medicalItems.any(
                        (item) => item['type'] == entry.key,
                      ))
                        section(
                          entry.value,
                          patient.medicalItems
                              .where((item) => item['type'] == entry.key)
                              .map((item) {
                                final details =
                                    item['details']?.toString().trim() ?? '';
                                return '${item['label']}${details.isEmpty ? '' : ' · $details'}';
                              })
                              .join('\n'),
                          alert: entry.key == 'allergy',
                        ),
                    for (final entry in const {
                      'special_needs': 'Besoins particuliers',
                      'pregnancy_status': 'Grossesse',
                      'phone': 'Téléphone',
                      'address': 'Adresse',
                      'primary_doctor': 'Médecin traitant',
                      'insurance': 'Assurance',
                    }.entries)
                      if (patient.text(entry.key).isNotEmpty)
                        section(entry.value, patient.text(entry.key)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPatientDisclosure extends StatefulWidget {
  final VideoCallRepository repository;
  final VideoAppointment appointment;
  const VideoPatientDisclosure({
    super.key,
    required this.repository,
    required this.appointment,
  });

  @override
  State<VideoPatientDisclosure> createState() => _VideoPatientDisclosureState();
}

class _VideoPatientDisclosureState extends State<VideoPatientDisclosure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    shape: const Border(),
    collapsedShape: const Border(),
    leading: const Icon(
      Icons.assignment_ind_outlined,
      color: Color(0xFF1976D2),
    ),
    title: const Text(
      'Données patient',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    onExpansionChanged: (value) => setState(() => _expanded = value),
    children: [
      if (_expanded)
        VideoPatientPanel(
          repository: widget.repository,
          appointmentId: widget.appointment.id,
          name: widget.appointment.name,
        ),
    ],
  );
}
