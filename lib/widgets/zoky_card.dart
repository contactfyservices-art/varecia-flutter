import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'glass_card.dart';

/// Liste des "ZOKY" (anciens membres) — gérée manuellement par l'admin,
/// pas liée à des comptes inscrits dans l'app (les anciens n'ont pas
/// forcément l'application).
class ZokyCard extends StatelessWidget {
  const ZokyCard({super.key});

  Future<void> _addOrEdit(BuildContext context,
      {int? index, String? currentName, String? currentInfo}) async {
    final nameCtrl = TextEditingController(text: currentName ?? '');
    final infoCtrl = TextEditingController(text: currentInfo ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? 'Ajouter un ancien' : 'Modifier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: infoCtrl,
              decoration: const InputDecoration(
                  labelText: 'Info (promotion, rôle passé...) — optionnel'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (result != true || nameCtrl.text.trim().isEmpty) return;

    final fs = FirestoreService.instance;
    final list = await fs.getJSON('zoky_anciens', []) as List;
    final entry = {'nom': nameCtrl.text.trim(), 'info': infoCtrl.text.trim()};
    if (index == null) {
      list.add(entry);
    } else {
      list[index] = entry;
    }
    await fs.setJSON('zoky_anciens', list);
  }

  Future<void> _delete(BuildContext context, int index) async {
    final fs = FirestoreService.instance;
    final list = await fs.getJSON('zoky_anciens', []) as List;
    list.removeAt(index);
    await fs.setJSON('zoky_anciens', list);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    final fs = FirestoreService.instance;

    return StreamBuilder(
      stream: fs.watchJSON('zoky_anciens', []),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return GlassCard(child: Text('Erreur ZOKY : ${snapshot.error}'));
        }
        final list = (snapshot.data ?? []) as List;

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('ZOKY — Anciens membres',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1),
                      onPressed: () => _addOrEdit(context),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Text('Aucun ancien membre enregistré pour le moment.',
                    style: TextStyle(color: Colors.grey)),
              for (int i = 0; i < list.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(list[i]['nom'] ?? ''),
                  subtitle: (list[i]['info'] ?? '').toString().isNotEmpty
                      ? Text(list[i]['info'])
                      : null,
                  trailing: isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _addOrEdit(context,
                                  index: i,
                                  currentName: list[i]['nom'],
                                  currentInfo: list[i]['info']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _delete(context, i),
                            ),
                          ],
                        )
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}
