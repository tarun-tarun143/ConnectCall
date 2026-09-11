import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../services/user_service.dart';
import '../../widgets/avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.userService,
    this.onOpenContacts,
    this.onOpenHistory,
  });

  final User user;
  final UserService userService;
  final VoidCallback? onOpenContacts;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final usersState = ref.watch(usersProvider);
    final historyState = ref.watch(historyProvider);
    final scheme = Theme.of(context).colorScheme;
    final displayName = (profile?.name.trim().isNotEmpty ?? false) ? profile!.name.trim() : 'there';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProfileProvider);
          ref.invalidate(usersProvider);
          ref.invalidate(historyProvider);
          await Future<void>.delayed(const Duration(milliseconds: 250));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good day, $displayName 👋',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Stay close to the people who matter.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (profile != null)
                      Hero(
                        tag: 'connectcall_profile_avatar_${profile.id}',
                        child: Avatar(
                          name: profile.name,
                          url: profile.avatarUrl,
                          radius: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _WelcomeCard(profile: profile),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Quick actions',
                  actionLabel: 'Find people',
                  onAction: onOpenContacts,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _QuickActions(
                  onSearch: () => Navigator.of(context).pushNamed('/search'),
                  onContacts: onOpenContacts,
                  onHistory: onOpenHistory,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'People online',
                  actionLabel: 'See all',
                  onAction: onOpenContacts,
                ),
              ),
            ),
            usersState.when(
              loading: () => const SliverToBoxAdapter(child: _InlineLoader()),
              error: (error, errorStack) => SliverToBoxAdapter(
                child: _StateCard(
                  icon: Icons.wifi_off_rounded,
                  title: 'Could not load people',
                  message: 'Pull down to try again.',
                ),
              ),
              data: (users) {
                final online = users.where((user) => user.online).take(8).toList();
                if (online.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _StateCard(
                      icon: Icons.people_outline_rounded,
                      title: 'No one is online',
                      message: 'Your contacts will appear here when they are available.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: online.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => _OnlinePerson(user: online[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recent calls',
                  actionLabel: 'View all',
                  onAction: onOpenHistory,
                ),
              ),
            ),
            historyState.when(
              loading: () => const SliverToBoxAdapter(child: _InlineLoader()),
              error: (error, errorStack) => const SliverToBoxAdapter(
                child: _StateCard(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Call history unavailable',
                  message: 'Pull down to refresh.',
                ),
              ),
              data: (calls) {
                if (calls.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _StateCard(
                      icon: Icons.phone_in_talk_outlined,
                      title: 'No calls yet',
                      message: 'Your conversations will show up here.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  sliver: SliverList.separated(
                    itemCount: calls.take(4).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _RecentCallTile(item: calls[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.profile});

  final UserModel? profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final online = profile?.online ?? false;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: online ? const Color(0xFF65F2AC) : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      online ? 'You are online' : 'You are offline',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ready for a call?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Connect with a friend in seconds.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
              ],
            ),
          ),
          const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 54),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onSearch, this.onContacts, this.onHistory});

  final VoidCallback onSearch;
  final VoidCallback? onContacts;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.person_search_rounded,
            label: 'Find people',
            onTap: onSearch,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.contacts_rounded,
            label: 'Contacts',
            onTap: onContacts,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: onHistory,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
          child: Column(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlinePerson extends StatelessWidget {
  const _OnlinePerson({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/user', arguments: user),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Avatar(name: user.name, url: user.avatarUrl, radius: 30),
                Positioned(
                  right: 0,
                  bottom: 1,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: const Color(0xFF33D786),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCallTile extends StatelessWidget {
  const _RecentCallTile({required this.item});

  final CallModel item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missed = item.status == 'missed' || item.status == 'failed';
    final incoming = item.direction == 'incoming';
    final video = item.callType == 'video';
    final when = item.createdAt == null ? 'Time unavailable' : Formatters.callDate(item.createdAt!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: missed ? scheme.errorContainer : scheme.primaryContainer,
              child: Icon(
                video ? Icons.videocam_rounded : Icons.call_rounded,
                color: missed ? scheme.error : scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.peerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        incoming ? Icons.call_received_rounded : Icons.call_made_rounded,
                        size: 15,
                        color: missed ? scheme.error : scheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${_status(item.status)} • $when',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.durationSeconds > 0)
              Text(
                Formatters.duration(item.durationSeconds),
                style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  String _status(String value) {
    if (value.isEmpty) return 'Ended';
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel, this.onAction});

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(28),
      child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.surfaceContainerHighest,
              child: Icon(icon, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
