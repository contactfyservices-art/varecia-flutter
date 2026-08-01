import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});
  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  final _fs = FirestoreService.instance;
  final _editCtrl = TextEditingController();
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    return StreamBuilder(
      stream: _fs.watchJSON('content_accueil', {'text': ''}),
      builder: (context, snapshot) {
        final data = (snapshot.data ?? {'text': ''}) as Map;
        final text = data['text'] ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Accueil', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (!_editing)
                  Text(
                    text.isEmpty ? 'Aucun contenu pour le moment.' : text,
                    style: TextStyle(
                        color: text.isEmpty ? Colors.grey : null),
                  )
                else
                  TextField(
                    controller: _editCtrl,
                    maxLines: 8,
                    decoration:
                        const InputDecoration(hintText: 'Rédigez le contenu...'),
                  ),
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!_editing)
                        ElevatedButton(
                          onPressed: () {
                            _editCtrl.text = text;
                            setState(() => _editing = true);
                          },
                          child: const Text('Modifier'),
                        )
                      else ...[
                        ElevatedButton(
                          onPressed: () async {
                            await _fs.setJSON(
                                'content_accueil', {'text': _editCtrl.text});
                            SoundService.instance.playSuccess();
                            setState(() => _editing = false);
                          },
                          child: const Text('Enregistrer'),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () => setState(() => _editing = false),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
