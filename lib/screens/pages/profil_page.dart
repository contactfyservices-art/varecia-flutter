import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _fs = FirestoreService.instance;
  bool _soundOn = true;
  String? _pendingPhotoB64;
  bool _busy = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 600);
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    if (bytes.lengthInBytes > 3 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image trop lourde (max 3 Mo).')));
      return;
    }
    setState(() {
      _pendingPhotoB64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _confirmAndSavePhoto() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null || _pendingPhotoB64 == null) return;

    setState(() => _busy = true);
    final users = await _fs.getJSON('users', []) as List;
    final idx = users.indexWhere((u) => u['email'] == user.email);
    if (idx != -1) {
      users[idx]['photo'] = _pendingPhotoB64;
      await _fs.setJSON('users', users);
      auth.updateCurrentUserPhoto(_pendingPhotoB64!); // corrige le bug d'affichage
      SoundService.instance.playSuccess();
    }
    setState(() {
      _busy = false;
      _pendingPhotoB64 = null;
    });
  }

  Future<void> _refresh() async {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil actualisé.'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox();

    final displayedPhoto = _pendingPhotoB64 ?? user.photo;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Réactualiser',
                      onPressed: _refresh,
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 44,
                  backgroundImage: displayedPhoto != null
                      ? MemoryImage(
                          base64Decode(displayedPhoto.split(',').last))
                      : null,
                  child: displayedPhoto == null
                      ? const Icon(Icons.person, size: 44)
                      : null,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _busy ? null : _pickPhoto,
                  child: const Text('Changer la photo'),
                ),
                if (_pendingPhotoB64 != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _confirmAndSavePhoto,
                        icon: const Icon(Icons.check),
                        label: const Text('Valider la nouvelle photo'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _pendingPhotoB64 = null),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(user.fullName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(user.email),
                Text(user.niveau,
                    style: const TextStyle(color: Colors.grey)),
                const Divider(height: 32),
                SwitchListTile(
                  title: const Text('Sons de l\'application'),
                  value: _soundOn,
                  onChanged: (v) {
                    setState(() => _soundOn = v);
                    SoundService.instance.enabled = v;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
