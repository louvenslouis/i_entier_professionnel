import 'package:flutter/material.dart';

import '../data/appointment_repository.dart';
import '../models/appointment_request.dart';
import '../models/provider_profile.dart';
import '../theme/pro_theme.dart';

enum _AppointmentFilter { all, pending, confirmed, cancelled }

class ProAppointmentsScreen extends StatefulWidget {
  final ProviderProfile profile;
  final ProfessionalAppointmentRepository repository;

  const ProAppointmentsScreen({
    super.key,
    required this.profile,
    required this.repository,
  });

  @override
  State<ProAppointmentsScreen> createState() => _ProAppointmentsScreenState();
}

class _ProAppointmentsScreenState extends State<ProAppointmentsScreen> {
  _AppointmentFilter _filter = _AppointmentFilter.all;
  String? _processingId;

  Future<void> _respond(
    ProfessionalAppointment appointment,
    ProfessionalAppointmentStatus status,
  ) async {
    var note = '';
    final confirmed = status == ProfessionalAppointmentStatus.confirmed;
    final responseNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          confirmed ? 'Valider le rendez-vous' : 'Annuler le rendez-vous',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${appointment.patientName} • ${_longDateTime(appointment.scheduledAt)}',
            ),
            const SizedBox(height: 16),
            TextField(
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              onChanged: (value) => note = value,
              decoration: InputDecoration(
                labelText:
                    confirmed &&
                        appointment.mode == ProfessionalAppointmentMode.video
                    ? 'Lien ou instructions de visioconférence'
                    : confirmed
                    ? 'Message au patient (facultatif)'
                    : 'Motif de l’annulation (facultatif)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour'),
          ),
          FilledButton(
            key: const ValueKey('confirm-appointment-response'),
            onPressed: () => Navigator.of(context).pop(note),
            style: confirmed
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB42318),
                  ),
            child: Text(confirmed ? 'Confirmer' : 'Annuler le rendez-vous'),
          ),
        ],
      ),
    );
    if (responseNote == null || !mounted) return;

    setState(() => _processingId = appointment.id);
    try {
      await widget.repository.respond(
        appointment: appointment,
        status: status,
        responseNote: responseNote,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirmed
                ? 'Rendez-vous confirmé et patient notifié.'
                : 'Rendez-vous annulé et patient notifié.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La réponse n’a pas pu être enregistrée.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _edit(ProfessionalAppointment appointment) async {
    var selectedDateTime = appointment.scheduledAt;
    var responseNote = appointment.responseNote;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Modifier le rendez-vous'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const ValueKey('edit-professional-appointment-date'),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null) return;
                    setDialogState(() {
                      selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        selectedDateTime.hour,
                        selectedDateTime.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(_shortDate(selectedDateTime)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('edit-professional-appointment-time'),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (time == null) return;
                    setDialogState(() {
                      selectedDateTime = DateTime(
                        selectedDateTime.year,
                        selectedDateTime.month,
                        selectedDateTime.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    '${_twoDigits(selectedDateTime.hour)} h ${_twoDigits(selectedDateTime.minute)}',
                  ),
                ),
                if (appointment.status ==
                    ProfessionalAppointmentStatus.confirmed) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('edit-professional-appointment-note'),
                    initialValue: responseNote,
                    onChanged: (value) => responseNote = value,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Instructions au patient (facultatif)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Retour'),
            ),
            FilledButton(
              key: const ValueKey('save-professional-appointment-changes'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (save != true || !mounted) return;
    if (!selectedDateTime.isAfter(
      DateTime.now().add(const Duration(minutes: 30)),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez un horaire situé à plus de 30 minutes.'),
        ),
      );
      return;
    }
    await _runAction(
      appointment,
      () => widget.repository.update(
        appointment: appointment,
        scheduledAt: selectedDateTime,
        responseNote: responseNote,
      ),
      success: 'Rendez-vous modifié et patient notifié.',
      failure: 'Le rendez-vous n’a pas pu être modifié.',
    );
  }

  Future<void> _delete(ProfessionalAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce rendez-vous ?'),
        content: const Text(
          'Il disparaîtra uniquement de votre interface. Le patient conservera son historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Retour'),
          ),
          FilledButton(
            key: const ValueKey('confirm-professional-appointment-deletion'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runAction(
      appointment,
      () => widget.repository.deleteForProvider(appointment),
      success: 'Rendez-vous supprimé de votre interface.',
      failure: 'Le rendez-vous n’a pas pu être supprimé.',
    );
  }

  Future<void> _runAction(
    ProfessionalAppointment appointment,
    Future<void> Function() action, {
    required String success,
    required String failure,
  }) async {
    setState(() => _processingId = appointment.id);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure)));
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('professional-appointments-page'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Rendez-vous', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      const Text(
        'Validez, modifiez, annulez ou supprimez vos rendez-vous.',
        style: TextStyle(color: ProColors.muted, fontSize: 15),
      ),
      const SizedBox(height: 22),
      StreamBuilder<List<ProfessionalAppointment>>(
        stream: widget.repository.watchForProvider(widget.profile.ownerUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _AppointmentsMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Demandes indisponibles',
              message:
                  'La synchronisation est momentanément impossible. Réessayez plus tard.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: ProColors.primary),
              ),
            );
          }
          final all = snapshot.data!;
          final appointments = all
              .where(
                (appointment) => switch (_filter) {
                  _AppointmentFilter.all => true,
                  _AppointmentFilter.pending =>
                    appointment.status == ProfessionalAppointmentStatus.pending,
                  _AppointmentFilter.confirmed =>
                    appointment.status ==
                        ProfessionalAppointmentStatus.confirmed,
                  _AppointmentFilter.cancelled =>
                    appointment.status ==
                        ProfessionalAppointmentStatus.cancelled,
                },
              )
              .toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_AppointmentFilter>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _AppointmentFilter.all,
                      label: Text('Toutes (${all.length})'),
                    ),
                    ButtonSegment(
                      value: _AppointmentFilter.pending,
                      label: Text(
                        'En attente (${_count(all, ProfessionalAppointmentStatus.pending)})',
                      ),
                    ),
                    ButtonSegment(
                      value: _AppointmentFilter.confirmed,
                      label: Text(
                        'Confirmées (${_count(all, ProfessionalAppointmentStatus.confirmed)})',
                      ),
                    ),
                    ButtonSegment(
                      value: _AppointmentFilter.cancelled,
                      label: Text(
                        'Annulées (${_count(all, ProfessionalAppointmentStatus.cancelled)})',
                      ),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (selection) =>
                      setState(() => _filter = selection.first),
                ),
              ),
              const SizedBox(height: 18),
              if (appointments.isEmpty)
                _AppointmentsMessage(
                  icon: Icons.event_available_outlined,
                  title: all.isEmpty
                      ? 'Aucune demande reçue'
                      : 'Aucune demande dans ce filtre',
                  message: all.isEmpty
                      ? 'Les réservations envoyées depuis l’application patient apparaîtront ici.'
                      : 'Sélectionnez un autre statut pour voir vos rendez-vous.',
                )
              else
                for (final appointment in appointments) ...[
                  _AppointmentRequestCard(
                    appointment: appointment,
                    processing: _processingId == appointment.id,
                    onConfirm:
                        appointment.status ==
                            ProfessionalAppointmentStatus.pending
                        ? () => _respond(
                            appointment,
                            ProfessionalAppointmentStatus.confirmed,
                          )
                        : null,
                    onEdit:
                        appointment.status !=
                            ProfessionalAppointmentStatus.cancelled
                        ? () => _edit(appointment)
                        : null,
                    onCancel:
                        appointment.status !=
                            ProfessionalAppointmentStatus.cancelled
                        ? () => _respond(
                            appointment,
                            ProfessionalAppointmentStatus.cancelled,
                          )
                        : null,
                    onDelete:
                        appointment.status ==
                            ProfessionalAppointmentStatus.cancelled
                        ? () => _delete(appointment)
                        : null,
                    onKeepPending:
                        appointment.status ==
                            ProfessionalAppointmentStatus.pending
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('La demande reste en attente.'),
                              ),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 13),
                ],
            ],
          );
        },
      ),
    ],
  );
}

