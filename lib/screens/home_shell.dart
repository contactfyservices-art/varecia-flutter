import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';
import '../services/firestore_service.dart';
import 'pages/accueil_page.dart';
import 'pages/bibliotheque_page.dart';
import 'pages/reunion_page.dart';
import 'pages/galerie_page.dart';
import 'pages/sondage_page.dart';
import 'pages/profil_page.dart';
import 'pages/admin_page.dart';
import 'pages/ma_section_page.dart';
import 'pages/messages_page.dart';

class _Dest {
  final String label;
  final IconData icon;
  final Widget page;
  final String? badgeKey;
  const _Dest(this.label, this.icon, this.page, {this.badgeKey});
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Future<void> _markSeenIfNeeded(String? badgeKey) async {
    if (badgeKey == null) return;
    final data = await FirestoreService.instance.getJSON(badgeKey, []);
    await BadgeService.instance.markSeen(badgeKey, (data as List).length);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isAdmin = auth.isAdmin;

    final destinations = <_Dest>[
      const _Dest('Accueil', Icons.home_outlined, AccueilPage()),
      const _Dest('Bibliothèque', Icons.menu_book_outlined, BibliothequePage(),
          badgeKey: 'library'),
      const _Dest('Réunion', Icons.videocam_outlined, ReunionPage()),
      const _Dest('Actualité', Icons.dynamic_feed_outlined, ActualitePage(),
          badgeKey: 'gallery'),
      const _Dest('Notes', Icons.forum_outlined, SondagePage(),
          badgeKey: 'posts'),
      const _Dest('Messages', Icons.chat_bubble_outline, MessagesPage()),
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
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // Icônes seules, sans texte — résout l'encombrement avec 9 onglets.
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 0, height: 0.01),
          ),
        ),
        child: NavigationBar(
          height: 58,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: _index,
          onDestinationSelected: (i) {
            setState(() => _index = i);
            _markSeenIfNeeded(destinations[i].badgeKey);
          },
          destinations: destinations
              .map((d) => NavigationDestination(
                    tooltip: d.label, // le nom reste accessible en appui long
                    icon: d.badgeKey == null
                        ? Icon(d.icon)
                        : StreamBuilder<int>(
                            stream: BadgeService.instance
                                .watchUnseenCount(d.badgeKey!),
                            builder: (context, snap) {
                              final count = snap.data ?? 0;
                              return Badge(
                                isLabelVisible: count > 0,
                                label: Text('$count'),
                                child: Icon(d.icon),
                              );
                            },
                          ),
                    label: d.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
