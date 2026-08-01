import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';

class GaleriePage extends StatefulWidget {
  const GaleriePage({super.key});
  @override
  State<GaleriePage> createState() => _GaleriePageState();
}

class _GaleriePageState extends State<GaleriePage> {
  final _fs = FirestoreService.instance;
  final _captionCtrl = TextEditingController();

  Future<void> _addPhoto(AppUser user) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1000);
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    if (bytes.lengthInBytes > 4.5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image trop volumineuse (max ~4,5 Mo).')));
      return;
    }
    final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    final items = await _fs.getJSON('gallery', []) as List;
    items.add(GalleryItem(
      index: items.length,
      image: b64,
      caption: _captionCtrl.text.trim(),
      author: user.fullName,
      authorEmail: user.email,
      likes: [],
      comments: [],
    ).toMap());
    await _fs.setJSON('gallery', items);
    _captionCtrl.clear();
    SoundService.instance.playSuccess();
  }

  Future<void> _toggleLike(int index, String email) async {
    final items = await _fs.getJSON('gallery', []) as List;
    final likes = List<String>.from(items[index]['likes'] ?? []);
    likes.contains(email) ? likes.remove(email) : likes.add(email);
    items[index]['likes'] = likes;
    await _fs.setJSON('gallery', items);
  }

  Future<void> _delete(int index) async {
    final items = await _fs.getJSON('gallery', []) as List;
    items.removeAt(index);
    await _fs.setJSON('gallery', items);
  }

  Future<void> _openComments(int index, GalleryItem it, AppUser? user) async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Commentaires', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: it.comments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Aucun commentaire pour le moment.',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: it.comments.length,
                        itemBuilder: (_, i) {
                          final c = it.comments[i];
                          return ListTile(
                            dense: true,
                            title: Text(c['author'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(c['text'] ?? ''),
                          );
                        },
                      ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration:
                          const InputDecoration(hintText: 'Ajouter un commentaire...'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: user == null
                        ? null
                        : () async {
                            if (ctrl.text.trim().isEmpty) return;
                            final items =
                                await _fs.getJSON('gallery', []) as List;
                            final comments = List<Map<String, dynamic>>.from(
                                items[index]['comments'] ?? []);
                            comments.add({
                              'author': user.fullName,
                              'authorEmail': user.email,
                              'text': ctrl.text.trim(),
                            });
                            items[index]['comments'] = comments;
                            await _fs.setJSON('gallery', items);
                            SoundService.instance.playSuccess();
                            ctrl.clear();
                            setSheetState(() {
                              it.comments
                                ..clear()
                                ..addAll(comments);
                            });
                          },
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final isAdmin = context.watch<AuthService>().isAdmin;

    return StreamBuilder(
      stream: _fs.watchJSON('gallery', []),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? []) as List;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Albums photos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (isAdmin)
              GlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _captionCtrl,
                      decoration: const InputDecoration(labelText: 'Légende'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: user == null ? null : () => _addPhoto(user),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Publier une photo'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('Aucune publication pour le moment.',
                  style: TextStyle(color: Colors.grey)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final it = GalleryItem.fromMap(
                    Map<String, dynamic>.from(items[i]), i);
                final liked = it.likes.contains(user?.email);
                final canEdit = isAdmin || it.authorEmail == user?.email;
                return GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (it.image != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: Image.memory(
                              base64Decode(it.image!.split(',').last),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.caption,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                      liked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 18),
                                  onPressed: user == null
                                      ? null
                                      : () => _toggleLike(i, user.email),
                                ),
                                Text('${it.likes.length}'),
                                IconButton(
                                  icon: const Icon(Icons.mode_comment_outlined,
                                      size: 18),
                                  onPressed: () =>
                                      _openComments(i, it, user),
                                ),
                                Text('${it.comments.length}'),
                                const Spacer(),
                                if (canEdit)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    onPressed: () => _delete(i),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
