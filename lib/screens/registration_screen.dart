import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/professional_repository.dart';
import '../models/provider_profile.dart';
import '../theme/pro_theme.dart';

class ProRegistrationScreen extends StatefulWidget {
  final String uid;
  final String accountEmail;
  final String accountName;
  final ProfessionalRepository repository;
  final ProviderProfile? initialProfile;

  const ProRegistrationScreen({
    super.key,
    required this.uid,
    required this.accountEmail,
    required this.accountName,
    required this.repository,
    this.initialProfile,
  });

  bool get isEditing => initialProfile != null;

  @override
  State<ProRegistrationScreen> createState() => _ProRegistrationScreenState();
}

class _ProRegistrationScreenState extends State<ProRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late ProviderAccountType _accountType;
  late final Map<String, TextEditingController> _controllers;
  bool _termsAccepted = false;
  bool _saving = false;
  String? _error;

  ProviderProfile? get _initial => widget.initialProfile;

  @override
  void initState() {
    super.initState();
    _accountType = _initial?.accountType ?? ProviderAccountType.professional;
    _termsAccepted = _initial?.termsAccepted ?? false;
    _controllers = {
      'displayName': TextEditingController(
        text: _initial?.displayName ?? widget.accountName,
      ),
      'category': TextEditingController(text: _initial?.category ?? ''),
      'registrationNumber': TextEditingController(
        text: _initial?.registrationNumber ?? '',
      ),
      'contactPerson': TextEditingController(
        text: _initial?.contactPerson ?? '',
      ),
      'workplace': TextEditingController(text: _initial?.workplace ?? ''),
      'phone': TextEditingController(text: _initial?.phone ?? ''),
      'email': TextEditingController(
        text: _initial?.email ?? widget.accountEmail,
      ),
      'address': TextEditingController(text: _initial?.address ?? ''),
      'description': TextEditingController(text: _initial?.description ?? ''),
      'experience': TextEditingController(text: _initial?.experience ?? ''),
      'qualifications': TextEditingController(
        text: _initial?.qualifications ?? '',
      ),
      'services': TextEditingController(text: _initial?.services ?? ''),
      'schedule': TextEditingController(text: _initial?.schedule ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _controllers[key]!.text.trim();

  ProviderProfile _buildProfile() => ProviderProfile(
    ownerUid: widget.uid,
    accountType: _accountType,
    displayName: _text('displayName'),
    category: _text('category'),
    registrationNumber: _text('registrationNumber'),
    contactPerson: _text('contactPerson'),
    workplace: _text('workplace'),
    phone: _text('phone'),
    email: _text('email'),
    address: _text('address'),
    description: _text('description'),
    experience: _text('experience'),
    qualifications: _text('qualifications'),
    services: _text('services'),
    schedule: _text('schedule'),
    available: _initial?.available ?? true,
    isVisible: _initial?.isVisible ?? false,
    verificationStatus:
        _initial?.verificationStatus ?? ProviderVerificationStatus.pending,
    rejectionReason: _initial?.rejectionReason ?? '',
    termsAccepted: _termsAccepted,
  );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() == true;
    if (!valid || !_termsAccepted) {
      setState(() {
        _error = !_termsAccepted
            ? 'Veuillez accepter les conditions de publication.'
            : null;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = _buildProfile();
      if (widget.isEditing) {
        await widget.repository.updateProfile(profile);
      } else {
        await widget.repository.submitProfile(profile);
      }
      if (mounted && widget.isEditing) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Enregistrement impossible. Vérifiez votre connexion.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Ce champ est requis.' : null;

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Ce champ est requis.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'Saisissez une adresse e-mail valide.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: widget.isEditing,
      title: const ProBrand(),
      actions: [
        if (!widget.isEditing)
          TextButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Déconnexion'),
          ),
        const SizedBox(width: 10),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 56),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RegistrationHeading(isEditing: widget.isEditing),
                  const SizedBox(height: 28),
                  if (!widget.isEditing) ...[
                    Text(
                      '1. Choisissez votre espace',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    _AccountTypeSelector(
                      selected: _accountType,
                      onSelected: (value) =>
                          setState(() => _accountType = value),
                    ),
                    const SizedBox(height: 26),
                  ],
                  ProPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormSectionTitle(
                          number: widget.isEditing ? null : '2',
                          title:
                              _accountType == ProviderAccountType.professional
                              ? 'Identité professionnelle'
                              : 'Identité de l’institution',
                          subtitle:
                              'Ces informations servent à la vérification et à votre future fiche.',
                        ),
                        const SizedBox(height: 22),
                        _ResponsiveFields(
                          children: [
                            ProField(
                              fieldKey: const ValueKey('display-name-field'),
                              controller: _controllers['displayName']!,
                              label:
                                  _accountType ==
                                      ProviderAccountType.professional
                                  ? 'Nom complet *'
                                  : 'Nom officiel *',
                              hint:
                                  _accountType ==
                                      ProviderAccountType.professional
                                  ? 'Dr Jean Exemple'
                                  : 'Clinique Exemple',
                              validator: _required,
                            ),
                            ProField(
                              controller: _controllers['category']!,
                              label:
                                  _accountType ==
                                      ProviderAccountType.professional
                                  ? 'Profession ou spécialité *'
                                  : 'Type d’institution *',
                              hint:
                                  _accountType ==
                                      ProviderAccountType.professional
                                  ? 'Médecin généraliste'
                                  : 'Hôpital, clinique, laboratoire…',
                              validator: _required,
                            ),
                            ProField(
                              controller: _controllers['registrationNumber']!,
                              label:
                                  _accountType ==
                                      ProviderAccountType.professional
                                  ? 'Numéro de licence / ordre *'
                                  : 'Numéro d’enregistrement *',
                              hint: 'Référence officielle',
                              validator: _required,
                            ),
                            if (_accountType == ProviderAccountType.institution)
                              ProField(
                                controller: _controllers['contactPerson']!,
                                label: 'Responsable du compte *',
                                hint: 'Nom et fonction',
                                validator: _required,
                              )
                            else
                              ProField(
                                controller: _controllers['workplace']!,
                                label: 'Établissement principal',
                                hint: 'Cabinet, clinique ou hôpital',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ProPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FormSectionTitle(
                          title: 'Coordonnées publiques',
                          subtitle:
                              'Indiquez comment les patients peuvent vous trouver et vous joindre.',
                        ),
                        const SizedBox(height: 22),
                        _ResponsiveFields(
                          children: [
                            ProField(
                              controller: _controllers['phone']!,
                              label: 'Téléphone *',
                              hint: '+509 …',
                              keyboardType: TextInputType.phone,
                              validator: _required,
                            ),
                            ProField(
                              controller: _controllers['email']!,
                              label: 'E-mail professionnel *',
                              hint: 'contact@exemple.ht',
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            ProField(
                              controller: _controllers['address']!,
                              label: 'Adresse complète *',
                              hint: 'Rue, commune, département',
                              validator: _required,
                              fullWidth: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ProPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FormSectionTitle(
                          title: 'Présentation de votre activité',
                          subtitle:
                              'Un profil détaillé aide les patients à choisir le bon service.',
                        ),
                        const SizedBox(height: 22),
                        _ResponsiveFields(
                          children: [
                            ProField(
                              controller: _controllers['description']!,
                              label: 'Présentation *',
                              hint:
                                  'Décrivez votre approche, votre mission ou votre établissement.',
                              maxLines: 4,
                              validator: _required,
                              fullWidth: true,
                            ),
                            if (_accountType ==
                                ProviderAccountType.professional) ...[
                              ProField(
                                controller: _controllers['experience']!,
                                label: 'Expérience',
                                hint: 'Ex. 8 ans d’expérience',
                              ),
                              ProField(
                                controller: _controllers['qualifications']!,
                                label: 'Formation et qualifications',
                                hint: 'Diplômes, certifications…',
                              ),
                            ],
                            ProField(
                              controller: _controllers['services']!,
                              label: 'Services et expertises *',
                              hint:
                                  'Consultation, pédiatrie, analyses, urgences…',
                              maxLines: 3,
                              validator: _required,
                            ),
                            ProField(
                              controller: _controllers['schedule']!,
                              label: 'Horaires *',
                              hint: 'Lun–Ven, 8 h–16 h',
                              maxLines: 3,
                              validator: _required,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ProPanel(
                    child: Column(
                      children: [
                        CheckboxListTile(
                          key: const ValueKey('pro-terms-checkbox'),
                          value: _termsAccepted,
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                  () => _termsAccepted = value == true,
                                ),
                          contentPadding: EdgeInsets.zero,
                          activeColor: ProColors.primary,
                          title: const Text(
                            'Je certifie l’exactitude de ces informations et j’accepte leur publication après validation.',
                            style: TextStyle(
                              color: ProColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFB42318),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.isEditing) ...[
                              OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text('Annuler'),
                              ),
                              const SizedBox(width: 12),
                            ],
                            FilledButton.icon(
                              key: const ValueKey('pro-submit-profile'),
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      widget.isEditing
                                          ? Icons.save_outlined
                                          : Icons.send_outlined,
                                    ),
                              label: Text(
                                widget.isEditing
                                    ? 'Enregistrer'
                                    : 'Soumettre pour validation',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RegistrationHeading extends StatelessWidget {
  final bool isEditing;

  const _RegistrationHeading({required this.isEditing});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: ProColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isEditing ? 'GESTION DU PROFIL' : 'INSCRIPTION PROFESSIONNELLE',
          style: const TextStyle(
            color: ProColors.primaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        isEditing
            ? 'Mettez votre fiche à jour'
            : 'Rejoignez l’annuaire i-ENTIER',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 9),
      Text(
        isEditing
            ? 'Vos modifications seront reflétées dans l’annuaire lorsque votre profil est publié.'
            : 'Renseignez votre activité. Notre équipe vérifiera les informations avant leur publication.',
        style: const TextStyle(color: ProColors.muted, fontSize: 16),
      ),
    ],
  );
}

class _AccountTypeSelector extends StatelessWidget {
  final ProviderAccountType selected;
  final ValueChanged<ProviderAccountType> onSelected;

  const _AccountTypeSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = constraints.maxWidth < 620;
      final professional = _AccountTypeCard(
        key: const ValueKey('type-professional'),
        icon: Icons.medical_services_outlined,
        title: 'Personnel de santé',
        description:
            'Médecin, infirmier, psychologue, pharmacien ou autre praticien.',
        selected: selected == ProviderAccountType.professional,
        onTap: () => onSelected(ProviderAccountType.professional),
      );
      final institution = _AccountTypeCard(
        key: const ValueKey('type-institution'),
        icon: Icons.local_hospital_outlined,
        title: 'Institution de santé',
        description:
            'Hôpital, clinique, laboratoire, pharmacie ou centre de soins.',
        selected: selected == ProviderAccountType.institution,
        onTap: () => onSelected(ProviderAccountType.institution),
      );
      if (stacked) {
        return Column(
          children: [professional, const SizedBox(height: 12), institution],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: professional),
            const SizedBox(width: 14),
            Expanded(child: institution),
          ],
        ),
      );
    },
  );
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _AccountTypeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? ProColors.primarySoft : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: selected ? ProColors.primary : ProColors.border,
        width: selected ? 1.7 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? ProColors.primary : const Color(0xFFF0F5F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : ProColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ProColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: ProColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? ProColors.primary : ProColors.border,
            ),
          ],
        ),
      ),
    ),
  );
}

class _FormSectionTitle extends StatelessWidget {
  final String? number;
  final String title;
  final String subtitle;

  const _FormSectionTitle({
    this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (number != null) ...[
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: ProColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ProColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: ProColors.muted)),
          ],
        ),
      ),
    ],
  );
}

class _ResponsiveFields extends StatelessWidget {
  final List<ProField> children;

  const _ResponsiveFields({required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 16.0;
      final twoColumns = constraints.maxWidth >= 650;
      final itemWidth = twoColumns
          ? (constraints.maxWidth - spacing) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: spacing,
        runSpacing: 16,
        children: [
          for (final field in children)
            SizedBox(
              width: field.fullWidth || !twoColumns
                  ? constraints.maxWidth
                  : itemWidth,
              child: field,
            ),
        ],
      );
    },
  );
}

class ProField extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool fullWidth;

  const ProField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: ProColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        key: fieldKey,
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}
