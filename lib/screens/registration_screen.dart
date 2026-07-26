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
  bool _atProviderEnabled = false;
  bool _homeVisitEnabled = false;
  bool _videoEnabled = false;
  bool _institutionPricesPublished = false;
  late final Map<String, _AvailabilityConfiguration>
  _availabilityConfigurations;
  String? _error;

  ProviderProfile? get _initial => widget.initialProfile;

  @override
  void initState() {
    super.initState();
    _accountType = _initial?.accountType ?? ProviderAccountType.professional;
    _termsAccepted = _initial?.termsAccepted ?? false;
    _atProviderEnabled = _initial?.atProviderEnabled ?? false;
    _homeVisitEnabled = _initial?.homeVisitEnabled ?? false;
    _videoEnabled = _initial?.videoEnabled ?? false;
    _institutionPricesPublished = _initial?.institutionPricesPublished ?? false;
    _availabilityConfigurations = {
      'inPerson': _AvailabilityConfiguration.fromStorage(
        _initial?.availabilityConfigurations['inPerson'],
        _initial?.atProviderSchedule.isNotEmpty == true
            ? _initial!.atProviderSchedule
            : _initial?.schedule ?? '',
      ),
      'homeVisit': _AvailabilityConfiguration.fromStorage(
        _initial?.availabilityConfigurations['homeVisit'],
        _initial?.homeVisitSchedule ?? '',
      ),
      'video': _AvailabilityConfiguration.fromStorage(
        _initial?.availabilityConfigurations['video'],
        _initial?.videoSchedule ?? '',
      ),
    };
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
      'defaultPrice': TextEditingController(text: _initial?.defaultPrice ?? ''),
      'servicePrices': TextEditingController(
        text: _initial?.servicePrices ?? '',
      ),
      'roomPrices': TextEditingController(text: _initial?.roomPrices ?? ''),
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

  List<String> get _categorySuggestions =>
      _accountType == ProviderAccountType.professional
      ? const [
          'Médecin généraliste',
          'Pédiatre',
          'Gynécologue-obstétricien',
          'Cardiologue',
          'Dermatologue',
          'Psychologue',
          'Infirmier·ère',
          'Dentiste',
          'Pharmacien·ne',
          'Kinésithérapeute',
        ]
      : const [
          'Hôpital',
          'Clinique',
          'Centre de santé',
          'Laboratoire',
          'Pharmacie',
          'Cabinet médical',
          'Centre de réadaptation',
          'Centre de maternité',
        ];

  List<String> get _serviceSuggestions =>
      _accountType == ProviderAccountType.professional
      ? const [
          'Consultation générale',
          'Suivi médical',
          'Dépistage',
          'Vaccination',
          'Soins infirmiers',
          'Téléconsultation',
          'Visite à domicile',
          'Conseils de prévention',
        ]
      : const [
          'Consultations',
          'Urgences',
          'Hospitalisation',
          'Laboratoire et analyses',
          'Imagerie médicale',
          'Pharmacie',
          'Vaccination',
          'Maternité',
          'Ambulance',
        ];

  List<String> _serviceValues() => _text('services')
      .split(RegExp(r'[,;\n]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  bool _hasService(String service) => _serviceValues().any(
    (value) => value.toLowerCase() == service.toLowerCase(),
  );

  void _setCategory(String category, bool selected) =>
      setState(() => _controllers['category']!.text = selected ? category : '');

  void _toggleService(String service, bool selected) {
    final values = _serviceValues();
    values.removeWhere((value) => value.toLowerCase() == service.toLowerCase());
    if (selected) values.add(service);
    setState(() => _controllers['services']!.text = values.join(', '));
  }

  _AvailabilityConfiguration _availabilityFor(String mode) =>
      _availabilityConfigurations[mode]!;

  void _setAvailabilityConfiguration(
    String mode,
    _AvailabilityConfiguration configuration,
  ) => setState(() => _availabilityConfigurations[mode] = configuration);

  String _professionalScheduleSummary() => [
    if (_atProviderEnabled) 'Sur place : ${_availabilityFor('inPerson').label}',
    if (_homeVisitEnabled)
      'À domicile : ${_availabilityFor('homeVisit').label}',
    if (_videoEnabled) 'Visioconférence : ${_availabilityFor('video').label}',
  ].join('\n');

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
    schedule: _accountType == ProviderAccountType.professional
        ? _professionalScheduleSummary()
        : _text('schedule'),
    atProviderSchedule: _accountType == ProviderAccountType.professional
        ? (_atProviderEnabled ? _availabilityFor('inPerson').label : '')
        : '',
    homeVisitSchedule: _accountType == ProviderAccountType.professional
        ? (_homeVisitEnabled ? _availabilityFor('homeVisit').label : '')
        : '',
    videoSchedule: _accountType == ProviderAccountType.professional
        ? (_videoEnabled ? _availabilityFor('video').label : '')
        : '',
    defaultPrice: _accountType == ProviderAccountType.professional
        ? _text('defaultPrice')
        : '',
    institutionPricesPublished:
        _accountType == ProviderAccountType.institution &&
        _institutionPricesPublished,
    servicePrices: _accountType == ProviderAccountType.institution
        ? _text('servicePrices')
        : '',
    roomPrices: _accountType == ProviderAccountType.institution
        ? _text('roomPrices')
        : '',
    availabilityConfigurations: _accountType == ProviderAccountType.professional
        ? {
            for (final entry in _availabilityConfigurations.entries)
              entry.key: entry.value.toStorageMap(),
          }
        : const <String, Map<String, dynamic>>{},
    atProviderEnabled:
        _accountType == ProviderAccountType.professional && _atProviderEnabled,
    homeVisitEnabled:
        _accountType == ProviderAccountType.professional && _homeVisitEnabled,
    videoEnabled:
        _accountType == ProviderAccountType.professional && _videoEnabled,
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

  String? _priceValidator(String? value) {
    final price = value?.trim() ?? '';
    if (price.isEmpty) return null;
    final normalized = price
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.');
    if (double.tryParse(normalized) == null) {
      return 'Saisissez un montant valide.';
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
                              fieldKey: const ValueKey('category-field'),
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
                        const SizedBox(height: 18),
                        _SuggestedChoices(
                          title:
                              _accountType == ProviderAccountType.professional
                              ? 'Spécialités suggérées'
                              : 'Types d’institution suggérés',
                          subtitle:
                              'Cochez une suggestion ou saisissez une autre valeur dans le champ ci-dessus.',
                          choices: _categorySuggestions,
                          isSelected: (choice) =>
                              _text('category').toLowerCase() ==
                              choice.toLowerCase(),
                          onChanged: _setCategory,
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
                              fieldKey: const ValueKey('services-field'),
                              controller: _controllers['services']!,
                              label: 'Services et expertises *',
                              hint:
                                  'Consultation, pédiatrie, analyses, urgences…',
                              maxLines: 3,
                              validator: _required,
                            ),
                            if (_accountType !=
                                ProviderAccountType.professional)
                              ProField(
                                controller: _controllers['schedule']!,
                                label: 'Horaires *',
                                hint: 'Lun–Ven, 8 h–16 h',
                                maxLines: 3,
                                validator: _required,
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SuggestedChoices(
                          title: 'Services et expertises suggérés',
                          subtitle:
                              'Vous pouvez cocher plusieurs propositions et compléter librement le champ.',
                          choices: _serviceSuggestions,
                          isSelected: _hasService,
                          onChanged: _toggleService,
                        ),
                      ],
                    ),
                  ),
                  if (_accountType == ProviderAccountType.professional) ...[
                    const SizedBox(height: 18),
                    ProPanel(
                      child: _AppointmentModeConfiguration(
                        atProviderEnabled: _atProviderEnabled,
                        homeVisitEnabled: _homeVisitEnabled,
                        videoEnabled: _videoEnabled,
                        atProviderConfiguration: _availabilityFor('inPerson'),
                        homeVisitConfiguration: _availabilityFor('homeVisit'),
                        videoConfiguration: _availabilityFor('video'),
                        defaultPrice: _controllers['defaultPrice']!,
                        onAtProviderEnabledChanged: _saving
                            ? null
                            : (value) =>
                                  setState(() => _atProviderEnabled = value),
                        onHomeVisitEnabledChanged: _saving
                            ? null
                            : (value) =>
                                  setState(() => _homeVisitEnabled = value),
                        onVideoEnabledChanged: _saving
                            ? null
                            : (value) => setState(() => _videoEnabled = value),
                        onAtProviderConfigurationChanged: _saving
                            ? null
                            : (configuration) => _setAvailabilityConfiguration(
                                'inPerson',
                                configuration,
                              ),
                        onHomeVisitConfigurationChanged: _saving
                            ? null
                            : (configuration) => _setAvailabilityConfiguration(
                                'homeVisit',
                                configuration,
                              ),
                        onVideoConfigurationChanged: _saving
                            ? null
                            : (configuration) => _setAvailabilityConfiguration(
                                'video',
                                configuration,
                              ),
                        priceValidator: _priceValidator,
                      ),
                    ),
                  ],
                  if (_accountType == ProviderAccountType.institution) ...[
                    const SizedBox(height: 18),
                    ProPanel(
                      child: _InstitutionPriceConfiguration(
                        published: _institutionPricesPublished,
                        servicePrices: _controllers['servicePrices']!,
                        roomPrices: _controllers['roomPrices']!,
                        onPublishedChanged: _saving
                            ? null
                            : (value) => setState(
                                () => _institutionPricesPublished = value,
                              ),
                      ),
                    ),
                  ],
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

class _SuggestedChoices extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> choices;
  final bool Function(String choice) isSelected;
  final void Function(String choice, bool selected) onChanged;

  const _SuggestedChoices({
    required this.title,
    required this.subtitle,
    required this.choices,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: ProColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: ProColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final choice in choices)
            FilterChip(
              key: ValueKey('suggestion-$choice'),
              label: Text(choice),
              selected: isSelected(choice),
              showCheckmark: true,
              selectedColor: ProColors.primarySoft,
              checkmarkColor: ProColors.primaryDark,
              labelStyle: TextStyle(
                color: isSelected(choice)
                    ? ProColors.primaryDark
                    : ProColors.ink,
                fontWeight: isSelected(choice)
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
              onSelected: (selected) => onChanged(choice, selected),
            ),
        ],
      ),
    ],
  );
}

