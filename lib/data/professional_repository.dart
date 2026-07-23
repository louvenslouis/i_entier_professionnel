import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider_profile.dart';

abstract class ProfessionalRepository {
  Stream<ProviderProfile?> watchProfile(String uid);

  Future<void> submitProfile(ProviderProfile profile);

  Future<void> updateProfile(ProviderProfile profile);

  Future<void> setVisibility(ProviderProfile profile, bool isVisible);

  Future<void> setAvailability(ProviderProfile profile, bool available);
}

class FirestoreProfessionalRepository implements ProfessionalRepository {
  final FirebaseFirestore firestore;

  FirestoreProfessionalRepository({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      firestore.collection('providerProfiles').doc(uid);

  DocumentReference<Map<String, dynamic>> _directory(ProviderProfile profile) =>
      firestore
          .collection(
            profile.accountType == ProviderAccountType.professional
                ? 'personnelMedical'
                : 'institution',
          )
          .doc(profile.ownerUid);

  @override
  Stream<ProviderProfile?> watchProfile(String uid) =>
      _profile(uid).snapshots().map(
        (document) =>
            document.exists ? ProviderProfile.fromFirestore(document) : null,
      );

  @override
  Future<void> submitProfile(ProviderProfile profile) =>
      _profile(profile.ownerUid).set(profile.toCreateMap());

  @override
  Future<void> updateProfile(ProviderProfile profile) async {
    if (!profile.isApproved || !profile.isVisible) {
      await _profile(profile.ownerUid).update(profile.toEditableMap());
      return;
    }
    final directory = _directory(profile);
    final existing = await directory.get();
    final batch = firestore.batch()
      ..update(_profile(profile.ownerUid), profile.toEditableMap())
      ..set(
        directory,
        _directoryData(profile, exists: existing.exists),
        SetOptions(merge: true),
      );
    await batch.commit();
  }

  @override
  Future<void> setVisibility(ProviderProfile profile, bool isVisible) async {
    if (!profile.isApproved) {
      throw StateError('Le profil doit être validé avant sa publication.');
    }
    final updated = profile.copyWith(isVisible: isVisible);
    final directory = _directory(updated);
    final existing = await directory.get();
    final batch = firestore.batch()
      ..update(_profile(profile.ownerUid), {
        'isVisible': isVisible,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    if (isVisible) {
      batch.set(
        directory,
        _directoryData(updated, exists: existing.exists),
        SetOptions(merge: true),
      );
    } else if (existing.exists) {
      batch.delete(directory);
    }
    await batch.commit();
  }

  @override
  Future<void> setAvailability(ProviderProfile profile, bool available) async {
    final updated = profile.copyWith(available: available);
    if (!profile.isApproved || !profile.isVisible) {
      await _profile(profile.ownerUid).update({
        'available': available,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final directory = _directory(updated);
    final existing = await directory.get();
    final batch = firestore.batch()
      ..update(_profile(profile.ownerUid), {
        'available': available,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        directory,
        _directoryData(updated, exists: existing.exists),
        SetOptions(merge: true),
      );
    await batch.commit();
  }

  Map<String, dynamic> _directoryData(
    ProviderProfile profile, {
    required bool exists,
  }) => {
    ...profile.toDirectoryMap(),
    if (!exists) 'createdAt': FieldValue.serverTimestamp(),
  };
}
