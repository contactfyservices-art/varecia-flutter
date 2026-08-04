import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// Petit badge "Admin" affiché à côté du nom d'un auteur, si son e-mail
/// figure dans la liste des administrateurs.
class AdminBadge extends StatelessWidget {
  final String authorEmail;
  const AdminBadge({super.key, required this.authorEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService.instance.watchJSON('admins', []),
      builder: (context, snapshot) {
        final admins = (snapshot.data ?? []) as List;
        if (!admins.contains(authorEmail)) return const SizedBox();
        return Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('Admin',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
