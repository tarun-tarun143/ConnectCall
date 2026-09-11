
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/routing/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'providers/app_providers.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/profile/edit_profile_screen.dart' as edit_profile;
import 'screens/profile/user_profile_screen.dart' as user_profile;
import 'screens/search/search_screen.dart';
import 'screens/settings/blocked_users_screen.dart';
import 'screens/settings/privacy_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash_screen.dart';

class ConnectCallApp extends ConsumerStatefulWidget {
  const ConnectCallApp({super.key});

  @override
  ConsumerState<ConnectCallApp> createState() =>
      _ConnectCallAppState();
}

class _ConnectCallAppState extends ConsumerState<ConnectCallApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;

    if (state == AppLifecycleState.resumed) {
      _setPresence(uid, true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setPresence(uid, false);
    }
  }

  Future<void> _setPresence(String uid, bool online) async {
    try {
      await ref.read(userServiceProvider).setPresence(
            uid,
            online: online,
            status: online ? 'available' : 'offline',
          );
    } catch (error) {
      debugPrint('ConnectCall: presence update failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return const _ConfigurationRequired();
    }

    ref.listen<AsyncValue<User?>>(
      authUserProvider,
      (previous, next) {
        if (next.hasValue && next.value == null) {
          ref.read(zegoServiceProvider).uninitialise();
          ref
              .read(connectCallUserBootstrapProvider.notifier)
              .reset();
        }
      },
    );

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const _AuthenticationGate(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/register':
        return MaterialPageRoute<void>(
          builder: (_) => const RegisterScreen(),
        );
      case '/forgot-password':
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordScreen(),
        );
      case '/search':
        return MaterialPageRoute<void>(
          builder: (_) => const SearchScreen(),
        );
      case '/edit-profile':
        return MaterialPageRoute<void>(
          builder: (_) => const edit_profile.EditProfileScreen(),
        );
      case '/settings':
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
        );
      case '/privacy':
        return MaterialPageRoute<void>(
          builder: (_) => const PrivacyScreen(),
        );
      case '/blocked':
        return MaterialPageRoute<void>(
          builder: (_) => const BlockedUsersScreen(),
        );
      case '/user':
        final argument = settings.arguments;

        if (argument is UserModel) {
          return MaterialPageRoute<void>(
            builder: (_) => user_profile.UserProfileScreen(
              user: argument,
            ),
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => const HomeShell(),
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
        );
    }
  }
}

class _AuthenticationGate extends ConsumerWidget {
  const _AuthenticationGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);

    return auth.when(
      loading: () => const SplashScreen(),
      error: (error, stackTrace) {
        debugPrint('ConnectCall: auth state error: $error');
        return const LoginScreen();
      },
      data: (user) {
        if (user == null) return const LoginScreen();
        return const _ProfileGate();
      },
    );
  }
}

class _ProfileGate extends ConsumerWidget {
  const _ProfileGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return profile.when(
      loading: () => const SplashScreen(),
      error: (error, stackTrace) {
        debugPrint('ConnectCall: profile state error: $error');

        return _ErrorScreen(
          message: 'We could not load your profile.',
          onRetry: () {
            ref.invalidate(currentUserProfileProvider);
          },
        );
      },
      data: (value) {
        if (value == null) return const SplashScreen();

        return _ZegoBootstrapGate(profile: value);
      },
    );
  }
}

class _ZegoBootstrapGate extends ConsumerStatefulWidget {
  const _ZegoBootstrapGate({
    required this.profile,
  });

  final UserModel profile;

  @override
  ConsumerState<_ZegoBootstrapGate> createState() =>
      _ZegoBootstrapGateState();
}

class _ZegoBootstrapGateState
    extends ConsumerState<_ZegoBootstrapGate> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref
          .read(connectCallUserBootstrapProvider.notifier)
          .bootstrap(widget.profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(connectCallUserBootstrapProvider);

    if (!ready) {
      return const SplashScreen();
    }

    return const HomeShell();
  }
}

final connectCallUserBootstrapProvider =
    NotifierProvider<ConnectCallUserBootstrap, bool>(
  ConnectCallUserBootstrap.new,
);

class ConnectCallUserBootstrap extends Notifier<bool> {
  String? _bootstrappedUid;

  @override
  bool build() => false;

  void reset() {
    _bootstrappedUid = null;
    state = false;
  }

  Future<void> bootstrap(UserModel profile) async {
    if (_bootstrappedUid == profile.id && state) return;

    state = false;

    try {
      await ref.read(zegoServiceProvider).initialiseForUser(
            uid: profile.id,
            name: profile.name,
          );

      await ref.read(notificationServiceProvider).initialise(
            profile.id,
          );

      await ref.read(userServiceProvider).setPresence(
            profile.id,
            online: true,
            status: 'available',
          );

      _bootstrappedUid = profile.id;
      state = true;
    } catch (error, stackTrace) {
      debugPrint('ConnectCall: bootstrap failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _bootstrappedUid = null;
      state = false;
    }
  }
}

class _ConfigurationRequired extends StatelessWidget {
  const _ConfigurationRequired();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_suggest_rounded,
                  size: 68,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'ConnectCall setup required',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add the required ZEGOCLOUD configuration and restart the app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
