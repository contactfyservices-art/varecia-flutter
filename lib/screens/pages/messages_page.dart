import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import 'chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final fs = FirestoreService.instance;
    if (user == null) return const SizedBox();

    return StreamBuilder(
      stream: fs.watchJSON('users', []),
      builder: (context, snapshot) {
        final allUsers = (snapshot.data ?? []) as List;
        final others = allUsers
            .where((u) =>
                u['status'] == 'approved' && u['email'] != user.email)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Messages', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Choisis un membre pour discuter avec lui.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (others.isEmpty)
              const Text('Aucun autre membre pour le moment.',
                  style: TextStyle(color: Colors.grey)),
            for (final m in others)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text((m['prenom'] ?? '?')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase()),
                    ),
                    title: Text('${m['prenom']} ${m['nom']}'),
                    subtitle: Text(m['email'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            peerEmail: m['email'],
                            peerName: '${m['prenom']} ${m['nom']}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