class _InstitutionPriceConfiguration extends StatelessWidget {
  final bool published;
  final TextEditingController servicePrices;
  final TextEditingController roomPrices;
  final ValueChanged<bool>? onPublishedChanged;

  const _InstitutionPriceConfiguration({
    required this.published,
    required this.servicePrices,
    required this.roomPrices,
    required this.onPublishedChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _FormSectionTitle(
        title: 'Tarifs de l’institution',
        subtitle:
            'Vous décidez si ces montants sont visibles par les patients dans l’annuaire.',
      ),
      const SizedBox(height: 10),
      SwitchListTile.adaptive(
        key: const ValueKey('institution-prices-published-switch'),
        contentPadding: EdgeInsets.zero,
        value: published,
        onChanged: onPublishedChanged,
        activeThumbColor: ProColors.primary,
        title: const Text(
          'Publier les tarifs',
          style: TextStyle(color: ProColors.ink, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          published
              ? 'Les tarifs ci-dessous seront visibles publiquement.'
              : 'Les tarifs restent privés et ne sont pas affichés dans l’annuaire.',
        ),
      ),
      if (published) ...[
        const SizedBox(height: 12),
        ProField(
          fieldKey: const ValueKey('institution-service-prices-field'),
          controller: servicePrices,
          label: 'Tarifs des services (HTG)',
          hint: 'Ex. Consultation générale : 2 500\nÉchographie : 4 000',
          maxLines: 4,
          fullWidth: true,
        ),
        const SizedBox(height: 14),
        ProField(
          fieldKey: const ValueKey('institution-room-prices-field'),
          controller: roomPrices,
          label: 'Tarifs des chambres (HTG)',
          hint: 'Ex. Chambre standard : 6 000 / nuit\nSuite : 12 000 / nuit',
          maxLines: 4,
          fullWidth: true,
        ),
      ],
    ],
  );
}

class _AppointmentModeConfiguration extends StatelessWidget {
  final bool atProviderEnabled;
  final bool homeVisitEnabled;
  final bool videoEnabled;
  final _AvailabilityConfiguration atProviderConfiguration;
  final _AvailabilityConfiguration homeVisitConfiguration;
  final _AvailabilityConfiguration videoConfiguration;
  final TextEditingController defaultPrice;
  final ValueChanged<bool>? onAtProviderEnabledChanged;
  final ValueChanged<bool>? onHomeVisitEnabledChanged;
  final ValueChanged<bool>? onVideoEnabledChanged;
  final ValueChanged<_AvailabilityConfiguration>?
  onAtProviderConfigurationChanged;
  final ValueChanged<_AvailabilityConfiguration>?
  onHomeVisitConfigurationChanged;
  final ValueChanged<_AvailabilityConfiguration>? onVideoConfigurationChanged;
  final String? Function(String?)? priceValidator;

