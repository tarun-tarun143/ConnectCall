
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/avatar.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final me =
        ref.watch(currentUserProfileProvider).value;

    final safeUser = ZegoUIKitUser(
      id: _safeZegoId(user.zegoId),
      name: user.name.trim().isEmpty
          ? _safeZegoId(user.zegoId)
          : user.name.trim(),
    );

    final isSelf = me?.id == user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!isSelf)
            IconButton(
              tooltip: 'Block user',
              onPressed: () => _block(
                context,
                ref,
              ),
              icon: const Icon(
                Icons.more_vert_rounded,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          40,
        ),
        children: [
          Center(
            child: Avatar(
              name: user.name,
              url: user.avatarUrl,
              radius: 54,
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              user.name.isEmpty
                  ? user.zegoId
                  : user.name,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),

          if (user.username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                '@${user.username}',
              ),
            ),
          ],

          const SizedBox(height: 10),

          Center(
            child: Text(
              user.online ? 'Online' : 'Offline',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: user.online
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            user.bio.isEmpty
                ? 'Available for secure calls.'
                : user.bio,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 26),

          if (isSelf)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This is your profile. '
                  'Calling yourself is disabled.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (me == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sign in to call this contact.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: _CallButton(
                      invitee: safeUser,
                      isVideo: false,
                      callId: createCallId(
                        me.id,
                        user.id,
                      ),
                      callerId: me.id,
                      calleeId: user.id,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: _CallButton(
                      invitee: safeUser,
                      isVideo: true,
                      callId: createCallId(
                        me.id,
                        user.id,
                      ),
                      callerId: me.id,
                      calleeId: user.id,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 18),

          if (me != null && !isSelf)
            Card(
              child: Column(
                children: [
                  StreamBuilder<bool>(
                    stream: ref
                        .read(userServiceProvider)
                        .watchFavoriteForUser(
                          currentUid: me.id,
                          targetUid: user.id,
                        ),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      final favorite =
                          snapshot.data ?? false;

                      return ListTile(
                        leading: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons
                                  .favorite_border_rounded,
                        ),
                        title: const Text(
                          'Favorite contact',
                        ),
                        trailing: Switch.adaptive(
                          value: favorite,
                          onChanged: (value) async {
                            try {
                              await ref
                                  .read(
                                    userServiceProvider,
                                  )
                                  .toggleFavoriteForUser(
                                    currentUid: me.id,
                                    targetUid: user.id,
                                    favorite: value,
                                  );
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Unable to update '
                                    'favorite: $error',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.block_outlined,
                    ),
                    title: const Text(
                      'Block user',
                    ),
                    onTap: () => _block(
                      context,
                      ref,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _block(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final uid =
        ref.read(authUserProvider).value?.uid;

    if (uid == null || uid == user.id) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Block ${user.name}?',
          ),
          content: const Text(
            'Blocked users should not be contacted '
            'through ConnectCall.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(firestoreProvider)
          .collection('blockedUsers')
          .doc('${uid}_${user.id}')
          .set({
        'userId': uid,
        'blockedUserId': user.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.name} has been blocked.',
          ),
        ),
      );

      Navigator.of(context).maybePop();
    } catch (error, stackTrace) {
      debugPrint(
        'Block user failed: $error',
      );
      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to block this user. '
            'Please try again.',
          ),
        ),
      );
    }
  }

  static String _safeZegoId(String value) {
    final cleaned = value
        .trim()
        .replaceAll(
          RegExp(r'[^A-Za-z0-9_]'),
          '_',
        );

    if (cleaned.isEmpty) {
      return 'user_'
          '${DateTime.now().millisecondsSinceEpoch}';
    }

    if (cleaned.length <= 32) {
      return cleaned;
    }

    return cleaned.substring(0, 32);
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.invitee,
    required this.isVideo,
    required this.callId,
    required this.callerId,
    required this.calleeId,
  });

  final ZegoUIKitUser invitee;
  final bool isVideo;
  final String callId;
  final String callerId;
  final String calleeId;

  @override
  Widget build(BuildContext context) {
    return ZegoSendCallInvitationButton(
      invitees: <ZegoUIKitUser>[
        invitee,
      ],
      isVideoCall: isVideo,
      callID: callId,
      customData: jsonEncode({
        'callerId': callerId,
        'calleeId': calleeId,
        'callType': isVideo
            ? 'video'
            : 'audio',
      }),
      timeoutSeconds: 60,
      verticalLayout: false,
      iconVisible: false,
      text: isVideo
          ? 'Video call'
          : 'Audio call',
      buttonSize: const Size(
        double.infinity,
        52,
      ),
      onPressed: (
        code,
        message,
        errorInvitees,
      ) {
        if (code == '0') {
          return;
        }

        if (!context.mounted) {
          return;
        }

        final errorText =
            message.trim().isEmpty
                ? 'Unable to start the call.'
                : message.trim();

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(errorText),
          ),
        );
      },
    );
  }
}

class PreCallPage extends StatelessWidget {
  const PreCallPage({
    super.key,
    required this.user,
    required this.me,
    required this.callId,
    required this.video,
  });

  final UserModel user;
  final UserModel me;
  final String callId;
  final bool video;

  @override
  Widget build(BuildContext context) {
    final target = ZegoUIKitUser(
      id: _safeZegoId(user.zegoId),
      name: user.name.trim().isEmpty
          ? _safeZegoId(user.zegoId)
          : user.name.trim(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          video
              ? 'Video call'
              : 'Audio call',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_in_talk_rounded,
                size: 64,
              ),

              const SizedBox(height: 16),

              Text(
                'Ready to call ${user.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),

              const SizedBox(height: 10),

              Text(
                video
                    ? 'Send a ZEGOCLOUD '
                      'video-call invitation.'
                    : 'Send a ZEGOCLOUD '
                      'audio-call invitation.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: _CallButton(
                  invitee: target,
                  isVideo: video,
                  callId: callId,
                  callerId: me.id,
                  calleeId: user.id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _safeZegoId(String value) {
    final cleaned = value
        .trim()
        .replaceAll(
          RegExp(r'[^A-Za-z0-9_]'),
          '_',
        );

    if (cleaned.isEmpty) {
      return 'user_'
          '${DateTime.now().millisecondsSinceEpoch}';
    }

    if (cleaned.length <= 32) {
      return cleaned;
    }

    return cleaned.substring(0, 32);
  }
}

