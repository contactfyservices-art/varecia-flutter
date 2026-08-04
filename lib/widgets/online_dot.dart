import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/presence_service.dart';

/// Petit rond vert affiché en superposition sur un avatar si la
/// personne est en ligne. Texte optionnel ("En ligne" / "Vu il y a...").
class OnlineDot extends StatelessWidget {
  final String email;
  const OnlineDot({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: PresenceService.instance.watchAll(),
      builder: (context, snapshot) {
        final map = snapshot.data ?? {};
        final online = PresenceService.isOnline(map[email]);
        if (!online) return const SizedBox();
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        );
      },
    );
  }
}

class OnlineLabel extends StatelessWidget {
  final String email;
  const OnlineLabel({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: PresenceService.instance.watchAll(),
      builder: (context, snapshot) {
        final map = snapshot.data ?? {};
        final text = PresenceService.label(map[email]);
        final online = PresenceService.isOnline(map[email]);
        return Text(text,
            style: TextStyle(
                fontSize: 11,
                color: online ? Colors.green : Colors.grey,
                fontWeight: online ? FontWeight.w600 : FontWeight.normal));
      },
    );
  }
}
