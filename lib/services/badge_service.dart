import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

/// Suit combien de nouvelles publications (galerie, notes, bibliothèque)
/// sont apparues depuis la dernière fois que l'utilisateur a ouvert
/// chaque onglet — pour afficher un petit badge rouge, sans notification
/// système (pas besoin du plan Firebase payant).
class BadgeService {
  BadgeService._();
  static final instance = BadgeService._();

  final _fs = FirestoreService.instance;

  Future<int> _lastSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastSeen_$key') ?? 0;
  }

  Future<void> markSeen(String key, int currentCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSeen_$key', currentCount);
  }

  /// Retourne un flux du nombre de nouveaux éléments non vus pour une
  /// clé donnée (ex: 'gallery', 'posts', 'library').
  Stream<int> watchUnseenCount(String key) async* {
    final lastSeen = await _lastSeen(key);
    yield* _fs.watchJSON(key, []).map((data) {
      final total = (data as List).length;
      final unseen = total - lastSeen;
      return unseen > 0 ? unseen : 0;
    });
  }
}
