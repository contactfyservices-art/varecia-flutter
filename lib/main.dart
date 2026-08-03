import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home_shell.dart';

const int kCurrentAppVersion = 1; // à augmenter manuellement à chaque nouveau build

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
      create: (_) => AuthService()..ensureDefaults(),
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
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final data = await FirestoreService.instance
        .getJSON('appVersion', {'v': 1, 'url': ''});
    final remoteVersion = data['v'] ?? 1;
    final url = data['url'] ?? '';
    if (remoteVersion > kCurrentAppVersion && url.isNotEmpty && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Nouvelle version disponible'),
          content: const Text(
              'Une nouvelle version de l\'app est prête. Télécharge-la et installe-la pour profiter des dernières nouveautés.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Télécharger'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.sessionLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.currentUser != null ? const HomeShell() : const WelcomeScreen();
  }
}
