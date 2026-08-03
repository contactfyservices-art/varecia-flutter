import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';

/// Affiche uniquement les membres approuvés qui partagent la même
/// section (A/B/C) que l'utilisateur connecté — assignée par l'admin
/// depuis l'onglet Administration.
class MaSectionPage extends StatelessWidget {
  const MaSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final fs = FirestoreService.instance;

    if (user == null) return const SizedBox();

    if (user.section.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tu n\'as pas encore été assigné à une section.\n'
            'Demande à un administrateur de te classer dans une section '
            '(A, B ou C) depuis l\'onglet Administration.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return StreamBuilder(
      stream: fs.watchJSON('users', []),
      builder: (context, snapshot) {
        final allUsers = (snapshot.data ?? []) as List;
        final sectionMembers = allUsers
            .where((u) =>
                u['status'] == 'approved' && u['section'] == user.section)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Ma section — ${user.section}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('${sectionMembers.length} membre(s) dans cette section',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              if (sectionMembers.isEmpty)
                const Text('Aucun autre membre dans ta section pour le moment.',
                    style: TextStyle(color: Colors.grey)),
              for (final m in sectionMembers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Row(
                      children: [
                        if (m['active'] ?? true)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: const BoxDecoration(
                                color: Colors.green, shape: BoxShape.circle),
                          )
                        else
                          const SizedBox(width: 20),
                        CircleAvatar(
                          radius: 18,
                          child: Text(
                            (m['prenom'] ?? '?')
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                          ),
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
          ),
        );
      },
    );
  }
}
