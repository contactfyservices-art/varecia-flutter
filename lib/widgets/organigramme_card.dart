import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'glass_card.dart';
import 'user_avatar.dart';

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

  Future<void> _editPoste(BuildContext context, String poste, int maxSlots,
      List<String> current) async {
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
                if (approved.isEmpty)
                  const Text('Aucun membre approuvé pour le moment.',
                      style: TextStyle(color: Colors.grey)),
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
                child: const Text('Annuler')),
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
        if (snapshot.hasError) {
          return GlassCard(
            child: Text('Erreur organigramme : ${snapshot.error}'),
          );
        }
        final data = Map<String, dynamic>.from(snapshot.data ?? {});

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Organigramme',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              for (int i = 0; i < kOrganigrammePostes.length; i++)
                _TierRow(
                  poste: kOrganigrammePostes.keys.elementAt(i),
                  maxSlots: kOrganigrammePostes.values.elementAt(i),
                  assignedEmails: List<String>.from(
                      data[kOrganigrammePostes.keys.elementAt(i)] ?? []),
                  isAdmin: isAdmin,
                  isFirst: i == 0,
                  onEdit: () => _editPoste(
                      context,
                      kOrganigrammePostes.keys.elementAt(i),
                      kOrganigrammePostes.values.elementAt(i),
                      List<String>.from(
                          data[kOrganigrammePostes.keys.elementAt(i)] ?? [])),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Un "niveau" de la pyramide : trait de connexion vertical depuis le
/// niveau précédent, puis le titre du poste, puis les photos des
/// personnes qui l'occupent (ou "Vacant").
class _TierRow extends StatelessWidget {
  final String poste;
  final int maxSlots;
  final List<String> assignedEmails;
  final bool isAdmin;
  final bool isFirst;
  final VoidCallback onEdit;

  const _TierRow({
    required this.poste,
    required this.maxSlots,
    required this.assignedEmails,
    required this.isAdmin,
    required this.isFirst,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService.instance;
    return Column(
      children: [
        if (!isFirst)
          Container(width: 2, height: 18, color: Colors.grey.withOpacity(0.4)),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(poste,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: onEdit,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (assignedEmails.isEmpty)
                    const Text('Vacant',
                        style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    FutureBuilder(
                      future: fs.getJSON('users', []),
                      builder: (context, snap) {
                        final allUsers = (snap.data ?? []) as List;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: assignedEmails.map((email) {
                            final match = allUsers
                                .cast<Map<String, dynamic>>()
                                .firstWhere((u) => u['email'] == email,
                                    orElse: () => {});
                            final name = match.isEmpty
                                ? email
                                : '${match['prenom']} ${match['nom']}';
                            return Column(
                              children: [
                                UserAvatar(
                                    email: email,
                                    fallbackName: name,
                                    radius: 26),
                                const SizedBox(height: 4),
                                Text(name,
                                    style: const TextStyle(fontSize: 11),
                                    textAlign: TextAlign.center),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
