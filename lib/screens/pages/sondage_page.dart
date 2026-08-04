import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/admin_badge.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/shimmer_loading.dart';

class SondagePage extends StatefulWidget {
  const SondagePage({super.key});
  @override
  State<SondagePage> createState() => _SondagePageState();
}

class _SondagePageState extends State<SondagePage> {
  final _fs = FirestoreService.instance;
  final _textCtrl = TextEditingController();

  Future<void> _add(dynamic user) async {
    if (_textCtrl.text.trim().isEmpty) return;
    await _fs.addItem('posts_items', {
      'author': user.fullName,
      'authorEmail': user.email,
      'text': _textCtrl.text.trim(),
      'date': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    });
    _textCtrl.clear();
    SoundService.instance.playSuccess();
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await _fs.deleteItem('posts_items', docId);
  }

  Future<void> _edit(String docId, String currentText) async {
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
    await _fs.updateItem('posts_items', docId, {'text': newText});
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final isAdmin = context.watch<AuthService>().isAdmin;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fs.watchItems('posts_items'),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];

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
              if (!snapshot.hasData)
                const ShimmerList()
              else if (posts.isEmpty)
                const Text('Aucune note pour le moment.',
                    style: TextStyle(color: Colors.grey)),
              for (int i = 0; i < posts.length; i++)
                FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Builder(builder: (context) {
                        final p = posts[i];
                        final author = p['author'] ?? '';
                        final authorEmail = p['authorEmail'] ?? '';
                        final canEdit =
                            isAdmin || authorEmail == user?.email;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                UserAvatar(
                                    email: authorEmail,
                                    fallbackName: author,
                                    radius: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(author,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          AdminBadge(
                                              authorEmail: authorEmail),
                                        ],
                                      ),
                                      Text(p['date'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(p['text'] ?? ''),
                            if (canEdit) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        _edit(p['id'], p['text'] ?? ''),
                                    child: const Text('Modifier'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _confirmDelete(p['id']),
                                    child: const Text('Supprimer',
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      }),
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
