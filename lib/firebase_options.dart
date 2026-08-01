// Généré manuellement pour le projet Firebase "association-varecia".
//
// ⚠️ IMPORTANT — Config Android manquante :
// Les valeurs ci-dessous (apiKey, appId, messagingSenderId) sont celles de
// l'app WEB déjà enregistrée dans la console Firebase. Pour builder l'APK
// Android, il faut enregistrer une app Android supplémentaire dans le
// même projet Firebase :
//   1. Console Firebase > association-varecia > ⚙️ Paramètres du projet
//   2. "Ajouter une application" > Android
//   3. Package name Android : com.varecia.app (ou celui choisi dans
//      android/app/build.gradle)
//   4. Télécharger google-services.json et le placer dans android/app/
//   5. Remplacer android.apiKey et android.appId ci-dessous par les
//      valeurs du google-services.json téléchargé (section "client")
//
// Voir le README.md à la racine pour le détail de cette étape.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyBhyKrFCiT_m0P2eXvvRXCcn_HFNk8WIPM',
    authDomain: 'association-varecia.firebaseapp.com',
    projectId: 'association-varecia',
    storageBucket: 'association-varecia.firebasestorage.app',
    messagingSenderId: '701202517558',
    appId: '1:701202517558:web:785e2c6d58060ae197d297',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyA-4qz2I6lJCDYLlPehnheut7PFIFZV6Y4',
    appId: '1:701202517558:android:8ae5614467416c5397d297',
    messagingSenderId: '701202517558',
    projectId: 'association-varecia',
    storageBucket: 'association-varecia.firebasestorage.app',
  );

  static const ios = android; // à adapter si build iOS envisagé un jour
}
