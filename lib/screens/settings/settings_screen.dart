
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/permission_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                  ),
                  title: const Text(
                    'Edit profile',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/edit-profile');
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    Icons.notifications_outlined,
                  ),
                  title: const Text(
                    'Notifications',
                  ),
                  subtitle: const Text(
                    'Call alerts and notification permissions',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () async {
                    try {
                      final enabled =
                          await PermissionService.notifications();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              enabled
                                  ? 'Notification permission is enabled.'
                                  : 'Notification permission is not enabled.',
                            ),
                          ),
                        );
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'Notification error: $error',
                            ),
                          ),
                        );
                    }
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    Icons.security_outlined,
                  ),
                  title: const Text(
                    'Privacy',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/privacy');
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    Icons.block_outlined,
                  ),
                  title: const Text(
                    'Blocked users',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/blocked');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    8,
                  ),
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                RadioGroup<ThemeMode>(
                  groupValue: mode,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    ref
                        .read(
                          themeModeProvider.notifier,
                        )
                        .setMode(value);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.system,
                        title: Text('System'),
                        subtitle: Text(
                          'Follow the device theme',
                        ),
                      ),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.light,
                        title: Text('Light'),
                        subtitle: Text(
                          'Always use light mode',
                        ),
                      ),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.dark,
                        title: Text('Dark'),
                        subtitle: Text(
                          'Always use dark mode',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.key_outlined,
                  ),
                  title: Text(
                    'Calling provider',
                  ),
                  subtitle: Text(
                    'ZEGOCLOUD Call Kit + Signaling',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                  ),
                  title: Text(
                    'Version',
                  ),
                  subtitle: Text(
                    'ConnectCall 1.0.0',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Center(
            child: TextButton.icon(
              onPressed: () => _logout(
                context,
                ref,
              ),
              icon: const Icon(
                Icons.logout_rounded,
              ),
              label: const Text(
                'Logout',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout?',
          ),
          content: const Text(
            'You will need to sign in again to use ConnectCall.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      // AuthService exposes logout(), not signOut().
      await ref
          .read(authServiceProvider)
          .logout();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed: $error',
            ),
          ),
        );
    }
  }
}

