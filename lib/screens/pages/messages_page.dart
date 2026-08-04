import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/online_dot.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String _filter = 'Tous';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final fs = FirestoreService.instance;

    if (user == null) {
      return const Center(
        child: Text('Session non chargée. Reviens sur cet onglet dans un instant.',
            textAlign: TextAlign.center),
      );
    }

    return StreamBuilder(
      stream: fs.watchJSON('users', []),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erreur de chargement : ${snapshot.error}',
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

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
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        allUsers.length <= 1
                            ? 'Aucun autre membre inscrit pour le moment dans l\'appli.'
                            : 'Aucun membre trouvé pour ce filtre.',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final m in others)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              UserAvatar(
                                email: m['email'] ?? '',
                                fallbackName: m['prenom'] ?? '?',
                              ),
                              Positioned(
                                bottom: -1,
                                right: -1,
                                child: OnlineDot(email: m['email'] ?? ''),
                              ),
                            ],
                          ),
                          title: Text('${m['prenom']} ${m['nom']}'),
                          subtitle: Row(
                            children: [
                              if (m['section'] != null &&
                                  m['section'].toString().isNotEmpty)
                                Text('Section ${m['section']} · ',
                                    style: const TextStyle(fontSize: 11)),
                              OnlineLabel(email: m['email'] ?? ''),
                            ],
                          ),
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
