# Varecia App — Projet Flutter

Application mobile de l'Association Varecia. Reconstruction Flutter native
de la version web/PWA, avec le même backend Firebase (Firestore, collection
`app_data`) — les données existantes restent utilisables telles quelles.

## ⚠️ Étape obligatoire avant le premier build : enregistrer l'app Android dans Firebase

Le projet Firebase `association-varecia` existe déjà (utilisé par la
version web), mais il n'a pour l'instant qu'une app **web** enregistrée.
Pour que Flutter/Android puisse s'y connecter, il faut ajouter une app
Android :

1. Va sur https://console.firebase.google.com/ → projet **association-varecia**
2. ⚙️ **Paramètres du projet** → onglet **Général** → section "Vos applications"
3. Clique l'icône **Android** pour ajouter une application
4. **Nom du package Android** : `com.varecia.app` (doit correspondre exactement à `android/app/build.gradle`, champ `applicationId` — déjà configuré ainsi dans ce projet)
5. Télécharge le fichier **`google-services.json`** généré
6. Place-le dans `android/app/google-services.json` (ce fichier est dans `.gitignore` — il ne sera jamais poussé sur GitHub, c'est normal et voulu)
7. Ouvre `lib/firebase_options.dart` et remplace `apiKey` et `appId` de la section `android` par les valeurs trouvées dans le `google-services.json` téléchargé (champs `current_key` et `mobilesdk_app_id`)

## Mise en ligne sur GitHub

```bash
git init
git add .
git commit -m "Version initiale Varecia App Flutter"
git branch -M main
git remote add origin https://github.com/TON-COMPTE/varecia-app.git
git push -u origin main
```

## Build de l'APK via Codemagic

1. Sur https://codemagic.io, connecte le repo `varecia-app` (déjà relié si tu t'es connecté avec GitHub)
2. Codemagic détecte automatiquement le fichier `codemagic.yaml` à la racine
3. Avant de lancer le build, va dans les paramètres du workflow et remplace `votre-email@exemple.com` par ton adresse (pour recevoir l'APK par e-mail une fois le build terminé) — ou modifie directement `codemagic.yaml` et repush
4. Lance le build (**Start new build**)
5. Une fois terminé (~5-10 min), télécharge l'APK depuis l'onglet **Artifacts** ou récupère-le par e-mail
6. Transfère l'APK sur un téléphone Android (Xender, câble USB...) et installe-le (autoriser "sources inconnues" si demandé)

## Sons (à ajouter toi-même)

Le dossier `assets/sounds/` est vide — ajoute deux fichiers courts (< 1 seconde) :
- `success.mp3` — son doux pour les actions réussies
- `error.mp3` — son distinct pour les erreurs

Le code (`lib/services/sound_service.dart`) les utilise déjà ; l'appli
fonctionne normalement même sans ces fichiers (le son est juste ignoré).

## Développement local (optionnel)

Si tu veux tester sur ta machine avant de passer par Codemagic :
```bash
flutter pub get
flutter run
```

## Structure du projet

```
lib/
  main.dart                    # Point d'entrée
  firebase_options.dart        # Config Firebase (à compléter, voir plus haut)
  theme/                       # Couleurs, typographie, thème aeroglass
  widgets/glass_card.dart      # Composant glassmorphism réutilisable
  models/models.dart           # Modèles de données (User, Post, GalleryItem...)
  services/
    firestore_service.dart     # Lecture/écriture Firestore (équivalent getJSON/setJSON)
    auth_service.dart          # Authentification interne (comptes gérés dans Firestore)
    sound_service.dart         # Sons de l'application
  screens/
    auth/                      # Bienvenue, connexion, inscription, admin, mot de passe oublié
    home_shell.dart            # Navigation principale (toujours visible)
    pages/                     # Accueil, Bibliothèque, Réunion, Galerie, Notes, Profil, Admin
```
