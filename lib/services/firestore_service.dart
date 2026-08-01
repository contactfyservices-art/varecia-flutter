import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Réplique la logique getJSON/setJSON de la version HTML : chaque "clé"
/// (users, posts, gallery, library, meeting, adminCode, appVersion, logo...)
/// correspond à un document de la collection `app_data`, avec un champ
/// `value` contenant le JSON encodé — exactement le même format que
/// l'ancienne version web, pour rester compatible avec les données déjà
/// créées dans Firestore.
class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference get _appData => _db.collection('app_data');

  Future<dynamic> getJSON(String key, dynamic fallback) async {
    try {
      final doc = await _appData.doc(key).get();
      if (!doc.exists) return fallback;
      final data = doc.data() as Map<String, dynamic>?;
      final raw = data?['value'];
      if (raw == null) return fallback;
      return jsonDecode(raw);
    } catch (e) {
      return fallback;
    }
  }

  Future<void> setJSON(String key, dynamic value) async {
    await _appData.doc(key).set({'value': jsonEncode(value)});
  }

  /// Écoute en temps réel un document — pratique pour les écrans qui
  /// doivent se rafraîchir automatiquement (réunion active, nouveaux posts...)
  Stream<dynamic> watchJSON(String key, dynamic fallback) {
    return _appData.doc(key).snapshots().map((doc) {
      if (!doc.exists) return fallback;
      final data = doc.data() as Map<String, dynamic>?;
      final raw = data?['value'];
      if (raw == null) return fallback;
      return jsonDecode(raw);
    });
  }
}
