import 'package:flutter/material.dart';
import '../services/messaging_service.dart';

/// Petit point rouge superposé sur l'avatar d'un membre s'il a envoyé
/// un message pas encore ouvert par l'utilisateur actuel.
class UnreadDot extends StatelessWidget {
  final String myEmail;
  final String peerEmail;
  const UnreadDot({super.key, required this.myEmail, required this.peerEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: MessagingService.instance.watchHasUnread(myEmail, peerEmail),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox();
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        );
      },
    );
  }
}
