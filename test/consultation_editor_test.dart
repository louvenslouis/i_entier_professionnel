import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_entier_professionnel/consultations/consultation_actions.dart';
import 'package:i_entier_professionnel/consultations/consultation_editor.dart';
import 'package:i_entier_professionnel/consultations/consultation_repository.dart';
import 'package:i_entier_professionnel/theme/pro_theme.dart';

class _Repository implements ConsultationRepository {
  final sent =
      <({String id, ConsultationKind kind, Map<String, dynamic> payload})>[];
  bool failFirst = false;
  int historyReads = 0;
  Completer<void>? block;
  @override
  Future<List<ConsultationDocument>> documents(String appointmentId) async {
    historyReads++;
    return [
      for (final item in sent) _document(item.kind, item.payload, item.id),
    ];
  }

  @override
  Future<List<ConsultationExam>> examCatalog(String appointmentId) async => [
    const ConsultationExam(
      id: 'cbc',
      name: 'Hémogramme',
      category: 'Hématologie',
    ),
  ];
  @override
  Future<ConsultationDocument> publish({
    required String appointmentId,
    required String requestId,
    required ConsultationKind kind,
    required Map<String, dynamic> payload,
  }) async {
    sent.add((id: requestId, kind: kind, payload: payload));
    if (failFirst && sent.length == 1) throw TimeoutException('offline');
    if (block != null) await block!.future;
    return _document(kind, payload, requestId);
  }

  ConsultationDocument _document(
    ConsultationKind kind,
    Map<String, dynamic> payload,
    String id,
  ) => ConsultationDocument.fromJson({
    'document_id': id,
    'patient_name': 'Marie Jean',
    'provider_name': 'Dr Louis',
    'kind': kind.name,
    'payload': payload,
    'created_at': '2026-10-10T12:00:00Z',
  });
}