  const _AppointmentModeConfiguration({
    required this.atProviderEnabled,
    required this.homeVisitEnabled,
    required this.videoEnabled,
    required this.atProviderConfiguration,
    required this.homeVisitConfiguration,
    required this.videoConfiguration,
    required this.defaultPrice,
    required this.onAtProviderEnabledChanged,
    required this.onHomeVisitEnabledChanged,
    required this.onVideoEnabledChanged,
    required this.onAtProviderConfigurationChanged,
    required this.onHomeVisitConfigurationChanged,
    required this.onVideoConfigurationChanged,
    required this.priceValidator,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _FormSectionTitle(
        title: 'Options de rendez-vous',
        subtitle:
            'Activez uniquement les modalités que vous proposez, puis renseignez leur disponibilité.',
      ),
      const SizedBox(height: 16),
      _AppointmentModeSetting(
        switchKey: const ValueKey('at-provider-enabled-switch'),
        icon: Icons.local_hospital_outlined,
        title: 'Consultation sur place',
        subtitle: 'Le patient se déplace vers votre lieu de consultation.',
        enabled: atProviderEnabled,
        onChanged: onAtProviderEnabledChanged,
        scheduleField: atProviderEnabled
            ? _AvailabilityConfigurationEditor(
                modeKey: 'inPerson',
                configuration: atProviderConfiguration,
                onChanged: onAtProviderConfigurationChanged,
              )
            : null,
      ),
      const Divider(height: 28, color: ProColors.border),
      _AppointmentModeSetting(
        switchKey: const ValueKey('home-visit-enabled-switch'),
        icon: Icons.home_work_outlined,
        title: 'Visite à domicile',
        subtitle: 'Vous vous déplacez à l’adresse indiquée par le patient.',
        enabled: homeVisitEnabled,
        onChanged: onHomeVisitEnabledChanged,
        scheduleField: homeVisitEnabled
            ? _AvailabilityConfigurationEditor(
                modeKey: 'homeVisit',
                configuration: homeVisitConfiguration,
                onChanged: onHomeVisitConfigurationChanged,
              )
            : null,
      ),
      const Divider(height: 28, color: ProColors.border),
      _AppointmentModeSetting(
        switchKey: const ValueKey('video-enabled-switch'),
        icon: Icons.video_camera_front_outlined,
        title: 'Visioconférence',
        subtitle: 'La consultation se déroule à distance.',
        enabled: videoEnabled,
        onChanged: onVideoEnabledChanged,
        scheduleField: videoEnabled
            ? _AvailabilityConfigurationEditor(
                modeKey: 'video',
                configuration: videoConfiguration,
                onChanged: onVideoConfigurationChanged,
              )
            : null,
      ),
      const SizedBox(height: 18),
      ProField(
        fieldKey: const ValueKey('default-price-field'),
        controller: defaultPrice,
        label: 'Prix par défaut (HTG)',
        hint: 'Ex. 2 500',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: priceValidator,
        fullWidth: true,
      ),
    ],
  );
}

class _AppointmentModeSetting extends StatelessWidget {
  final Key switchKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final Widget? scheduleField;

