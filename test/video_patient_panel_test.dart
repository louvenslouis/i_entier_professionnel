import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_entier_professionnel/video_calls/video_call_repository.dart';
import 'package:i_entier_professionnel/video_calls/video_patient_panel.dart';
import 'package:i_entier_professionnel/video_calls/video_room_page.dart';

class _Repository implements VideoCallRepository {
  int reads = 0;
  bool fail = false;
  VideoPatientDetails details = const VideoPatientDetails({
    'birth_date': '1990-05-12',
    'sex': 'Femme',
    'blood_type': 'O+',
    'weight_kg': 65,
    'height_cm': 168,
    'patient_note': 'Consultation de suivi',
    'medical_items': [
      {
        'type': 'allergy',
        'label': 'Pénicilline',
        'details': 'Éruption cutanée',
      },
      {'type': 'condition', 'label': 'Asthme', 'details': ''},
    ],
  });
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<VideoPatientDetails?> patientDetails(String appointmentId) async {
    reads++;
    if (fail) throw Exception('offline');
    return details;
  }

  @override
  Future<List<VideoAppointment>> appointments() async => [];
  @override
  Future<Map<String, dynamic>> command(
    String action, {
    String? appointmentId,
    String? callId,
  }) async => {'calls': [], 'configured': true};
  @override
  void dispose() {}
}

void main() {
  test('age respects the birthday and rejects future dates', () {
    const patient = VideoPatientDetails({'birth_date': '1990-05-12'});
    expect(patient.ageAt(DateTime(2026, 5, 11)), 35);
    expect(patient.ageAt(DateTime(2026, 5, 12)), 36);
    expect(patient.ageAt(DateTime(1989)), isNull);
    expect(const VideoPatientDetails({}).ageAt(DateTime(2026)), isNull);
  });

  testWidgets('small screen shows medical data and hides empty fields', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoPatientPanel(
              repository: repository,
              appointmentId: 'a',
              name: 'Marie Jean',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('Pénicilline · Éruption cutanée'), findsOneWidget);
    expect(find.text('Téléphone'), findsNothing);
    expect(find.text('Assurance'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed load can be retried', (tester) async {
    final repository = _Repository()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoPatientPanel(
            repository: repository,
            appointmentId: 'a',
            name: 'Marie Jean',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Données patient indisponibles'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('O+'), findsOneWidget);
    expect(repository.reads, 2);
  });

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('call keeps controls accessible at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _Repository();
      final controller = VideoCallController(
        repository: repository,
        userId: 'provider',
      );
      final call = VideoCall.fromJson({
        'id': 'call',
        'appointment_id': 'a',
        'patient_id': 'patient',
        'provider_id': 'provider',
        'caller_id': 'provider',
        'patient_name': 'Marie Jean',
        'provider_name': 'Dr Jean',
        'status': 'ringing',
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
      });
      await tester.pumpWidget(
        MaterialApp(
          home: VideoRoomPage(controller: controller, initialCall: call),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Raccrocher'), findsOneWidget);
      if (size.width < 900) {
        expect(find.byType(VideoPatientPanel), findsNothing);
        await tester.tap(find.byTooltip('Données patient'));
        await tester.pumpAndSettle();
      }
      expect(find.text('O+'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump();
    });
  }
}
