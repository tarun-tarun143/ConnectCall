
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/user_tile.dart';
import '../profile/user_profile_screen.dart' as profile;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  void _changed() {
    final value = _controller.text.trim().toLowerCase();

    if (value == _query) {
      return;
    }

    setState(() {
      _query = value;
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_changed)
      ..dispose();

    super.dispose();
  }

  bool _matches(UserModel user) {
    if (_query.isEmpty) {
      return true;
    }

    return user.name.toLowerCase().contains(_query) ||
        user.username.toLowerCase().contains(_query) ||
        user.email.toLowerCase().contains(_query) ||
        user.phone.toLowerCase().contains(_query);
  }

  void _openProfile(
    BuildContext context,
    UserModel user,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            profile.UserProfileScreen(user: user),
      ),
    );
  }

  void _openAudioCall(
    BuildContext context,
    UserModel user,
    UserModel me,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => profile.PreCallPage(
          user: user,
          me: me,
          callId: createCallId(
            me.id,
            user.id,
          ),
          video: false,
        ),
      ),
    );
  }

  void _openVideoCall(
    BuildContext context,
    UserModel user,
    UserModel me,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => profile.PreCallPage(
          user: user,
          me: me,
          callId: createCallId(
            me.id,
            user.id,
          ),
          video: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final me = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search people'),
      ),
      body: users.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load people.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          final matches = items
              .where(_matches)
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  12,
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText:
                        'Search name, username, email or phone',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _controller.clear();
                            },
                            icon: const Icon(
                              Icons.clear_rounded,
                            ),
                          ),
                  ),
                ),
              ),

              Expanded(
                child: matches.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching people found.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          28,
                        ),
                        itemCount: matches.length,

                        // Do not use (_, _) here.
                        // Each callback parameter needs
                        // its own identifier.
                        separatorBuilder: (
                          context,
                          index,
                        ) =>
                            const Divider(height: 1),

                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final user = matches[index];

                          return UserTile(
                            user: user,

                            onTap: () {
                              _openProfile(
                                context,
                                user,
                              );
                            },

                            onAudio: me == null
                                ? null
                                : () {
                                    _openAudioCall(
                                      context,
                                      user,
                                      me,
                                    );
                                  },

                            onVideo: me == null
                                ? null
                                : () {
                                    _openVideoCall(
                                      context,
                                      user,
                                      me,
                                    );
                                  },
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