  const _AppointmentModeSetting({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    this.scheduleField,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ProColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ProColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ProColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: ProColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(key: switchKey, value: enabled, onChanged: onChanged),
        ],
      ),
      if (scheduleField != null) ...[
        const SizedBox(height: 14),
        scheduleField!,
      ],
    ],
  );
}

class _AvailabilityConfigurationEditor extends StatelessWidget {
  final String modeKey;
  final _AvailabilityConfiguration configuration;
  final ValueChanged<_AvailabilityConfiguration>? onChanged;

  const _AvailabilityConfigurationEditor({
    required this.modeKey,
    required this.configuration,
    required this.onChanged,
  });

  Future<void> _pickTime(BuildContext context, {required bool opening}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: opening
          ? configuration.openingTime
          : configuration.closingTime,
      helpText: opening ? 'Heure de début' : 'Heure de fin',
    );
    if (selected == null) return;
    final updated = opening
        ? configuration.copyWith(openingTime: selected)
        : configuration.copyWith(closingTime: selected);
    if (updated.closingMinutes <= updated.openingMinutes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L’heure de fin doit être après l’heure de début.'),
          ),
        );
      }
      return;
    }
    onChanged?.call(updated);
  }

  Future<void> _pickPeriod(BuildContext context) async {
    final initialRange =
        configuration.validFrom != null && configuration.validUntil != null
        ? DateTimeRange(
            start: configuration.validFrom!,
            end: configuration.validUntil!,
          )
        : null;
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      helpText: 'Période de disponibilité',
      saveText: 'Appliquer',
    );
    if (selected != null) {
      onChanged?.call(
        configuration.copyWith(
          validFrom: selected.start,
          validUntil: selected.end,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Jours disponibles',
        style: TextStyle(color: ProColors.ink, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final day in _AvailabilityConfiguration.weekdayOptions)
            FilterChip(
              key: ValueKey('availability-$modeKey-day-${day.value}'),
              label: Text(day.shortLabel),
              selected: configuration.weekdays.contains(day.value),
              showCheckmark: true,
              selectedColor: ProColors.primarySoft,
              checkmarkColor: ProColors.primaryDark,
              onSelected: onChanged == null
                  ? null
                  : (selected) {
                      final selectedDays = {...configuration.weekdays};
                      if (selected) {
                        selectedDays.add(day.value);
                      } else if (selectedDays.length > 1) {
                        selectedDays.remove(day.value);
                      }
                      onChanged?.call(
                        configuration.copyWith(weekdays: selectedDays),
                      );
                    },
            ),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        'Créneau horaire',
        style: TextStyle(color: ProColors.ink, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            key: ValueKey('availability-$modeKey-opening-time'),
            onPressed: onChanged == null
                ? null
                : () => _pickTime(context, opening: true),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: Text('Début : ${configuration.openingLabel}'),
          ),
          OutlinedButton.icon(
            key: ValueKey('availability-$modeKey-closing-time'),
            onPressed: onChanged == null
                ? null
                : () => _pickTime(context, opening: false),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text('Fin : ${configuration.closingLabel}'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        key: ValueKey('availability-$modeKey-period'),
        onPressed: onChanged == null ? null : () => _pickPeriod(context),
        icon: const Icon(Icons.date_range_outlined, size: 18),
        label: Text(configuration.periodLabel),
      ),
      if (configuration.validFrom != null) ...[
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onChanged == null
              ? null
              : () =>
                    onChanged?.call(configuration.copyWith(clearPeriod: true)),
          icon: const Icon(Icons.clear_rounded, size: 16),
          label: const Text('Retirer la période'),
        ),
      ],
      const SizedBox(height: 8),
      Text(
        'Aperçu : ${configuration.label}',
        style: const TextStyle(color: ProColors.muted, fontSize: 12),
      ),
    ],
  );
}

