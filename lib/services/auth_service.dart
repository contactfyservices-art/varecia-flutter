import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'firestore_service.dart';

/// Gestion des comptes en interne (pas de Firebase Auth, pas de provider
/// tiers) — reproduit exactement la logique de la version HTML :
/// les comptes sont stockés dans le document `users` de `app_data`.
class AuthService extends ChangeNotifier {
  AppUser? currentUser;
  bool isAdmin = false;

  final _fs = FirestoreService.instance;

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
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    isAdmin = false;
    notifyListeners();
  }
}
