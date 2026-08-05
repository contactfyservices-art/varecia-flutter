import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'glass_card.dart';
import 'user_avatar.dart';

/// Postes fixes de l'organigramme "ZOKY", avec le nombre de places
/// disponibles pour chacun.
const Map<String, int> kOrganigrammePostes = {
  'Président': 1,
  'Vice président': 1,
  'Secrétaire': 2,
  'Trésorier': 1,
  'Commissaire aux comptes': 2,
  'Suivi Évaluation': 1,
  'Superviseur d\'activité': 1,
  'Superviseur Niveau L1': 2,
  'Superviseur Niveau L2': 2,
  'Superviseur Niveau L3': 2,
  'Superviseur Niveau M1': 2,
  'Superviseur Niveau M2': 2,
};

class OrganigrammeCard extends StatelessWidget {
  const OrganigrammeCard({super.key});

  Future<void> _editPoste(
      BuildContext context, String poste, int maxSlots, List<String> current) async {
    final fs = FirestoreService.instance;
    final allUsers = await fs.getJSON('users', []) as List;
    final approved =
        allUsers.where((u) => u['status'] == 'approved').toList();

    final selected = List<String>.from(current);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return AlertDialog(
          title: Text(poste),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text('$maxSlots place(s) maximum',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                for (final u in approved)
                  CheckboxListTile(
                    dense: true,
                    title: Text('${u['prenom']} ${u['nom']}'),
                    value: selected.contains(u['email']),
                    onChanged: (checked) {
                      setSheetState(() {
                        if (checked == true) {
                          if (selected.length >= maxSlots) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Maximum $maxSlots place(s) pour ce poste.')));
                            return;
                          }
                          selected.add(u['email']);
                        } else {
                          selected.remove(u['email']);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data =
                    await fs.getJSON('organigramme', <String, dynamic>{});
                final map = Map<String, dynamic>.from(data);
                map[poste] = selected;
                await fs.setJSON('organigramme', map);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    final fs = FirestoreService.instance;

    return StreamBuilder(
      stream: fs.watchJSON('organigramme', <String, dynamic>{}),
      builder: (context, snapshot) {
        final data = Map<String, dynamic>.from(snapshot.data ?? {});

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Organigramme — ZOKY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              for (final entry in kOrganigrammePostes.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PosteRow(
                    poste: entry.key,
                    maxSlots: entry.value,
                    assignedEmails:
                        List<String>.from(data[entry.key] ?? []),
                    isAdmin: isAdmin,
                    onEdit: () => _editPoste(context, entry.key, entry.value,
                        List<String>.from(data[entry.key] ?? [])),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PosteRow extends StatelessWidget {
  final String poste;
  final int maxSlots;
  final List<String> assignedEmails;
  final bool isAdmin;
  final VoidCallback onEdit;

  const _PosteRow({
    required this.poste,
    required this.maxSlots,
    required this.assignedEmails,
    required this.isAdmin,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService.instance;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$poste ($maxSlots)',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (assignedEmails.isEmpty)
                const Text('Vacant',
                    style: TextStyle(color: Colors.grey, fontSize: 12))
              else
                FutureBuilder(
                  future: fs.getJSON('users', []),
                  builder: (context, snap) {
                    final allUsers = (snap.data ?? []) as List;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: assignedEmails.map((email) {
                        final match = allUsers.cast<Map<String, dynamic>>().firstWhere(
                              (u) => u['email'] == email,
                              orElse: () => {},
                            );
                        final name = match.isEmpty
                            ? email
                            : '${match['prenom']} ${match['nom']}';
                        return Chip(
                          avatar: UserAvatar(
                              email: email, fallbackName: name, radius: 10),
                          label: Text(name, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: onEdit,
          ),
      ],
    );
  }
}
