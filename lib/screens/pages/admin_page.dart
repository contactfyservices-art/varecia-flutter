import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/organigramme_card.dart';
import '../../widgets/zoky_card.dart';

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Limite de 20 administrateurs atteinte.')));
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
    final urlCtrl = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Publier une nouvelle version'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
              labelText: 'Lien de téléchargement du nouvel APK'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, urlCtrl.text.trim()),
              child: const Text('Publier')),
        ],
      ),
    );
    if (link == null || link.isEmpty) return;
    final v = await _fs.getJSON('appVersion', {'v': 1, 'url': ''});
    await _fs.setJSON('appVersion', {'v': (v['v'] ?? 1) + 1, 'url': link});
    SoundService.instance.playSuccess();
  }

  Future<void> _setSection(String email, String section) async {
    final users = await _fs.getJSON('users', []) as List;
    final idx = users.indexWhere((u) => u['email'] == email);
    if (idx != -1) {
      users[idx]['section'] = section;
      await _fs.setJSON('users', users);
      SoundService.instance.playSuccess();
    }
  }

  Future<void> _toggleActive(String email, bool value) async {
    final users = await _fs.getJSON('users', []) as List;
    final idx = users.indexWhere((u) => u['email'] == email);
    if (idx != -1) {
      users[idx]['active'] = value;
      await _fs.setJSON('users', users);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _fs.watchJSON('users', []),
      builder: (context, usersSnap) {
        if (usersSnap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erreur de chargement des membres :\n${usersSnap.error}',
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (!usersSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = (usersSnap.data ?? []) as List;
        final pending = users.where((u) => u['status'] == 'pending').toList();
        final approved =
            users.where((u) => u['status'] == 'approved').toList();

        return StreamBuilder(
          stream: _fs.watchJSON('admins', []),
          builder: (context, adminsSnap) {
            if (adminsSnap.hasError) {
              return Center(
                child: Text('Erreur de chargement des admins :\n${adminsSnap.error}'),
              );
            }
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
                      const Text('Membres inscrits',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${approved.length} membre(s)',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      if (approved.isEmpty)
                        const Text('Aucun membre inscrit pour le moment.',
                            style: TextStyle(color: Colors.grey)),
                      for (final u in approved)
                        _MemberRow(
                          name: '${u['prenom']} ${u['nom']}',
                          email: u['email'],
                          section: u['section'] ?? '',
                          active: u['active'] ?? true,
                          onSectionChanged: (s) => _setSection(u['email'], s),
                          onActiveChanged: (v) => _toggleActive(u['email'], v),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Organigramme — géré ici, directement visible côté admin.
                const OrganigrammeCard(),
                const SizedBox(height: 16),

                // ZOKY — anciens membres.
                const ZokyCard(),
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
                const SizedBox(height: 30),
              ],
            );
          },
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String name;
  final String email;
  final String section;
  final bool active;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<bool> onActiveChanged;

  const _MemberRow({
    required this.name,
    required this.email,
    required this.section,
    required this.active,
    required this.onSectionChanged,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (active)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                )
              else
                const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(email,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Switch(value: active, onChanged: onActiveChanged),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Section : ', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              DropdownButton<String>(
                value: section.isEmpty ? null : section,
                hint: const Text('Aucune'),
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('A')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                  DropdownMenuItem(value: 'C', child: Text('C')),
                ],
                onChanged: (v) => onSectionChanged(v ?? ''),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
