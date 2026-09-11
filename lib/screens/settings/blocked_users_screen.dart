
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/avatar.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final auth = ref.watch(authUserProvider);
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked users'),
      ),
      body: auth.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) {
          return const Center(
            child: Text(
              'Unable to determine the signed-in account.',
            ),
          );
        },
        data: (firebaseUser) {
          if (firebaseUser == null) {
            return const Center(
              child: Text(
                'Please sign in to view blocked users.',
              ),
            );
          }

          return users.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load contacts.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            data: (items) {
              return _BlockedBody(
                uid: firebaseUser.uid,
                users: items,
                firestore: ref.read(firestoreProvider),
              );
            },
          );
        },
      ),
    );
  }
}

class _BlockedBody extends StatelessWidget {
  const _BlockedBody({
    required this.uid,
    required this.users,
    required this.firestore,
  });

  final String uid;
  final List<UserModel> users;
  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    final stream = firestore
        .collection('blockedUsers')
        .where(
          'userId',
          isEqualTo: uid,
        )
        .snapshots();

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load blocked users. '
                'Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ??
            <QueryDocumentSnapshot<
                Map<String, dynamic>>>[];

        final ids = docs
            .map(
              (doc) => doc.data()['blockedUserId'],
            )
            .whereType<String>()
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet();

        final blocked = users
            .where(
              (user) => ids.contains(user.id),
            )
            .toList();

        if (blocked.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'You have no blocked users.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: blocked.length,

          // Fixed duplicate "_" error.
          separatorBuilder: (
            context,
            index,
          ) =>
              const Divider(height: 1),

          itemBuilder: (
            context,
            index,
          ) {
            final user = blocked[index];

            return ListTile(
              leading: Avatar(
                name: user.name,
                url: user.avatarUrl,
                radius: 22,
              ),

              title: Text(
                user.name.isEmpty
                    ? user.zegoId
                    : user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              subtitle: user.username.isEmpty
                  ? null
                  : Text(
                      '@${user.username}',
                    ),

              trailing: OutlinedButton(
                onPressed: () => _unblock(
                  context,
                  user,
                ),
                child: const Text(
                  'Unblock',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _unblock(
    BuildContext context,
    UserModel user,
  ) async {
    try {
      await firestore
          .collection('blockedUsers')
          .doc('${uid}_${user.id}')
          .delete();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.name} has been unblocked.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Unblock failed: $error',
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
            'Unable to unblock this user. '
            'Please try again.',
          ),
        ),
      );
    }
  }
}