class _AvailabilityConfiguration {
  final Set<int> weekdays;
  final TimeOfDay openingTime;
  final TimeOfDay closingTime;
  final DateTime? validFrom;
  final DateTime? validUntil;

  const _AvailabilityConfiguration({
    required this.weekdays,
    required this.openingTime,
    required this.closingTime,
    this.validFrom,
    this.validUntil,
  });

  static const weekdayOptions = <_AvailabilityWeekday>[
    _AvailabilityWeekday(1, 'Lun'),
    _AvailabilityWeekday(2, 'Mar'),
    _AvailabilityWeekday(3, 'Mer'),
    _AvailabilityWeekday(4, 'Jeu'),
    _AvailabilityWeekday(5, 'Ven'),
    _AvailabilityWeekday(6, 'Sam'),
    _AvailabilityWeekday(7, 'Dim'),
  ];

  factory _AvailabilityConfiguration.fromStorage(
    Map<String, dynamic>? value,
    String fallbackSchedule,
  ) {
    final storedDays = value?['weekdays'];
    final days = storedDays is Iterable
        ? storedDays
              .whereType<num>()
              .map((day) => day.toInt())
              .where((day) => day >= 1 && day <= 7)
              .toSet()
        : _weekdaysFromSchedule(fallbackSchedule);
    return _AvailabilityConfiguration(
      weekdays: days.isEmpty ? {1, 2, 3, 4, 5} : days,
      openingTime: _timeFromText(
        value?['openingTime']?.toString(),
        fallbackSchedule,
        fallbackIndex: 0,
      ),
      closingTime: _timeFromText(
        value?['closingTime']?.toString(),
        fallbackSchedule,
        fallbackIndex: 1,
      ),
      validFrom: DateTime.tryParse(value?['validFrom']?.toString() ?? ''),
      validUntil: DateTime.tryParse(value?['validUntil']?.toString() ?? ''),
    );
  }

