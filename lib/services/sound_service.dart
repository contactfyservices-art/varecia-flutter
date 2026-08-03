import 'package:audioplayers/audioplayers.dart';

/// Design sonore de l'appli.
///
/// IMPORTANT : ajoute tes propres fichiers courts dans assets/sounds/ :
///   - success.mp3  (clochette feuille / pop organique)
///   - error.mp3    (buzz doux)
///   - ringtone.mp3 (sonnerie d'appel, boucle courte 2-4s, style vibrant)
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  final _player = AudioPlayer();
  final _ringtonePlayer = AudioPlayer();
  bool enabled = true;

  Future<void> playSuccess() async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (_) {}
  }

  Future<void> playError() async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource('sounds/error.mp3'));
    } catch (_) {}
  }

  /// Démarre la sonnerie d'appel EN BOUCLE — reste active tant que
  /// [stopRingtone] n'est pas appelé (quand on rejoint ou ignore l'appel).
  Future<void> playRingtone() async {
    if (!enabled) return;
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(AssetSource('sounds/ringtone.mp3'));
    } catch (_) {}
  }

  Future<void> stopRingtone() async {
    try {
      await _ringtonePlayer.stop();
    } catch (_) {}
  }
}
