import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/admin_badge.dart';

class BibliothequePage extends StatefulWidget {
  const BibliothequePage({super.key});
  @override
  State<BibliothequePage> createState() => _BibliothequePageState();
}

class _BibliothequePageState extends State<BibliothequePage> {
  final _fs = FirestoreService.instance;
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  PlatformFile? _pickedFile;
  String _search = '';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > 900 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Fichier trop lourd pour un envoi direct (max ~900 Ko). '
              'Utilise plutôt un lien Google Drive ci-dessus pour les gros fichiers.'),
          duration: Duration(seconds: 4)));
      return;
    }
    setState(() => _pickedFile = file);
  }

  Future<void> _add(dynamic user) async {
    if (_titleCtrl.text.trim().isEmpty) return;

    String? fileData;
    String? fileName;
    String? fileType;
    if (_pickedFile != null && _pickedFile!.bytes != null) {
      fileData = 'data:application/octet-stream;base64,'
          '${base64Encode(_pickedFile!.bytes!)}';
      fileName = _pickedFile!.name;
      fileType = _pickedFile!.extension;
    }

    await _fs.addItem('library_items', {
      'title': _titleCtrl.text.trim(),
      'author': user.fullName,
      'authorEmail': user.email,
      'link': _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      'fileData': fileData,
      'fileName': fileName,
      'fileType': fileType,
    });
    _titleCtrl.clear();
    _linkCtrl.clear();
    setState(() => _pickedFile = null);
    SoundService.instance.playSuccess();
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette ressource ?'),
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
    if (ok == true) await _fs.deleteItem('library_items', docId);
  }

  Future<void> _editTitle(String docId, String currentTitle) async {
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
    await _fs.updateItem('library_items', docId, {'title': newTitle});
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final isAdmin = context.watch<AuthService>().isAdmin;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fs.watchItems('library_items'),
      builder: (context, snapshot) {
        final allItems = snapshot.data ?? [];
        // Filtre de recherche — insensible à la casse, sur le titre.
        final items = _search.isEmpty
            ? allItems
            : allItems
                .where((it) => (it['title'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_search.toLowerCase()))
                .toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Bibliothèque partagée',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                  'Ouverte à tous : chacun peut ajouter une ressource et consulter les autres.'),
              const SizedBox(height: 12),
              // Barre de recherche
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher une ressource par titre...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Titre de la ressource'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lien Google Drive (recommandé pour les gros fichiers)',
                        helperText: 'Astuce : partage ton fichier sur Drive avec '
                            '"Tout le monde avec le lien", puis colle le lien ici — '
                            'aucune limite de taille.',
                        helperMaxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: Text(_pickedFile == null
                                ? 'OU joindre un petit fichier (<900 Ko)'
                                : _pickedFile!.name,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        if (_pickedFile != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _pickedFile = null),
                          ),
                      ],
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
              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                Text(
                  _search.isEmpty
                      ? 'Aucune ressource pour le moment.'
                      : 'Aucun résultat pour "$_search".',
                  style: const TextStyle(color: Colors.grey),
                ),
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Builder(builder: (context) {
                      final title = it['title'] ?? '';
                      final author = it['author'] ?? '';
                      final authorEmail = it['authorEmail'] ?? '';
                      final link = it['link'] as String?;
                      final fileName = it['fileName'] as String?;
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
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text('Ajouté par $author',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ),
                                    AdminBadge(authorEmail: authorEmail),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (link != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.link, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(link,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.blue,
                                          decoration:
                                              TextDecoration.underline)),
                                ),
                              ],
                            ),
                          ],
                          if (fileName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.insert_drive_file, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                    child: Text(fileName,
                                        overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ],
                          if (canEdit) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _editTitle(it['id'], title),
                                  child: const Text('Modifier'),
                                ),
                                TextButton(
                                  onPressed: () => _confirmDelete(it['id']),
                                  child: const Text('Supprimer',
                                      style: TextStyle(color: Colors.red)),
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
