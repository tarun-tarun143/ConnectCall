import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'avatar.dart';

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.onAudio,
    required this.onVideo,
    this.onTap,
    this.trailing,
  });

  final UserModel user;
  final VoidCallback? onAudio;
  final VoidCallback? onVideo;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final subtitle = user.online
        ? 'Online'
        : user.status == 'busy'
            ? 'Busy'
            : 'Offline';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      leading: UserAvatar(user: user),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.verified_rounded,
              size: 17,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Audio call',
                onPressed: onAudio,
                icon: const Icon(Icons.call_rounded),
              ),
              IconButton(
                tooltip: 'Video call',
                onPressed: onVideo,
                icon: const Icon(Icons.videocam_rounded),
              ),
            ],
          ),
    );
  }
}
