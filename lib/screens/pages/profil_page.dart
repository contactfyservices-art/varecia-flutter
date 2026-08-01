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

  Future<void> _changePhoto() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;

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
    final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    final users = await _fs.getJSON('users', []) as List;
    final idx = users.indexWhere((u) => u['email'] == user.email);
    if (idx != -1) {
      users[idx]['photo'] = b64;
      await _fs.setJSON('users', users);
      SoundService.instance.playSuccess();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage: user.photo != null
                    ? MemoryImage(
                        base64Decode(user.photo!.split(',').last))
                    : null,
                child: user.photo == null
                    ? const Icon(Icons.person, size: 44)
                    : null,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _changePhoto,
                child: const Text('Changer la photo'),
              ),
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
    );
  }
}
