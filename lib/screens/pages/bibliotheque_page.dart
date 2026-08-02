import 'dart:convert';
import 'package:file_picker/file_picker.dart';
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
  PlatformFile? _pickedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if ((file.size) > 3 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier trop lourd (max 3 Mo).')));
      return;
    }
    setState(() => _pickedFile = file);
  }

  Future<void> _add(AppUser user) async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final items = await _fs.getJSON('library', []) as List;

    String? fileData;
    String? fileName;
    String? fileType;
    if (_pickedFile != null && _pickedFile!.bytes != null) {
      fileData = 'data:application/octet-stream;base64,'
          '${base64Encode(_pickedFile!.bytes!)}';
      fileName = _pickedFile!.name;
      fileType = _pickedFile!.extension;
    }

    items.add(LibraryItem(
      index: items.length,
      title: _titleCtrl.text.trim(),
      author: user.fullName,
      authorEmail: user.email,
      date: DateTime.now().toString(),
      link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      fileData: fileData,
      fileName: fileName,
      fileType: fileType,
    ).toMap());
    await _fs.setJSON('library', items);
    _titleCtrl.clear();
    _linkCtrl.clear();
    setState(() => _pickedFile = null);
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
                          labelText: 'Lien (URL) — optionnel'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: Text(_pickedFile == null
                                ? 'Joindre un fichier — optionnel'
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
                      final canEdit =
                          isAdmin || it.authorEmail == user?.email;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Ajouté par ${it.author}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          if (it.link != null) ...[
                            const SizedBox(height: 4),
                            Text(it.link!,
                                style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline)),
                          ],
                          if (it.fileName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.insert_drive_file, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                    child: Text(it.fileName!,
                                        overflow: TextOverflow.ellipsis)),
                              ],
                            ),
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
          ),
        );
      },
    );
  }
}