int _count(
  List<ProfessionalAppointment> appointments,
  ProfessionalAppointmentStatus status,
) => appointments.where((item) => item.status == status).length;

class _AppointmentRequestCard extends StatelessWidget {
  final ProfessionalAppointment appointment;
  final bool processing;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onKeepPending;

  const _AppointmentRequestCard({
    required this.appointment,
    required this.processing,
    this.onConfirm,
    this.onEdit,
    this.onCancel,
    this.onDelete,
    this.onKeepPending,
  });

  @override
  Widget build(BuildContext context) {
    final pending = appointment.status == ProfessionalAppointmentStatus.pending;
    final statusColor = switch (appointment.status) {
      ProfessionalAppointmentStatus.pending => const Color(0xFF98610A),
      ProfessionalAppointmentStatus.confirmed => ProColors.success,
      ProfessionalAppointmentStatus.cancelled => const Color(0xFFB42318),
    };
    final statusBackground = switch (appointment.status) {
      ProfessionalAppointmentStatus.pending => const Color(0xFFFFF4DF),
      ProfessionalAppointmentStatus.confirmed => const Color(0xFFE7F7EF),
      ProfessionalAppointmentStatus.cancelled => const Color(0xFFFFECE9),
    };
    return ProPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ProColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _initials(appointment.patientName),
                  style: const TextStyle(
                    color: ProColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(
                        color: ProColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      appointment.service,
                      style: const TextStyle(color: ProColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointment.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RequestInformation(
            icon: Icons.event_outlined,
            text: _longDateTime(appointment.scheduledAt),
          ),
          const SizedBox(height: 10),
          _RequestInformation(
            icon: _modeIcon(appointment.mode),
            text: appointment.mode.label,
          ),
          const SizedBox(height: 10),
          _RequestInformation(
            icon: _paymentMethodIcon(appointment.paymentMethod),
            text: 'Paiement : ${appointment.paymentMethod.label}',
          ),
          if (appointment.location.isNotEmpty) ...[
            const SizedBox(height: 10),
            _RequestInformation(
              icon: Icons.location_on_outlined,
              text: appointment.location,
            ),
          ],
          if (appointment.patientNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            _RequestInformation(
              icon: Icons.notes_rounded,
              text: appointment.patientNote,
            ),
          ],
          if (appointment.responseNote.isNotEmpty) ...[
            const Divider(height: 28, color: ProColors.border),
            Text(
              'Votre réponse : ${appointment.responseNote}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ],
          if (appointment.cancellationNote.isNotEmpty) ...[
            const Divider(height: 28, color: ProColors.border),
            Text(
              'Annulation${appointment.cancelledBy == 'patient' ? ' par le patient' : ''} : ${appointment.cancellationNote}',
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (onConfirm != null ||
              onEdit != null ||
              onCancel != null ||
              onDelete != null ||
              onKeepPending != null) ...[
            const Divider(height: 28, color: ProColors.border),
            if (processing)
              const LinearProgressIndicator(color: ProColors.primary)
            else
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  if (onConfirm != null)
                    FilledButton.icon(
                      key: ValueKey('confirm-${appointment.id}'),
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Valider'),
                    ),
                  if (onEdit != null)
                    OutlinedButton.icon(
                      key: ValueKey('edit-${appointment.id}'),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier'),
                    ),
                  if (onCancel != null)
                    OutlinedButton.icon(
                      key: ValueKey('cancel-${appointment.id}'),
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Annuler'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      key: ValueKey('delete-${appointment.id}'),
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Supprimer'),
                    ),
                  if (pending && onKeepPending != null)
                    TextButton(
                      onPressed: onKeepPending,
                      child: const Text('Garder en attente'),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _RequestInformation extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RequestInformation({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: ProColors.primary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: ProColors.ink,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _AppointmentsMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _AppointmentsMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 40, color: ProColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ProColors.muted, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  final result = parts.map((part) => part[0].toUpperCase()).join();
  return result.isEmpty ? 'PA' : result;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _shortDate(DateTime value) =>
    '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';

IconData _modeIcon(ProfessionalAppointmentMode mode) => switch (mode) {
  ProfessionalAppointmentMode.atProvider => Icons.directions_walk_rounded,
  ProfessionalAppointmentMode.homeVisit => Icons.home_work_rounded,
  ProfessionalAppointmentMode.video => Icons.video_camera_front_rounded,
};

IconData _paymentMethodIcon(ProfessionalAppointmentPaymentMethod method) =>
    switch (method) {
      ProfessionalAppointmentPaymentMethod.cash => Icons.payments_outlined,
      ProfessionalAppointmentPaymentMethod.monCash =>
        Icons.phone_android_rounded,
      ProfessionalAppointmentPaymentMethod.natCash =>
        Icons.account_balance_wallet_outlined,
      ProfessionalAppointmentPaymentMethod.bankTransfer =>
        Icons.account_balance_outlined,
      ProfessionalAppointmentPaymentMethod.card => Icons.credit_card_rounded,
    };

String _longDateTime(DateTime value) {
  const weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${weekdays[value.weekday - 1]} ${value.day} ${months[value.month - 1]} ${value.year} à ${_twoDigits(value.hour)} h ${_twoDigits(value.minute)}';
}
