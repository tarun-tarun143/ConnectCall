import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _photoUrl = TextEditingController();

  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    _bio.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate() || _saving) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      await ref.read(userServiceProvider).updateProfile(
        uid,
        {
          'name': _name.text.trim(),
          'username': _username.text.trim().toLowerCase(),
          'phone': _phone.text.trim(),
          'bio': _bio.text.trim(),
          'photoUrl': _photoUrl.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint('Profile update failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final uid = ref.watch(authUserProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Profile error: $error', textAlign: TextAlign.center),
          ),
        ),
        data: (user) {
          if (user == null || uid == null) {
            return const Center(child: Text('Profile unavailable.'));
          }

          if (!_loaded) {
            _loaded = true;
            _name.text = user.name;
            _username.text = user.username;
            _phone.text = user.phone;
            _bio.text = user.bio;
            _photoUrl.text = user.photoUrl;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => _required(value, 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _username,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    final error = _required(value, 'Username');
                    if (error != null) return error;
                    if (!RegExp(r'^[A-Za-z0-9_]{3,30}$')
                        .hasMatch(value!.trim())) {
                      return 'Use 3–30 letters, numbers or underscores.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _photoUrl,
                  enabled: !_saving,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Profile image URL (optional)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bio,
                  enabled: !_saving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(uid),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
