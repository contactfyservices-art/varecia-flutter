import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _fs = FirestoreService.instance;
  final _newAdminEmail = TextEditingController();
  final _newCode = TextEditingController();

  Future<void> _approve(String email) async {
    final users = await _fs.getJSON('users', []) as List;
    final idx = users.indexWhere((u) => u['email'] == email);
    if (idx != -1) {
      users[idx]['status'] = 'approved';
      await _fs.setJSON('users', users);
      SoundService.instance.playSuccess();
    }
  }

  Future<void> _reject(String email) async {
    final users = await _fs.getJSON('users', []) as List;
    users.removeWhere((u) => u['email'] == email);
    await _fs.setJSON('users', users);
  }

  Future<void> _addAdmin() async {
    final email = _newAdminEmail.text.trim().toLowerCase();
    if (email.isEmpty) return;
    final admins = await _fs.getJSON('admins', []) as List;
    if (admins.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limite de 20 administrateurs atteinte.')));
      return;
    }
    if (!admins.contains(email)) admins.add(email);
    await _fs.setJSON('admins', admins);
    _newAdminEmail.clear();
    SoundService.instance.playSuccess();
  }

  Future<void> _removeAdmin(String email) async {
    final admins = await _fs.getJSON('admins', []) as List;
    admins.remove(email);
    await _fs.setJSON('admins', admins);
  }

  Future<void> _changeCode() async {
    if (_newCode.text.trim().isEmpty) return;
    await _fs.setJSON('adminCode', {'code': _newCode.text.trim()});
    _newCode.clear();
    SoundService.instance.playSuccess();
  }

  Future<void> _publishUpdate() async {
    final v = await _fs.getJSON('appVersion', {'v': 1});
    await _fs.setJSON('appVersion', {'v': (v['v'] ?? 1) + 1});
    SoundService.instance.playSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _fs.watchJSON('users', []),
      builder: (context, usersSnap) {
        final users = (usersSnap.data ?? []) as List;
        final pending = users.where((u) => u['status'] == 'pending').toList();

        return StreamBuilder(
          stream: _fs.watchJSON('admins', []),
          builder: (context, adminsSnap) {
            final admins = (adminsSnap.data ?? []) as List;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Administration',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Demandes en attente',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (pending.isEmpty)
                        const Text('Aucune demande en attente.',
                            style: TextStyle(color: Colors.grey)),
                      for (final u in pending)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${u['prenom']} ${u['nom']}'),
                          subtitle: Text(u['email']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _approve(u['email']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _reject(u['email']),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Administrateurs',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      for (final a in admins)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(a),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeAdmin(a),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newAdminEmail,
                              decoration: const InputDecoration(
                                  labelText: 'E-mail du nouvel admin'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addAdmin,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Code administrateur',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newCode,
                        decoration:
                            const InputDecoration(labelText: 'Nouveau code'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _changeCode,
                        child: const Text('Mettre à jour le code'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mise à jour de l\'application',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _publishUpdate,
                        child: const Text('Publier une nouvelle version'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
