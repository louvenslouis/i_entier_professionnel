# i-ENTIER Professionnel

Application Flutter autonome pour les personnels et institutions de santé.
Elle partage le projet Supabase i-ENTIER avec les applications Patient et
Administration.

## Parcours inclus

- connexion Google par Supabase Auth ;
- inscription comme professionnel ou institution ;
- dossier professionnel et statut de vérification ;
- publication, visibilité et disponibilité ;
- liaison d’un professionnel à une institution ;
- réception et traitement atomique des rendez-vous ;
- page dédiée aux appels vidéo Patient–Professionnel avec LiveKit.

Les profils sont stockés dans `ientier.provider_profiles`. Les rendez-vous sont
partagés dans `ientier.appointments`; les réponses passent par la fonction SQL
`ientier.respond_to_appointment`.

## Lancer et vérifier

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

Le schéma mobile `com.ientier.i_entier_professionnel://login-callback` doit
figurer dans la liste des Redirect URLs de Supabase Auth. Le schéma SQL et les
migrations sont maintenus dans `../ientier/supabase/migrations`.

L’activation LiveKit et le nettoyage des salles sont documentés dans
`../ientier/docs/VIDEO_CALLS_SETUP.md`. Le module `lib/video_calls` est synchronisé
depuis le dépôt Patient via `python3 tools/sync_video_calls.py` exécuté là-bas.
Les invitations nécessitent une application ouverte ; la réception native
quand l’application est fermée n’est pas encore intégrée.

La fiche patient vidéo utilise la RPC `ientier.video_patient_details`, appliquée
par la migration distante `add_video_patient_details`. Sa définition est conservée
dans `docs/sql/video_patient_details.sql`. Elle réserve la lecture au professionnel
du rendez-vous vidéo confirmé. Préserver cette extension professionnelle lors
d’une synchronisation du module depuis le dépôt Patient.

Les actions de consultation sont dans `lib/consultations` et accessibles depuis
la fiche patient vidéo ainsi que l’historique des appels. La RPC atomique
`ientier.publish_video_consultation` relie les diagnostics à
`consultation_documents`, les ordonnances à `prescriptions` et
`prescription_items`, les examens à `laboratory_exam_requests` et les suivis à
un nouveau rendez-vous confirmé dans `appointments`. Chaque envoi crée sa
notification patient et conserve une clé d’idempotence lors des reprises réseau.
Les documents envoyés sont en lecture seule pour les deux participants.

Les migrations correspondantes sont conservées dans le dépôt Patient :
`20261010225128_add_video_consultation_actions`,
`20261010234506_fix_consultation_appointment_trigger_context` et
`20261011013816_restrict_consultation_to_identified_accounts`.
La définition SQL consolidée et les tests transactionnels avec rollback se
trouvent dans `docs/sql/video_consultation_actions.sql` et
`docs/sql/test_video_consultation_actions.sql`. Les vues de documents partagées
(`consultation_repository.dart`, `consultation_document_view.dart`) existent
dans les deux applications ; conserver leur cohérence lors des changements.
