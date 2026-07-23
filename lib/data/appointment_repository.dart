import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_request.dart';

abstract class ProfessionalAppointmentRepository {
  Stream<List<ProfessionalAppointment>> watchForProvider(String providerId);

  Future<void> respond({
    required ProfessionalAppointment appointment,
    required ProfessionalAppointmentStatus status,
    required String responseNote,
  });
}

class FirestoreProfessionalAppointmentRepository
    implements ProfessionalAppointmentRepository {
  final FirebaseFirestore firestore;

  FirestoreProfessionalAppointmentRepository({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<ProfessionalAppointment>> watchForProvider(String providerId) =>
      firestore
          .collection('appointments')
          .where('providerId', isEqualTo: providerId)
          .snapshots()
          .map((snapshot) {
            final requests = snapshot.docs
                .map(ProfessionalAppointment.fromFirestore)
                .toList(growable: false);
            requests.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
            return requests;
          });

  @override
  Future<void> respond({
    required ProfessionalAppointment appointment,
    required ProfessionalAppointmentStatus status,
    required String responseNote,
  }) async {
    if (status == ProfessionalAppointmentStatus.pending) return;
    final appointmentReference = firestore
        .collection('appointments')
        .doc(appointment.id);
    final notificationReference = firestore
        .collection('patients')
        .doc(appointment.patientId)
        .collection('notifications')
        .doc('appointment_${appointment.id}');
    final confirmed = status == ProfessionalAppointmentStatus.confirmed;
    final batch = firestore.batch()
      ..update(appointmentReference, {
        'status': status.storageValue,
        'responseNote': responseNote.trim(),
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(notificationReference, {
        'title': confirmed ? 'Rendez-vous confirmé' : 'Rendez-vous annulé',
        'message': confirmed
            ? '${appointment.providerName} a confirmé votre demande de rendez-vous.'
            : '${appointment.providerName} a annulé votre demande de rendez-vous.',
        'type': 'appointment',
        'isRead': false,
        'actionLabel': 'Voir le rendez-vous',
        'source': 'appointment',
        'sourceId': appointment.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }
}
