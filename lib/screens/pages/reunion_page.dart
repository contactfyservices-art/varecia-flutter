import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';

/// Contrairement à la version HTML (qui affichait parfois un choix
/// "rejoindre depuis navigateur/appli"), cette version Flutter utilise
/// le SDK Jitsi natif : la vidéo s'intègre directement dans l'appli,
/// l'utilisateur ne la quitte jamais.
class ReunionPage extends StatefulWidget {
  const ReunionPage({super.key});
  @override
  State<ReunionPage> createState() => _ReunionPageState();
}

class _ReunionPageState extends State<ReunionPage> {
  final _fs = FirestoreService.instance;
  final _jitsi = JitsiMeet();
  bool? _wasActive; // état précédent, pour détecter le passage à "actif"

  Future<void> _startMeeting() async {
    final room = 'varecia-${DateTime.now().millisecondsSinceEpoch}';
    await _fs.setJSON('meeting', {'active': true, 'room': room});
    await _fs.setJSON('meetingRequests', []);
    _join(room);
  }

  Future<void> _join(String room) async {
    final user = context.read<AuthService>().currentUser;
    final options = JitsiMeetConferenceOptions(
      room: room,
      configOverrides: {
        'startWithAudioMuted': !(context.read<AuthService>().isAdmin),
        'prejoinPageEnabled': true,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: user?.fullName ?? 'Membre Varecia',
      ),
    );
    await _jitsi.join(options);
  }

  Future<void> _requestFloor() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final reqs = await _fs.getJSON('meetingRequests', []) as List;
    reqs.add({'email': user.email, 'name': user.fullName});
    await _fs.setJSON('meetingRequests', reqs);
    SoundService.instance.playSuccess();
  }

  Future<void> _clearRequest(String email) async {
    final reqs = await _fs.getJSON('meetingRequests', []) as List;
    reqs.removeWhere((r) => r['email'] == email);
    await _fs.setJSON('meetingRequests', reqs);
    SoundService.instance.playSuccess();
  }

  Future<void> _stopMeeting() async {
    await _fs.setJSON('meeting', {'active': false});
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    return StreamBuilder(
      stream: _fs.watchJSON('meeting', {'active': false}),
      builder: (context, snapshot) {
        final meeting = (snapshot.data ?? {'active': false}) as Map;
        final active = meeting['active'] == true;
        final room = meeting['room'] as String?;

        // Notification sonore pour TOUT LE MONDE (pas seulement l'admin)
        // dès que la réunion passe de "inactive" à "active".
        if (_wasActive == false && active == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SoundService.instance.playSuccess();
          });
        }
        _wasActive = active;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? Icons.videocam : Icons.videocam_off,
                      size: 48,
                      color: active ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      active
                          ? 'Une réunion est en cours.'
                          : 'Aucune réunion en cours actuellement.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (!active && isAdmin)
                      ElevatedButton(
                        onPressed: _startMeeting,
                        child: const Text('Démarrer une réunion'),
                      ),
                    if (active) ...[
                      ElevatedButton(
                        onPressed: () => _join(room!),
                        child: const Text('Rejoindre la réunion'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _requestFloor,
                        child: const Text('🖐 Demander à intervenir'),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _stopMeeting,
                          child: const Text('Arrêter la réunion'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (active && isAdmin) ...[
                const SizedBox(height: 16),
                StreamBuilder(
                  stream: _fs.watchJSON('meetingRequests', []),
                  builder: (context, reqSnap) {
                    final reqs = (reqSnap.data ?? []) as List;
                    if (reqs.isEmpty) return const SizedBox();
                    return GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🖐 Demandes de parole en attente',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          for (final r in reqs)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(r['name'] ?? r['email'] ?? ''),
                              trailing: ElevatedButton(
                                onPressed: () => _clearRequest(r['email']),
                                child: const Text('Approuver'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
