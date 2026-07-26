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
- réception et traitement atomique des rendez-vous.

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
