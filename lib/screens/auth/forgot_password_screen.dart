import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';

/// Écran simple : dans la version HTML d'origine il n'y avait pas
/// d'envoi d'e-mail réel (pas de backend mail configuré). On garde le
/// même comportement — invite l'utilisateur à contacter un admin.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_reset, size: 40),
                SizedBox(height: 12),
                Text(
                  'Contacte un administrateur de l\'association pour '
                  'réinitialiser ton mot de passe.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
