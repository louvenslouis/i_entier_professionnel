import 'package:flutter/material.dart';

import '../data/insurance_coverage_repository.dart';
import '../models/insurance_coverage_review.dart';
import '../models/provider_profile.dart';
import '../theme/pro_theme.dart';

class InsuranceCoverageValidationScreen extends StatelessWidget {
  final ProviderProfile profile;
  final InsuranceCoverageProfessionalRepository repository;

  const InsuranceCoverageValidationScreen({
    super.key,
    required this.profile,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (!profile.isApproved ||
        profile.accountType != ProviderAccountType.professional) {
      return const ProPanel(
        child: Column(
          children: [
            Icon(Icons.lock_outline_rounded, color: ProColors.muted, size: 42),
            SizedBox(height: 12),
            Text(
              'Validation non disponible',
              style: TextStyle(
                color: ProColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Votre profil professionnel doit être approuvé avant de vérifier les couvertures des patients.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return StreamBuilder<List<InsuranceCoverageReview>>(
      stream: repository.watchCoverages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const ProPanel(
            child: Text(
              'Impossible de charger les cartes d’assurance. Vérifiez votre accès et votre connexion.',
            ),
          );
        }
        final coverages = snapshot.data ?? const [];
        final pending = coverages.where((item) => item.pending).toList();
        final reviewed = coverages.where((item) => !item.pending).toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Couvertures médicales',
                        style: TextStyle(
                          color: ProColors.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Vérifiez le recto, le verso et la période de validité de chaque carte OFATMA.',
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: ProColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pending.length} en attente',
                    style: const TextStyle(
                      color: ProColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (pending.isEmpty)
              const ProPanel(
                child: Row(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      color: ProColors.success,
                      size: 34,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Aucune carte en attente de validation.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final coverage in pending) ...[
                _CoverageReviewCard(coverage: coverage, repository: repository),
                const SizedBox(height: 14),
              ],
            if (reviewed.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Dossiers récemment traités',
                style: TextStyle(
                  color: ProColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              for (final coverage in reviewed.take(8))
                _ReviewedCoverageTile(coverage: coverage),
            ],
          ],
        );
      },
    );
  }
}

class _CoverageReviewCard extends StatefulWidget {
  final InsuranceCoverageReview coverage;
  final InsuranceCoverageProfessionalRepository repository;

  const _CoverageReviewCard({required this.coverage, required this.repository});

  @override
  State<_CoverageReviewCard> createState() => _CoverageReviewCardState();
}

class _CoverageReviewCardState extends State<_CoverageReviewCard> {
  bool _saving = false;

  Future<void> _showCard(String path, String side) async {
    try {
      final url = await widget.repository.createCardUrl(path);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Carte OFATMA — $side',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    minScale: .8,
                    maxScale: 5,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(36),
                        child: Text('Impossible d’afficher cette image.'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) _message('Impossible d’ouvrir cette face de la carte.');
    }
  }

  Future<void> _approve() async {
    final result = await showDialog<_ApprovalResult>(
      context: context,
      builder: (_) => const _ApprovalDialog(),
    );
    if (result == null) return;
    await _review(
      approve: true,
      reason: result.note,
      validUntil: result.validUntil,
    );
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectionDialog(),
    );
    if (reason == null) return;
    await _review(approve: false, reason: reason);
  }

  Future<void> _review({
    required bool approve,
    required String reason,
    DateTime? validUntil,
  }) async {
    setState(() => _saving = true);
    try {
      await widget.repository.reviewCoverage(
        coverageId: widget.coverage.id,
        approve: approve,
        reason: reason,
        validUntil: validUntil,
      );
      if (mounted) {
        _message(
          approve
              ? 'La couverture OFATMA est maintenant valide.'
              : 'Le refus a été transmis au patient.',
        );
      }
    } catch (_) {
      if (mounted) _message('La décision n’a pas pu être enregistrée.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => ProPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ProColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                color: ProColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.coverage.patientName,
                    style: const TextStyle(
                      color: ProColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${widget.coverage.insurerCode}${widget.coverage.memberNumber.isEmpty ? '' : ' • ${widget.coverage.memberNumber}'}',
                  ),
                ],
              ),
            ),
            Text(
              _date(widget.coverage.submittedAt),
              style: const TextStyle(color: ProColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final buttons = [
              OutlinedButton.icon(
                key: ValueKey('view-front-${widget.coverage.id}'),
                onPressed: () => _showCard(widget.coverage.frontPath, 'recto'),
                icon: const Icon(Icons.credit_card_outlined),
                label: const Text('Voir le recto'),
              ),
              OutlinedButton.icon(
                key: ValueKey('view-back-${widget.coverage.id}'),
                onPressed: () => _showCard(widget.coverage.backPath, 'verso'),
                icon: const Icon(Icons.flip_to_back_outlined),
                label: const Text('Voir le verso'),
              ),
            ];
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [buttons[0], const SizedBox(height: 10), buttons[1]],
              );
            }
            return Row(
              children: [
                Expanded(child: buttons[0]),
                const SizedBox(width: 12),
                Expanded(child: buttons[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: ValueKey('reject-coverage-${widget.coverage.id}'),
                onPressed: _saving ? null : _reject,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Refuser'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: ValueKey('approve-coverage-${widget.coverage.id}'),
                onPressed: _saving ? null : _approve,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_rounded),
                label: const Text('Valider'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ApprovalResult {
  final DateTime validUntil;
  final String note;
  const _ApprovalResult(this.validUntil, this.note);
}

class _ApprovalDialog extends StatefulWidget {
  const _ApprovalDialog();

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _note = TextEditingController();
  DateTime? _validUntil;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Fin de validité OFATMA',
    );
    if (value != null) setState(() => _validUntil = value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Valider la couverture'),
    content: SizedBox(
      width: 430,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: _pickDate,
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Date de fin de validité'),
            subtitle: Text(
              _validUntil == null ? 'Obligatoire' : _date(_validUntil!),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note interne ou précision (facultatif)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _validUntil == null
            ? null
            : () => Navigator.pop(
                context,
                _ApprovalResult(_validUntil!, _note.text.trim()),
              ),
        child: const Text('Confirmer la validité'),
      ),
    ],
  );
}

class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog();

  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Refuser la carte'),
    content: SizedBox(
      width: 430,
      child: TextField(
        controller: _reason,
        autofocus: true,
        maxLength: 1000,
        minLines: 3,
        maxLines: 5,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Motif transmis au patient',
          hintText: 'Ex. verso illisible ou carte expirée',
          alignLabelWithHint: true,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _reason.text.trim().length < 5
            ? null
            : () => Navigator.pop(context, _reason.text.trim()),
        child: const Text('Confirmer le refus'),
      ),
    ],
  );
}

class _ReviewedCoverageTile extends StatelessWidget {
  final InsuranceCoverageReview coverage;
  const _ReviewedCoverageTile({required this.coverage});

  @override
  Widget build(BuildContext context) {
    final verified = coverage.status == 'verified';
    final color = verified ? ProColors.success : const Color(0xFFB42318);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: Icon(
          verified ? Icons.verified_outlined : Icons.cancel_outlined,
          color: color,
        ),
        title: Text('${coverage.patientName} • ${coverage.insurerCode}'),
        subtitle: Text(
          verified && coverage.validUntil != null
              ? 'Valide jusqu’au ${_date(coverage.validUntil!)}'
              : coverage.reviewNote,
        ),
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
