# i-ENTIER Professionnel

Projet Flutter autonome destiné aux personnels et institutions de santé qui
souhaitent s’inscrire et gérer leur présence dans l’annuaire i-ENTIER.

Le projet se trouve dans son propre dossier
`AndroidStudioProjects/i_entier_professionnel`
et ne dépend pas du code de l’application patient `ientier`. Il partage
uniquement le projet Firebase `i-entier`, afin de publier les fiches validées
dans les collections déjà lues par l’annuaire patient.

## Parcours inclus

- connexion Google distincte ;
- inscription comme personnel de santé ou institution ;
- collecte des informations professionnelles et des coordonnées publiques ;
- statut de vérification `pending`, `approved` ou `rejected` ;
- tableau de bord responsive mobile/web ;
- modification du profil ;
- gestion de la visibilité et de la disponibilité ;
- recherche d’une institution existante et liaison au profil d’un personnel ;
- réception des demandes de rendez-vous envoyées par les patients ;
- validation, annulation ou maintien en attente avec notification du patient ;
- aperçu de la fiche destinée aux patients.

Les demandes complètes sont stockées dans `providerProfiles/{uid}`. Cette
collection reste privée. Après validation, l’utilisateur peut publier sa fiche
dans `personnelMedical/{uid}` ou `institution/{uid}`. Masquer une fiche la
retire de l’annuaire public sans supprimer le profil professionnel privé.
Les réservations sont partagées dans `appointments/{id}`. Lorsqu’une demande
est confirmée ou annulée, la décision et la notification du patient sont
enregistrées dans une même opération Firestore.

Un personnel de santé peut rechercher les fiches publiées de la collection
`institution` depuis la page **Mon institution**. La relation est enregistrée
dans `providerProfiles/{uid}` avec `linkedInstitutionId` et
`linkedInstitutionName`, puis synchronisée vers sa fiche `personnelMedical`
lorsque celle-ci est publiée.

## Lancer le projet

```sh
flutter pub get
flutter run -d chrome
```

Pour vérifier le projet :

```sh
flutter analyze
flutter test
flutter build web
```

## Firebase

Les applications Firebase dédiées ont été enregistrées avec les identifiants :

- Android : `com.ientier.i_entier_professionnel`
- iOS : `com.ientier.iEntierProfessionnel`
- Web : application web existante du projet `i-entier`

Google Sign-In doit rester activé dans Firebase Authentication. Pour Android,
ajoutez les empreintes SHA-1/SHA-256 des clés de signature avant une mise en
production.

Les règles professionnelles sont intégrées au ruleset partagé maintenu dans
`../ientier/firestore.rules` et déployées sur le projet `i-entier`. Le fichier
[docs/firestore_provider.rules](docs/firestore_provider.rules) en conserve le
fragment de référence ; il ne doit jamais être déployé seul, car le même
ruleset protège aussi les données médicales de l’application patient.

La validation d’un compte doit être effectuée par un backend Admin SDK ou
manuellement par un administrateur : le client ne peut pas s’auto-attribuer le
statut `approved`.
