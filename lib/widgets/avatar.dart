import 'package:flutter/material.dart';

import '../models/user_model.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.radius = 24, this.url});

  final String name;
  final double radius;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url?.trim() ?? '';
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundImage: cleanUrl.isEmpty ? null : NetworkImage(cleanUrl),
      child: cleanUrl.isEmpty
          ? Text(letter, style: TextStyle(fontSize: radius * .7))
          : null,
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.showStatus = true});

  final UserModel user;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Avatar(name: user.name, url: user.avatarUrl, radius: 24),
        if (showStatus)
          Positioned(
            right: -1,
            bottom: -1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user.online ? Colors.green : Colors.grey,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
      ],
    );
  }
}
