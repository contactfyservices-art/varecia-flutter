import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'pages/accueil_page.dart';
import 'pages/bibliotheque_page.dart';
import 'pages/reunion_page.dart';
import 'pages/galerie_page.dart';
import 'pages/sondage_page.dart';
import 'pages/profil_page.dart';
import 'pages/admin_page.dart';
import 'pages/ma_section_page.dart';

class _Dest {
  final String label;
  final IconData icon;
  final Widget page;
  const _Dest(this.label, this.icon, this.page);
}

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
      const _Dest('Bibliothèque', Icons.menu_book_outlined, BibliothequePage()),
      const _Dest('Réunion', Icons.videocam_outlined, ReunionPage()),
      const _Dest('Galerie', Icons.photo_library_outlined, GaleriePage()),
      const _Dest('Notes', Icons.forum_outlined, SondagePage()),
      const _Dest('Ma Section', Icons.groups_outlined, MaSectionPage()),
      const _Dest('Profil', Icons.person_outline, ProfilPage()),
      if (isAdmin)
        const _Dest('Admin', Icons.admin_panel_settings_outlined, AdminPage()),
    ];

    if (_index >= destinations.length) _index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icons/logo.png', height: 28),
            const SizedBox(width: 10),
            const Text('Association Varecia'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: destinations.map((d) => d.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
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
