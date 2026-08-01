import 'package:audioplayers/audioplayers.dart';

/// Design sonore de l'appli : un son doux pour les actions réussies,
/// un son distinct pour les erreurs. Coupable via le réglage du profil.
///
/// IMPORTANT : les fichiers audio ne sont pas fournis avec ce projet —
/// ajoute tes propres fichiers courts (< 1s) dans assets/sounds/ :
///   - success.mp3  (clochette feuille / pop organique)
///   - error.mp3    (buzz doux)
/// puis vérifie qu'ils sont bien déclarés dans pubspec.yaml (déjà fait,
/// tout le dossier assets/sounds/ est inclus).
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  final _player = AudioPlayer();
  bool enabled = true;

  Future<void> playSuccess() async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (_) {
      // Fichier son manquant : on ignore silencieusement plutôt que
      // de faire planter l'app.
    }
  }

  Future<void> playError() async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource('sounds/error.mp3'));
    } catch (_) {}
  }
}
