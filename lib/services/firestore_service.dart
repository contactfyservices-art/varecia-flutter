import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// Service d'accès à Firestore. Conserve les méthodes historiques
/// getJSON/setJSON/watchJSON (documents uniques, utilisées par users,
/// admins, adminCode, meeting, appVersion, content_accueil, conv_*)
/// ET ajoute de nouvelles méthodes basées sur des SOUS-COLLECTIONS
/// pour tout ce qui grossit sans limite (galerie, notes, bibliothèque)
/// — chaque élément devient son propre petit document au lieu d'un
/// tableau géant, ce qui évite la limite de 1 Mo par document Firestore.
class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;
  DocumentReference get _root => _db.collection('app_data').doc('main');

  // === Ancien système (document unique, tableau JSON) — inchangé ===
  Future<dynamic> getJSON(String key, dynamic fallback) async {
    final snap = await _root.get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey(key)) return fallback;
    final raw = data[key];
    if (raw is String) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return fallback;
      }
    }
    return raw ?? fallback;
  }

  Future<void> setJSON(String key, dynamic value) async {
    await _root.set({key: value}, SetOptions(merge: true));
  }

  Stream<dynamic> watchJSON(String key, dynamic fallback) {
    return _root.snapshots().map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey(key)) return fallback;
      return data[key] ?? fallback;
    });
  }

  // === Nouveau système (sous-collection, un document par élément) ===
  CollectionReference _col(String name) =>
      _db.collection('app_data').doc('main').collection(name);

  /// Ajoute un nouvel élément (photo, note, ressource...) comme document
  /// individuel — retourne son identifiant Firestore.
  Future<String> addItem(String collectionName, Map<String, dynamic> data) async {
    final doc = await _col(collectionName).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateItem(
      String collectionName, String docId, Map<String, dynamic> data) async {
    await _col(collectionName).doc(docId).update(data);
  }

  Future<void> deleteItem(String collectionName, String docId) async {
    await _col(collectionName).doc(docId).delete();
  }

  /// Flux des éléments les plus récents en premier, avec leur id Firestore
  /// inclus sous la clé 'id' de chaque map.
  Stream<List<Map<String, dynamic>>> watchItems(String collectionName) {
    return _col(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final map = Map<String, dynamic>.from(d.data() as Map);
              map['id'] = d.id;
              return map;
            }).toList());
  }
}
