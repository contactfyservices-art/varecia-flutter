import 'firestore_service.dart';

/// Messagerie privée entre membres, stockée dans app_data comme le
/// reste de l'appli — chaque conversation est un document dont la clé
/// est les deux e-mails triés alphabétiquement et combinés, pour que
/// les deux personnes retombent toujours sur le même document.
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
}
