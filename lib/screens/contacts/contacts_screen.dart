import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../models/user_model.dart';
import '../../services/permission_service.dart';
import '../../services/user_service.dart';
import '../../widgets/avatar.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key, required this.user, required this.userService});

  final User user;
  final UserService userService;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _search = TextEditingController();
  String _query = '';
  bool _onlineOnly = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final value = _search.text.trim().toLowerCase();
      if (value == _query || !mounted) return;
      setState(() => _query = value);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: StreamBuilder<List<UserModel>>(
        stream: widget.userService.watchUsers(widget.user.uid),
        builder: (context, snapshot) {
          final source = snapshot.data ?? const <UserModel>[];
          final filtered = source.where((item) {
            if (_onlineOnly && !item.online) return false;
            if (_query.isEmpty) return true;
            return item.name.toLowerCase().contains(_query) ||
                item.username.toLowerCase().contains(_query) ||
                item.email.toLowerCase().contains(_query) ||
                item.phone.toLowerCase().contains(_query);
          }).toList();

          filtered.sort((a, b) {
            if (a.online != b.online) return a.online ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contacts', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            const SizedBox(height: 5),
                            Text('${filtered.length} people available', style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Search options',
                        onPressed: () => setState(() => _onlineOnly = !_onlineOnly),
                        style: IconButton.styleFrom(
                          backgroundColor: _onlineOnly ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                        ),
                        icon: Icon(
                          _onlineOnly ? Icons.wifi_rounded : Icons.tune_rounded,
                          color: _onlineOnly ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search name, username, email or phone',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              onPressed: _search.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
              ),
              if (_onlineOnly)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: const Icon(Icons.circle, size: 10),
                        label: const Text('Online only'),
                        onDeleted: () => setState(() => _onlineOnly = false),
                      ),
                    ),
                  ),
                ),
              if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null)
                const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  sliver: SliverToBoxAdapter(
                    child: _StateCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load contacts',
                      message: 'Check your connection and try again.',
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return Dismissible(
                        key: ValueKey(user.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 18),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.person_rounded, color: scheme.primary),
                        ),
                        confirmDismiss: (dismissedItem) async {
                          await Navigator.of(context).pushNamed('/user', arguments: user);
                          return false;
                        },
                        child: _ContactCard(user: user),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final invitee = ZegoUIKitUser(
      id: user.zegoId,
      name: user.name.trim().isEmpty ? user.zegoId : user.name.trim(),
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).pushNamed('/user', arguments: user),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Avatar(name: user.name, url: user.avatarUrl, radius: 28),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: user.online ? const Color(0xFF35D58C) : scheme.outlineVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 5),
                          Icon(Icons.verified_rounded, size: 16, color: scheme.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.username.isEmpty ? (user.online ? 'Online now' : 'Offline') : '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: user.online ? scheme.primary : scheme.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _CallButton(invitee: invitee, isVideo: false),
              const SizedBox(width: 6),
              _CallButton(invitee: invitee, isVideo: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.invitee, required this.isVideo});

  final ZegoUIKitUser invitee;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 44,
      child: ZegoSendCallInvitationButton(
        invitees: <ZegoUIKitUser>[invitee],
        isVideoCall: isVideo,
        iconVisible: true,
        iconSize: const Size(21, 21),
        buttonSize: const Size(44, 44),
        verticalLayout: false,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        borderRadius: 15,
        unclickableBackgroundColor: scheme.surfaceContainerHighest,
        onWillPressed: () => PermissionService.ensureForCall(context: context, video: isVideo),
        onPressed: (code, message, errorInvitees) {
          if (!context.mounted || code == '0') return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message.trim().isEmpty ? 'Call could not be started.' : message.trim())));
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 34, backgroundColor: scheme.primaryContainer, child: Icon(Icons.person_search_rounded, size: 32, color: scheme.primary)),
            const SizedBox(height: 14),
            const Text('No people found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Try a different search or turn off Online only.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
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
            CircleAvatar(radius: 22, backgroundColor: scheme.surfaceContainerHighest, child: Icon(icon, color: scheme.onSurfaceVariant)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(message, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3)),
            ])),
          ],
        ),
      ),
    );
  }
}
