import 'package:flutter/material.dart';

import 'consultation_document_view.dart';
import 'consultation_editor.dart';
import 'consultation_repository.dart';

class ConsultationActions extends StatelessWidget {
  final ConsultationRepository repository;
  final String appointmentId, patientName;
  final bool dark;
  final bool showHistory;
  final VoidCallback? onPublished;
  const ConsultationActions({
    super.key,
    required this.repository,
    required this.appointmentId,
    required this.patientName,
    this.dark = false,
    this.showHistory = true,
    this.onPublished,
  });

  @override
  Widget build(BuildContext context) {
    final ink = dark ? Colors.white : const Color(0xFF142C49);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Consultation',
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showHistory)
              IconButton(
                tooltip: 'Documents envoyés',
                onPressed: () => showConsultationHistory(
                  context,
                  repository: repository,
                  appointmentId: appointmentId,
                  patientName: patientName,
                ),
                icon: Icon(Icons.history_rounded, color: ink),
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final kind in ConsultationKind.values)
                SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: Material(
                    color: dark
                        ? const Color(0xFF273B57)
                        : const Color(0xFFF0F6FA),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final sent = await showConsultationEditor(
                          context,
                          repository: repository,
                          appointmentId: appointmentId,
                          patientName: patientName,
                          kind: kind,
                        );
                        if (sent == true) {
                          onPublished?.call();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Envoyé au patient'),
                              ),
                            );
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              consultationIcon(kind),
                              color: dark
                                  ? const Color(0xFF8ACBFF)
                                  : const Color(0xFF087F8C),
                              size: 23,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              kind.label,
                              style: TextStyle(
                                color: ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> showConsultationHistory(
  BuildContext context, {
  required ConsultationRepository repository,
  required String appointmentId,
  required String patientName,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ConsultationHistory(
    repository: repository,
    appointmentId: appointmentId,
    patientName: patientName,
  ),
);

class _ConsultationHistory extends StatefulWidget {
  final ConsultationRepository repository;
  final String appointmentId, patientName;
  const _ConsultationHistory({
    required this.repository,
    required this.appointmentId,
    required this.patientName,
  });
  @override
  State<_ConsultationHistory> createState() => _ConsultationHistoryState();
}

class _ConsultationHistoryState extends State<_ConsultationHistory> {
  late Future<List<ConsultationDocument>> _documents = widget.repository
      .documents(widget.appointmentId);

  void _refresh() {
    if (!mounted) return;
    final documents = widget.repository.documents(widget.appointmentId);
    setState(() {
      _documents = documents;
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.patientName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  ConsultationActions(
                    repository: widget.repository,
                    appointmentId: widget.appointmentId,
                    patientName: widget.patientName,
                    showHistory: false,
                    onPublished: _refresh,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Documents envoyés',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualiser les documents',
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  FutureBuilder<List<ConsultationDocument>>(
                    future: _documents,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Text('Documents indisponibles.');
                      }
                      if (snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Aucun document envoyé'),
                        );
                      }
                      return Column(
                        children: [
                          for (final doc in snapshot.data!)
                            Card(
                              elevation: 0,
                              child: ExpansionTile(
                                leading: Icon(consultationIcon(doc.kind)),
                                title: Text(doc.kind.title),
                                subtitle: Text(
                                  consultationDate(context, doc.createdAt),
                                ),
                                childrenPadding: const EdgeInsets.all(20),
                                children: [
                                  ConsultationDocumentView(
                                    kind: doc.kind,
                                    payload: doc.payload,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
