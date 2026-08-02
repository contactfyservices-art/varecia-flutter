import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'firestore_service.dart';

/// Gestion des comptes en interne (pas de Firebase Auth, pas de provider
/// tiers) — reproduit exactement la logique de la version HTML :
/// les comptes sont stockés dans le document `users` de `app_data`.
class AuthService extends ChangeNotifier {
  AppUser? currentUser;
  bool isAdmin = false;
  bool sessionLoaded = false;

  final _fs = FirestoreService.instance;
  static const _kSessionEmail = 'session_email';
  static const _kSessionIsAdmin = 'session_is_admin';

  Future<void> ensureDefaults() async {
    final admins = await _fs.getJSON('admins', null);
    if (admins == null) {
      await _fs.setJSON('admins', ['contact.fy.services@gmail.com']);
    }
    final code = await _fs.getJSON('adminCode', null);
    if (code == null) {
      await _fs.setJSON('adminCode', {'code': '199403100310'});
    }
    final users = await _fs.getJSON('users', null);
    if (users == null) {
      await _fs.setJSON('users', []);
    }
  }

  /// À appeler au démarrage de l'app : relit la session sauvegardée
  /// localement et recharge l'utilisateur depuis Firestore si présent.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kSessionEmail);
    if (savedEmail != null) {
      final users = await _fs.getJSON('users', []) as List;
      final match = users.cast<Map<String, dynamic>>().firstWhere(
            (u) => u['email'] == savedEmail,
            orElse: () => {},
          );
      if (match.isNotEmpty && match['status'] == 'approved') {
        currentUser = AppUser.fromMap(match);
        isAdmin = prefs.getBool(_kSessionIsAdmin) ?? false;
      } else {
        await prefs.remove(_kSessionEmail);
        await prefs.remove(_kSessionIsAdmin);
      }
    }
    sessionLoaded = true;
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (currentUser != null) {
      await prefs.setString(_kSessionEmail, currentUser!.email);
      await prefs.setBool(_kSessionIsAdmin, isAdmin);
    }
  }

  Future<String?> login(String email, String password) async {
    final users = await _fs.getJSON('users', []) as List;
    final match = users.cast<Map<String, dynamic>>().firstWhere(
          (u) => u['email'] == email && u['password'] == password,
          orElse: () => {},
        );
    if (match.isEmpty) return 'Identifiants incorrects.';
    if (match['status'] != 'approved') {
      return 'Compte en attente d\'approbation par un administrateur.';
    }
    currentUser = AppUser.fromMap(match);
    final admins = await _fs.getJSON('admins', []) as List;
    isAdmin = admins.contains(email);
    await _saveSession();
    notifyListeners();
    return null; // pas d'erreur
  }

  Future<String?> signup({
    required String prenom,
    required String nom,
    required String email,
    required String password,
    required String niveau,
  }) async {
    final users = await _fs.getJSON('users', []) as List;
    final exists = users.any((u) => u['email'] == email);
    if (exists) return 'Un compte existe déjà avec cet e-mail.';

    final newUser = AppUser(
      email: email,
      prenom: prenom,
      nom: nom,
      niveau: niveau,
      passwordHash: password,
      status: 'pending',
    );
    users.add(newUser.toMap());
    await _fs.setJSON('users', users);
    return null;
  }

  Future<String?> adminLogin(String code) async {
    final codeObj = await _fs.getJSON('adminCode', {'code': ''});
    if (codeObj['code'] != code) return 'Code administrateur incorrect.';
    isAdmin = true;
    await _saveSession();
    notifyListeners();
    return null;
  }

  /// Met à jour la photo de l'utilisateur actuellement connecté EN MÉMOIRE,
  /// après qu'elle ait été enregistrée dans Firestore (corrige le bug
  /// où la photo ne s'affichait jamais après changement).
  void updateCurrentUserPhoto(String base64Photo) {
    if (currentUser == null) return;
    currentUser = currentUser!.copyWith(photo: base64Photo);
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    isAdmin = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionEmail);
    await prefs.remove(_kSessionIsAdmin);
    notifyListeners();
  }
}
