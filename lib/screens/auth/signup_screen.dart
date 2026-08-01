import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/glass_card.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _niveau = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _done = false;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final err = await auth.signup(
      prenom: _prenom.text.trim(),
      nom: _nom.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      niveau: _niveau.text.trim(),
    );
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      SoundService.instance.playError();
      return;
    }
    SoundService.instance.playSuccess();
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: _done
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 48, color: Colors.green),
                      SizedBox(height: 12),
                      Text(
                        'Compte créé ! Il doit maintenant être approuvé '
                        'par un administrateur avant que tu puisses te connecter.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _prenom,
                        decoration: const InputDecoration(labelText: 'Prénom'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nom,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(labelText: 'Adresse e-mail'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'Mot de passe'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _niveau,
                        decoration: const InputDecoration(
                            labelText: 'Niveau / matricule'),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Text('Créer mon compte'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
