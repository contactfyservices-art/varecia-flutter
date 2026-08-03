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
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: GlassCard(
            borderRadius: 0,
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
                          decoration: const InputDecoration(
                              hintText: 'Ajouter un commentaire...'),
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
        ),
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
        final rawItems = (snapshot.data ?? []) as List;
        // Ordre "fil d'actualité" : le plus récent en premier
        final items = rawItems.asMap().entries.toList().reversed.toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Albums photos',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _captionCtrl,
                          decoration: const InputDecoration(labelText: 'Légende'),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: user == null ? null : () => _addPhoto(user),
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Publier une photo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Aucune publication pour le moment.',
                      style: TextStyle(color: Colors.grey)),
                ),
              // Fil en une seule colonne, pleine largeur, hauteur d'image
              // fixe et cohérente — comme un fil Instagram.
              for (final entry in items)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: _PostCard(
                    item: GalleryItem.fromMap(
                        Map<String, dynamic>.from(entry.value), entry.key),
                    index: entry.key,
                    userEmail: user?.email,
                    canEdit: isAdmin || entry.value['authorEmail'] == user?.email,
                    onLike: () => _toggleLike(entry.key, user?.email ?? ''),
                    onComment: () => _openComments(
                        entry.key,
                        GalleryItem.fromMap(
                            Map<String, dynamic>.from(entry.value), entry.key),
                        user),
                    onDelete: () => _delete(entry.key),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Carte de publication style "post Instagram" : en-tête avec l'auteur,
/// image pleine largeur à ratio fixe (4:5, comme Instagram), puis
/// actions (like / commentaire) et légende.
class _PostCard extends StatelessWidget {
  final GalleryItem item;
  final int index;
  final String? userEmail;
  final bool canEdit;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;

  const _PostCard({
    required this.item,
    required this.index,
    required this.userEmail,
    required this.canEdit,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final liked = item.likes.contains(userEmail);
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(item.author.isNotEmpty
                      ? item.author[0].toUpperCase()
                      : '?'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.author,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
          if (item.image != null)
            AspectRatio(
              // Hauteur cohérente pour toutes les photos, quel que
              // soit leur format d'origine — même sensation qu'Instagram.
              aspectRatio: 4 / 5,
              child: Image.memory(
                base64Decode(item.image!.split(',').last),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                          color: liked ? Colors.redAccent : null),
                      onPressed: onLike,
                    ),
                    Text('${item.likes.length}'),
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined),
                      onPressed: onComment,
                    ),
                    Text('${item.comments.length}'),
                  ],
                ),
                if (item.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(item.caption),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
