import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';

class SondagePage extends StatefulWidget {
  const SondagePage({super.key});
  @override
  State<SondagePage> createState() => _SondagePageState();
}

class _SondagePageState extends State<SondagePage> {
  final _fs = FirestoreService.instance;
  final _textCtrl = TextEditingController();

  Future<void> _add(AppUser user) async {
    if (_textCtrl.text.trim().isEmpty) return;
    final posts = await _fs.getJSON('posts', []) as List;
    posts.add(Post(
      index: posts.length,
      author: user.fullName,
      authorEmail: user.email,
      text: _textCtrl.text.trim(),
      date: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    ).toMap());
    await _fs.setJSON('posts', posts);
    _textCtrl.clear();
    SoundService.instance.playSuccess();
  }

  Future<void> _delete(int index) async {
    final posts = await _fs.getJSON('posts', []) as List;
    posts.removeAt(index);
    await _fs.setJSON('posts', posts);
  }

  Future<void> _edit(int index, String currentText) async {
    final ctrl = TextEditingController(text: currentText);
    final newText = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier la note'),
        content: TextField(controller: ctrl, maxLines: 4),
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
    if (newText == null) return;
    final posts = await _fs.getJSON('posts', []) as List;
    posts[index]['text'] = newText;
    await _fs.setJSON('posts', posts);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final isAdmin = context.watch<AuthService>().isAdmin;

    return StreamBuilder(
      stream: _fs.watchJSON('posts', []),
      builder: (context, snapshot) {
        final posts = (snapshot.data ?? []) as List;
        final reversed = posts.asMap().entries.toList().reversed.toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Notes & remarques',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _textCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Partagez une note, une remarque...'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: user == null ? null : () => _add(user),
                        child: const Text('Publier'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (posts.isEmpty)
                const Text('Aucune note pour le moment.',
                    style: TextStyle(color: Colors.grey)),
              for (final entry in reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Builder(builder: (context) {
                      final p = Post.fromMap(
                          Map<String, dynamic>.from(entry.value), entry.key);
                      final canEdit = isAdmin || p.authorEmail == user?.email;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.author,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(p.date,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(p.text),
                          if (canEdit) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => _edit(p.index, p.text),
                                  child: const Text('Modifier'),
                                ),
                                TextButton(
                                  onPressed: () => _delete(p.index),
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
          ),
        );
      },
    );
  }
}
