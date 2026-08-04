import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String _filter = 'Tous'; // 'Tous' | 'A' | 'B' | 'C'

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final fs = FirestoreService.instance;
    if (user == null) return const SizedBox();

    return StreamBuilder(
      stream: fs.watchJSON('users', []),
      builder: (context, snapshot) {
        final allUsers = (snapshot.data ?? []) as List;
        var others = allUsers
            .where((u) =>
                u['status'] == 'approved' && u['email'] != user.email)
            .toList();

        if (_filter != 'Tous') {
          others = others.where((u) => u['section'] == _filter).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Messages',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            // Filtre par section — toujours visible en haut de la page.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in ['Tous', 'A', 'B', 'C'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (others.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text('Aucun membre trouvé pour ce filtre.',
                          style: TextStyle(color: Colors.grey)),
                    ),
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
                          subtitle: Text(m['section'] != null &&
                                  m['section'].toString().isNotEmpty
                              ? 'Section ${m['section']} · ${m['email']}'
                              : m['email'] ?? ''),
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
