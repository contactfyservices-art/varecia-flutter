import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

/// Suit combien de nouveaux éléments sont apparus dans une sous-collection
/// (gallery_items, posts_items, library_items) depuis la dernière fois
/// que l'utilisateur a ouvert l'onglet correspondant.
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

  Stream<int> watchUnseenCount(String collectionName) async* {
    final lastSeen = await _lastSeen(collectionName);
    yield* _fs.watchItems(collectionName).map((items) {
      final unseen = items.length - lastSeen;
      return unseen > 0 ? unseen : 0;
    });
  }

  Future<void> markSeenNow(String collectionName) async {
    final items = await _fs.watchItems(collectionName).first;
    await markSeen(collectionName, items.length);
  }
}
