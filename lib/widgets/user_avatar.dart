import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class UserAvatar extends StatelessWidget {
  final String email;
  final String fallbackName;
  final double radius;

  const UserAvatar({
    super.key,
    required this.email,
    required this.fallbackName,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService.instance.watchJSON('users', []),
      builder: (context, snapshot) {
        final users = (snapshot.data ?? []) as List;
        final match = users.cast<Map<String, dynamic>>().firstWhere(
              (u) => u['email'] == email,
              orElse: () => {},
            );
        final photo = match['photo'] as String?;

        if (photo != null && photo.isNotEmpty) {
          try {
            return CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(base64Decode(photo.split(',').last)),
            );
          } catch (_) {}
        }

        final initial =
            fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : '?';
        return CircleAvatar(radius: radius, child: Text(initial));
      },
    );
  }
}
