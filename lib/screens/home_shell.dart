import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';
import '../services/presence_service.dart';
import 'pages/accueil_page.dart';
import 'pages/bibliotheque_page.dart';
import 'pages/reunion_page.dart';
import 'pages/galerie_page.dart';
import 'pages/sondage_page.dart';
import 'pages/profil_page.dart';
import 'pages/admin_page.dart';
import 'pages/ma_section_page.dart';
import 'pages/messages_page.dart';
import 'auth/welcome_screen.dart';

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

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pingPresence();
    _presenceTimer =
        Timer.periodic(const Duration(seconds: 60), (_) => _pingPresence());
  }

  void _pingPresence() {
    final email = context.read<AuthService>().currentUser?.email;
    if (email != null) PresenceService.instance.heartbeat(email);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _pingPresence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    super.dispose();
  }

  Future<void> _markSeenIfNeeded(String? badgeKey) async {
    if (badgeKey == null) return;
    await BadgeService.instance.markSeenNow(badgeKey);
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isAdmin = auth.isAdmin;

    final destinations = <_Dest>[
      const _Dest('Accueil', Icons.home_outlined, AccueilPage()),
      const _Dest('Bibliothèque', Icons.menu_book_outlined, BibliothequePage(),
          badgeKey: 'library_items'),
      const _Dest('Réunion', Icons.videocam_outlined, ReunionPage()),
      const _Dest('Actualité', Icons.dynamic_feed_outlined, ActualitePage(),
          badgeKey: 'gallery_items'),
      const _Dest('Notes', Icons.forum_outlined, SondagePage(),
          badgeKey: 'posts_items'),
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
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: destinations.map((d) => d.page).toList(),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
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
                    tooltip: d.label,
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
