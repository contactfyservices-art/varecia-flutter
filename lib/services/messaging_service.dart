import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class MessagingService {
  MessagingService._();
  static final instance = MessagingService._();

  final _fs = FirestoreService.instance;

  String conversationKey(String emailA, String emailB) {
    final sorted = [emailA, emailB]..sort();
    return 'conv_${sorted[0]}__${sorted[1]}';
  }

  Stream<List<Map<String, dynamic>>> watchConversation(
      String emailA, String emailB) {
    final key = conversationKey(emailA, emailB);
    return _fs.watchJSON(key, []).map(
        (data) => List<Map<String, dynamic>>.from(data as List));
  }

  Future<void> sendMessage({
    required String fromEmail,
    required String fromName,
    required String toEmail,
    required String text,
  }) async {
    final key = conversationKey(fromEmail, toEmail);
    final messages = await _fs.getJSON(key, []) as List;
    messages.add({
      'from': fromEmail,
      'fromName': fromName,
      'text': text,
      'date': DateTime.now().toIso8601String(),
    });
    await _fs.setJSON(key, messages);
  }

  Future<DateTime?> _lastRead(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString('lastRead_$key');
    return iso == null ? null : DateTime.tryParse(iso);
  }

  /// Marque la conversation comme lue à l'instant présent.
  Future<void> markConversationRead(String myEmail, String peerEmail) async {
    final key = conversationKey(myEmail, peerEmail);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastRead_$key', DateTime.now().toIso8601String());
  }

  /// Vrai si le dernier message de la conversation vient du pair (pas de
  /// moi) et est arrivé après la dernière fois où j'ai ouvert cette
  /// conversation.
  Stream<bool> watchHasUnread(String myEmail, String peerEmail) async* {
    final key = conversationKey(myEmail, peerEmail);
    final lastRead = await _lastRead(key);
    yield* watchConversation(myEmail, peerEmail).map((messages) {
      if (messages.isEmpty) return false;
      final last = messages.last;
      if (last['from'] == myEmail) return false;
      final date = DateTime.tryParse(last['date'] ?? '');
      if (date == null) return false;
      if (lastRead == null) return true;
      return date.isAfter(lastRead);
    });
  }
}
