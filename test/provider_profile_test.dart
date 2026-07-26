import 'package:flutter_test/flutter_test.dart';
import 'package:i_entier_professionnel/models/provider_profile.dart';

ProviderProfile institutionProfile() => const ProviderProfile(
  ownerUid: 'institution-1',
  accountType: ProviderAccountType.institution,
  displayName: 'Clinique Espoir',
  category: 'Clinique',
  registrationNumber: 'REG-123',
  contactPerson: 'Jean Paul',
  workplace: '',
  phone: '+509 2222-0000',
  email: 'contact@example.ht',
  address: 'Pétion-Ville, Ouest',
  description: 'Des soins de proximité.',
  experience: '',
  qualifications: '',
  services: 'Consultations, hospitalisation',
  schedule: 'Lun–Ven, 8 h–16 h',
  available: true,
  isVisible: true,
  verificationStatus: ProviderVerificationStatus.approved,
  rejectionReason: '',
  termsAccepted: true,
);

void main() {
  test('publie les tarifs d’une institution uniquement avec son accord', () {
    final institution = institutionProfile().copyWith(
      institutionPricesPublished: true,
      servicePrices: 'Consultation : 2 500',
      roomPrices: 'Chambre standard : 6 000 / nuit',
    );

    final directory = institution.toDirectoryMap();
    expect(directory['tarifsPublies'], isTrue);
    expect(directory['tarifsServices'], 'Consultation : 2 500');
    expect(directory['tarifsChambres'], 'Chambre standard : 6 000 / nuit');

    final privateDirectory = institution
        .copyWith(institutionPricesPublished: false)
        .toDirectoryMap();
    expect(privateDirectory['tarifsPublies'], isFalse);
    expect(privateDirectory['tarifsServices'], isEmpty);
    expect(privateDirectory['tarifsChambres'], isEmpty);
  });
}
