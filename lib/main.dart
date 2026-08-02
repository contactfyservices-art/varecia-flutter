import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VareciaApp());
}

class VareciaApp extends StatelessWidget {
  const VareciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()
        ..ensureDefaults().then((_) => null),
      child: MaterialApp(
        title: 'Varecia App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const _SplashGate(),
      ),
    );
  }
}

/// Écran de démarrage : recharge la session sauvegardée localement
/// (si l'utilisateur ne s'est pas explicitement déconnecté la dernière
/// fois), puis redirige automatiquement vers l'accueil ou la connexion.
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final auth = context.read<AuthService>();
    await auth.ensureDefaults();
    await auth.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.sessionLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return auth.currentUser != null
        ? const HomeShell()
        : const WelcomeScreen();
  }
}
