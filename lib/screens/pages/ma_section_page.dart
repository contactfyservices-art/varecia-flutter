import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/online_dot.dart';
import '../../widgets/organigramme_card.dart';
import '../../widgets/zoky_card.dart';

class MaSectionPage extends StatelessWidget {
  const MaSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final fs = FirestoreService.instance;

    if (user == null) return const SizedBox();

    return StreamBuilder(
      stream: fs.watchJSON('users', []),
      builder: (context, snapshot) {
        final allUsers = (snapshot.data ?? []) as List;
        final sectionMembers = user.section.isEmpty
            ? []
            : allUsers
                .where((u) =>
                    u['status'] == 'approved' && u['section'] == user.section)
                .toList();

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const OrganigrammeCard(),
              const SizedBox(height: 16),
              const ZokyCard(),
              const SizedBox(height: 20),
              Text(
                user.section.isEmpty
                    ? 'Ma section'
                    : 'Ma section — ${user.section}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              if (user.section.isEmpty)
                const Text(
                  'Tu n\'as pas encore été assigné à une section.\n'
                  'Demande à un administrateur de te classer dans une section '
                  '(A, B ou C) depuis l\'onglet Administration.',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                Text('${sectionMembers.length} membre(s) dans cette section',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                if (sectionMembers.isEmpty)
                  const Text(
                      'Aucun autre membre dans ta section pour le moment.',
                      style: TextStyle(color: Colors.grey)),
                for (final m in sectionMembers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              UserAvatar(
                                email: m['email'] ?? '',
                                fallbackName: m['prenom'] ?? '?',
                                radius: 18,
                              ),
                              Positioned(
                                bottom: -1,
                                right: -1,
                                child: OnlineDot(email: m['email'] ?? ''),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${m['prenom']} ${m['nom']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(m['email'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
