import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'pages/accueil_page.dart';
import 'pages/bibliotheque_page.dart';
import 'pages/reunion_page.dart';
import 'pages/galerie_page.dart';
import 'pages/sondage_page.dart';
import 'pages/profil_page.dart';
import 'pages/admin_page.dart';
import 'auth/welcome_screen.dart';

/// Structure principale : la navigation (rail sur grand écran, barre du
/// bas sur mobile) reste TOUJOURS visible — c'est géré nativement par
/// Scaffold, contrairement à la version web où il fallait forcer le
/// `position: sticky`.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isAdmin = auth.isAdmin;

    final destinations = <_Dest>[
      const _Dest('Accueil', Icons.home_outlined, AccueilPage()),
      const _Dest('Bibliothèque', Icons.menu_book_outlined,
          BibliothequePage()),
      const _Dest('Réunion', Icons.video_call_outlined, ReunionPage()),
      const _Dest('Galerie', Icons.photo_library_outlined, GaleriePage()),
      const _Dest('Notes', Icons.forum_outlined, SondagePage()),
      const _Dest('Profil', Icons.person_outline, ProfilPage()),
      if (isAdmin)
        const _Dest('Admin', Icons.admin_panel_settings_outlined,
            AdminPage()),
    ];

    final wide = MediaQuery.of(context).size.width > 720;
    final safeIndex = _index >= destinations.length ? 0 : _index;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/icons/logo.png',
                  height: 28, width: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text('Association Varecia'),
          ],
        ),
        backgroundColor: AppColors.forest,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: AppColors.canopy,
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme:
                  IconThemeData(color: Colors.white.withOpacity(0.7)),
              selectedLabelTextStyle: const TextStyle(color: Colors.white),
              unselectedLabelTextStyle:
                  TextStyle(color: Colors.white.withOpacity(0.7)),
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
          Expanded(child: destinations[safeIndex].page),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: destinations
                  .map((d) => NavigationDestination(
                        icon: Icon(d.icon),
                        label: d.label,
                      ))
                  .toList(),
            ),
    );
  }
}

class _Dest {
  final String label;
  final IconData icon;
  final Widget page;
  const _Dest(this.label, this.icon, this.page);
}
