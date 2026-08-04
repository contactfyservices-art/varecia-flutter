import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/admin_badge.dart';

class ActualitePage extends StatefulWidget {
  const ActualitePage({super.key});
  @override
  State<ActualitePage> createState() => _ActualitePageState();
}

class _ActualitePageState extends State<ActualitePage> {
  final _fs = FirestoreService.instance;
  final _captionCtrl = TextEditingController();

  Future<void> _addPhoto(dynamic user) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70, maxWidth: 1000);
      if (picked == null) return;
      final bytes = await File(picked.path).readAsBytes();
      if (bytes.lengthInBytes > 900 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Image trop volumineuse (max ~900 Ko après compression).')));
        return;
      }
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await _fs.addItem('gallery_items', {
        'image': b64,
        'caption': _captionCtrl.text.trim(),
        'author': user.fullName,
        'authorEmail': user.email,
        'likes': <String>[],
        'comments': <Map<String, dynamic>>[],
      });
      _captionCtrl.clear();
      SoundService.instance.playSuccess();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Publié !')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la publication : $e')));
    }
  }

  Future<void> _toggleLike(String docId, List likes, String email) async {
    final updated = List<String>.from(likes);
    updated.contains(email) ? updated.remove(email) : updated.add(email);
    await _fs.updateItem('gallery_items', docId, {'likes': updated});
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette publication ?'),
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
    if (ok == true) {
      await _fs.deleteItem('gallery_items', docId);
    }
  }

  Future<void> _openComments(
      String docId, List comments, dynamic user) async {
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
              var localComments = List<Map<String, dynamic>>.from(comments);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commentaires', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: localComments.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Aucun commentaire pour le moment.',
                                style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: localComments.length,
                            itemBuilder: (_, i) {
                              final c = localComments[i];
                              return ListTile(
                                dense: true,
                                leading: UserAvatar(
                                  email: c['authorEmail'] ?? '',
                                  fallbackName: c['author'] ?? '?',
                                  radius: 12,
                                ),
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
                                localComments.add({
                                  'author': user.fullName,
                                  'authorEmail': user.email,
                                  'text': ctrl.text.trim(),
                                });
                                await _fs.updateItem('gallery_items', docId,
                                    {'comments': localComments});
                                SoundService.instance.playSuccess();
                                ctrl.clear();
                                setSheetState(() {});
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

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fs.watchItems('gallery_items'),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Actualité',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
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
                          onPressed: () {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Session non chargée — réessaie dans un instant.')));
                              return;
                            }
                            _addPhoto(user);
                          },
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Publier une photo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Aucune publication pour le moment.',
                      style: TextStyle(color: Colors.grey)),
                ),
              for (final it in items)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: _PostCard(
                    data: it,
                    userEmail: user?.email,
                    canEdit: isAdmin || it['authorEmail'] == user?.email,
                    onLike: () =>
                        _toggleLike(it['id'], it['likes'] ?? [], user?.email ?? ''),
                    onComment: () =>
                        _openComments(it['id'], it['comments'] ?? [], user),
                    onDelete: () => _confirmDelete(it['id']),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? userEmail;
  final bool canEdit;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;

  const _PostCard({
    required this.data,
    required this.userEmail,
    required this.canEdit,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final likes = List<String>.from(data['likes'] ?? []);
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    final liked = likes.contains(userEmail);
    final author = data['author'] ?? '';
    final authorEmail = data['authorEmail'] ?? '';
    final image = data['image'] as String?;
    final caption = data['caption'] ?? '';

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                UserAvatar(email: authorEmail, fallbackName: author),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(author,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      AdminBadge(authorEmail: authorEmail),
                    ],
                  ),
                ),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
          if (image != null)
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.memory(
                base64Decode(image.split(',').last),
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
                    Text('${likes.length}'),
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined),
                      onPressed: onComment,
                    ),
                    Text('${comments.length}'),
                  ],
                ),
                if (caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(caption),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
