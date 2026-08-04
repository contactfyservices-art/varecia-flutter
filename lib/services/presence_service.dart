import 'firestore_service.dart';

/// Suit la dernière activité de chaque utilisateur (horodatage stocké
/// dans un document dédié, léger — juste un email -> date ISO par
/// personne, pas de risque de grossir vers la limite de 1 Mo).
class PresenceService {
  PresenceService._();
  static final instance = PresenceService._();

  final _fs = FirestoreService.instance;

  Future<void> heartbeat(String email) async {
    final data = await _fs.getJSON('presence', <String, dynamic>{});
    final map = Map<String, dynamic>.from(data);
    map[email] = DateTime.now().toIso8601String();
    await _fs.setJSON('presence', map);
  }

  Stream<Map<String, dynamic>> watchAll() {
    return _fs
        .watchJSON('presence', <String, dynamic>{})
        .map((d) => Map<String, dynamic>.from(d));
  }

  /// "En ligne" si actif dans les 2 dernières minutes.
  static bool isOnline(String? isoDate) {
    if (isoDate == null) return false;
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return false;
    return DateTime.now().difference(dt).inMinutes < 2;
  }

  static String label(String? isoDate) {
    if (isoDate == null) return 'Jamais connecté';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return 'Jamais connecté';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'En ligne';
    if (diff.inMinutes < 60) return 'Vu il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Vu il y a ${diff.inHours} h';
    return 'Vu il y a ${diff.inDays} j';
  }
}