Future<void> _open(
  WidgetTester tester,
  _Repository repository,
  ConsultationKind kind,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildProTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showConsultationEditor(
              context,
              repository: repository,
              appointmentId: 'appointment',
              patientName: 'Marie Jean',
              kind: kind,
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String label, String text) async {
  final finder = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'diagnostic validates, previews, and sends only after confirmation',
    (tester) async {
      final repository = _Repository();
      await _open(tester, repository, ConsultationKind.diagnosis);
      await _tap(tester, 'Aperçu');
      expect(find.text('Champ requis'), findsOneWidget);
      expect(repository.sent, isEmpty);
      await _fill(
        tester,
        'Diagnostic',
        'Diagnostic rédigé par le professionnel',
      );
      await _fill(tester, 'Symptômes', 'Symptômes rapportés');
      await _fill(tester, 'Conduite à tenir', 'Suivi prévu');
      await _tap(tester, 'Aperçu');
      expect(repository.sent, isEmpty);
      expect(
        find.text('Diagnostic rédigé par le professionnel'),
        findsOneWidget,
      );
      await _tap(tester, 'Envoyer au patient');
      expect(repository.sent.single.kind, ConsultationKind.diagnosis);
      expect(repository.sent.single.payload['plan'], 'Suivi prévu');
      expect(find.byType(ConsultationEditor), findsNothing);
    },
  );

  testWidgets('prescription retains structured medication details', (
    tester,
  ) async {
    final repository = _Repository();
    await _open(tester, repository, ConsultationKind.prescription);
    await _fill(tester, 'Médicament', 'Médicament de test');
    await _fill(tester, 'Dosage', 'Dose de test');
    await _fill(tester, 'Fréquence', 'Fréquence de test');
    await _fill(tester, 'Durée en jours', '0');
    await _tap(tester, 'Aperçu');
    expect(find.text('Entre 1 et 3650 jours'), findsOneWidget);
    await _fill(tester, 'Durée en jours', '3');
    await _fill(tester, 'Instructions', 'Consigne de test');
    await _tap(tester, 'Aperçu');
    await _tap(tester, 'Envoyer au patient');
    final medication =
        (repository.sent.single.payload['items'] as List).single as Map;
    expect(medication['duration_days'], 3);
    expect(medication['instructions'], 'Consigne de test');
  });

  testWidgets('exam can use a catalog entry with instructions and priority', (
    tester,
  ) async {
    final repository = _Repository();
    await _open(tester, repository, ConsultationKind.exams);
    await _fill(tester, 'Indication clinique', 'Indication de test');
    await _tap(tester, 'Autre examen');
    await tester.tap(find.text('Hémogramme').last);
    await tester.pumpAndSettle();
    await _fill(tester, 'Instructions et préparation', 'Préparation saisie');
    await _tap(tester, 'Aperçu');
    expect(find.text('Hémogramme'), findsOneWidget);
    await _tap(tester, 'Envoyer au patient');
    expect(
      (repository.sent.single.payload['items'] as List).single['exam_id'],
      'cbc',
    );
    expect(repository.sent.single.payload['priority'], 'routine');
  });

  testWidgets(
    'followup requires a future date and sends UTC appointment data',
    (tester) async {
      final repository = _Repository();
      await _open(tester, repository, ConsultationKind.followup);
      await _tap(tester, 'Aperçu');
      expect(repository.sent, isEmpty);
      expect(
        find.textContaining('Choisissez une date et une heure'),
        findsOneWidget,
      );
      await _tap(tester, 'Choisir la date');
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(DateTime.now().add(const Duration(days: 7)));
      await tester.pumpAndSettle();
      await _tap(tester, 'OK');
      await _tap(tester, 'Choisir l’heure');
      await _tap(tester, 'OK');
      await _fill(tester, 'Note au patient', 'Consultation de suivi');
      await _tap(tester, 'Aperçu');
      await _tap(tester, 'Envoyer au patient');
      expect(repository.sent.single.kind, ConsultationKind.followup);
      expect(
        DateTime.parse(
          repository.sent.single.payload['scheduled_at'] as String,
        ).isUtc,
        isTrue,
      );
      expect(repository.sent.single.payload['mode'], 'video');
    },
  );

  testWidgets('network retry preserves the request ID and reviewed content', (
    tester,
  ) async {
    final repository = _Repository()..failFirst = true;
    await _open(tester, repository, ConsultationKind.diagnosis);
    await _fill(tester, 'Diagnostic', 'Diagnostic de test');
    await _tap(tester, 'Aperçu');
    await _tap(tester, 'Envoyer au patient');
    expect(find.text('Modifier'), findsNothing);
    expect(find.textContaining('Envoi non confirmé'), findsOneWidget);
    await _tap(tester, 'Vérifier l’envoi');
    expect(repository.sent.length, 2);
    expect(repository.sent.first.id, repository.sent.last.id);
    expect(repository.sent.first.payload, repository.sent.last.payload);
  });

  testWidgets('an in-flight send cannot be duplicated or dismissed', (
    tester,
  ) async {
    final repository = _Repository()..block = Completer<void>();
    await _open(tester, repository, ConsultationKind.diagnosis);
    await _fill(tester, 'Diagnostic', 'Diagnostic de test');
    await _tap(tester, 'Aperçu');
    await tester.tap(find.text('Envoyer au patient'));
    await tester.pump();
    expect(repository.sent.length, 1);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Envoi…'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Fermer',
            ),
          )
          .onPressed,
      isNull,
    );
    repository.block!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ConsultationEditor), findsNothing);
  });

  testWidgets('history refreshes after sending a document', (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildProTheme(),
        home: Scaffold(
          body: ConsultationActions(
            repository: repository,
            appointmentId: 'a',
            patientName: 'Marie Jean',
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Documents envoyés'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun document envoyé'), findsOneWidget);
    await tester.tap(find.text('Diagnostic').last);
    await tester.pumpAndSettle();
    await _fill(tester, 'Diagnostic', 'Diagnostic de test');
    await _tap(tester, 'Aperçu');
    await _tap(tester, 'Envoyer au patient');
    expect(find.text('Aucun document envoyé'), findsNothing);
    expect(find.text('Fiche de diagnostic'), findsOneWidget);
    await tester.tap(find.byTooltip('Actualiser les documents'));
    await tester.pumpAndSettle();
    expect(repository.historyReads, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile actions and large text fit without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildProTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConsultationActions(
                  repository: _Repository(),
                  appointmentId: 'a',
                  patientName: 'Marie Jean',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Diagnostic'), findsOneWidget);
    expect(find.text('Ordonnance'), findsOneWidget);
    expect(find.text('Examens'), findsOneWidget);
    expect(find.text('Rendez-vous'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
