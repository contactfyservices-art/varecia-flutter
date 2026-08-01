import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';

class BibliothequePage extends StatefulWidget {
  const BibliothequePage({super.key});
  @override
  State<BibliothequePage> createState() => _BibliothequePageState();
}

class _BibliothequePageState extends State<BibliothequePage> {
  final _fs = FirestoreService.instance;
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  Future<void> _add(AppUser user) async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final items = await _fs.getJSON('library', []) as List;
    items.add(LibraryItem(
      index: items.length,
      title: _titleCtrl.text.trim(),
      author: user.fullName,
      authorEmail: user.email,
      date: DateTime.now().toString(),
      link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
    ).toMap());
    await _fs.setJSON('library', items);
    _titleCtrl.clear();
    _linkCtrl.clear();
    SoundService.instance.playSuccess();
  }

  Future<void> _delete(int index) async {
    final items = await _fs.getJSON('library', []) as List;
    items.removeAt(index);
    await _fs.setJSON('library', items);
  }

  Future<void> _editTitle(int index, String currentTitle) async {
    final ctrl = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le titre'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (newTitle == null) return;
    final items = await _fs.getJSON('library', []) as List;
    items[index]['title'] = newTitle;
    await _fs.setJSON('library', items);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final isAdmin = context.watch<AuthService>().isAdmin;

    return StreamBuilder(
      stream: _fs.watchJSON('library', []),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? []) as List;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Bibliothèque partagée',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
                'Ouverte à tous : chacun peut ajouter une ressource et consulter les autres.'),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Titre de la ressource'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _linkCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Lien (URL) — optionnel'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: user == null ? null : () => _add(user),
                      child: const Text('Ajouter à la bibliothèque'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('Aucune ressource pour le moment.',
                  style: TextStyle(color: Colors.grey)),
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  child: Builder(builder: (context) {
                    final it = LibraryItem.fromMap(
                        Map<String, dynamic>.from(items[i]), i);
                    final canEdit = isAdmin || it.authorEmail == user?.email;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.title,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Ajouté par ${it.author}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (it.link != null) ...[
                          const SizedBox(height: 4),
                          Text(it.link!,
                              style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline)),
                        ],
                        if (canEdit) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _editTitle(i, it.title),
                                child: const Text('Modifier'),
                              ),
                              TextButton(
                                onPressed: () => _delete(i),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}