  _AvailabilityConfiguration copyWith({
    Set<int>? weekdays,
    TimeOfDay? openingTime,
    TimeOfDay? closingTime,
    DateTime? validFrom,
    DateTime? validUntil,
    bool clearPeriod = false,
  }) => _AvailabilityConfiguration(
    weekdays: weekdays ?? this.weekdays,
    openingTime: openingTime ?? this.openingTime,
    closingTime: closingTime ?? this.closingTime,
    validFrom: clearPeriod ? null : validFrom ?? this.validFrom,
    validUntil: clearPeriod ? null : validUntil ?? this.validUntil,
  );

  int get openingMinutes => openingTime.hour * 60 + openingTime.minute;
  int get closingMinutes => closingTime.hour * 60 + closingTime.minute;
  String get openingLabel => _formatTime(openingTime);
  String get closingLabel => _formatTime(closingTime);
  String get label => '${_dayLabel(weekdays)}, $openingLabel–$closingLabel';
  String get periodLabel => validFrom == null
      ? 'Définir une période de validité (facultatif)'
      : 'Du ${_formatDate(validFrom!)} au ${_formatDate(validUntil!)}';

  Map<String, dynamic> toStorageMap() => {
    'weekdays': weekdays.toList()..sort(),
    'openingTime': _storageTime(openingTime),
    'closingTime': _storageTime(closingTime),
    'validFrom': validFrom == null ? '' : _storageDate(validFrom!),
    'validUntil': validUntil == null ? '' : _storageDate(validUntil!),
  };

  static Set<int> _weekdaysFromSchedule(String schedule) {
    final normalized = schedule.toLowerCase();
    final range = RegExp(
      r'(lun|mar|mer|jeu|ven|sam|dim)\s*[–-]\s*(lun|mar|mer|jeu|ven|sam|dim)',
    ).firstMatch(normalized);
    int? dayFor(String? value) => switch (value) {
      'lun' => 1,
      'mar' => 2,
      'mer' => 3,
      'jeu' => 4,
      'ven' => 5,
      'sam' => 6,
      'dim' => 7,
      _ => null,
    };
    if (range != null) {
      final start = dayFor(range.group(1))!;
      final end = dayFor(range.group(2))!;
      return {for (var day = start; day <= end; day++) day};
    }
    return {
      for (final day in weekdayOptions)
        if (normalized.contains(day.shortLabel.toLowerCase())) day.value,
    };
  }

  static TimeOfDay _timeFromText(
    String? stored,
    String fallback, {
    required int fallbackIndex,
  }) {
    final storedMatch = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(stored ?? '');
    if (storedMatch != null) {
      return TimeOfDay(
        hour: int.parse(storedMatch.group(1)!),
        minute: int.parse(storedMatch.group(2)!),
      );
    }
    final matches = RegExp(
      r'(\d{1,2})\s*h(?:\s*(\d{1,2}))?',
    ).allMatches(fallback).toList();
    if (matches.length > fallbackIndex) {
      final match = matches[fallbackIndex];
      return TimeOfDay(
        hour: int.parse(match.group(1)!),
        minute: int.tryParse(match.group(2) ?? '') ?? 0,
      );
    }
    return TimeOfDay(hour: fallbackIndex == 0 ? 8 : 16, minute: 0);
  }

  static String _dayLabel(Set<int> days) {
    final ordered = days.toList()..sort();
    if (ordered.length > 1 &&
        ordered.every((day) => day >= ordered.first && day <= ordered.last) &&
        ordered.length == ordered.last - ordered.first + 1) {
      return '${weekdayOptions[ordered.first - 1].shortLabel}–${weekdayOptions[ordered.last - 1].shortLabel}';
    }
    return ordered.map((day) => weekdayOptions[day - 1].shortLabel).join(', ');
  }

  static String _formatTime(TimeOfDay time) => time.minute == 0
      ? '${time.hour} h'
      : '${time.hour} h ${time.minute.toString().padLeft(2, '0')}';
  static String _storageTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  static String _storageDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _AvailabilityWeekday {
  final int value;
  final String shortLabel;

  const _AvailabilityWeekday(this.value, this.shortLabel);
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
