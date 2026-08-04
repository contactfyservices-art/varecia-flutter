import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class _OnboardSlide {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardSlide(this.icon, this.title, this.description);
}

const _slides = [
  _OnboardSlide(
    Icons.home_outlined,
    'Bienvenue sur Varecia App',
    'Retrouve toute la vie de l\'association : actualités, réunions, '
        'bibliothèque et bien plus, au même endroit.',
  ),
  _OnboardSlide(
    Icons.dynamic_feed_outlined,
    'Actualité & Notes',
    'Publie des photos, des notes, réagis et commente ce que partagent '
        'les autres membres.',
  ),
  _OnboardSlide(
    Icons.videocam_outlined,
    'Réunions vidéo',
    'Rejoins les réunions en un clic, directement dans l\'appli, sans '
        'jamais la quitter.',
  ),
  _OnboardSlide(
    Icons.groups_outlined,
    'Messages & Sections',
    'Discute en privé avec les autres membres et retrouve facilement '
        'ceux de ta section.',
  ),
];

/// Tutoriel affiché une seule fois, au tout premier lancement de l'app
/// (avant même l'écran de connexion). Ne réapparaît plus ensuite, sauf
/// si les données de l'appareil sont effacées.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: CanopyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text('Passer',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final s = _slides[i];
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: GlassCard(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(s.icon, size: 64, color: AppColors.canopy),
                              const SizedBox(height: 20),
                              Text(s.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge),
                              const SizedBox(height: 12),
                              Text(s.description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLast
                        ? _finish
                        : () => _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut),
                    child: Text(isLast ? 'Commencer' : 'Suivant'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
