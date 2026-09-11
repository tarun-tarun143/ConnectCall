import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _accepted = false;

  @override
  void dispose() {
    for (final controller in [_name, _username, _email, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the terms to continue.')));
      return;
    }
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).register(
        name: _name.text,
        username: _username.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created. Check your email for verification.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
            children: [
              Text('Set up your profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Create an account and start connecting in minutes.'),
              const SizedBox(height: 24),
              TextFormField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name.' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _username, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email_rounded)), validator: (v) => v == null || v.trim().length < 3 ? 'Use at least 3 characters.' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email.' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 12),
              TextFormField(controller: _password, obscureText: true, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)), validator: (v) => v == null || v.length < 6 ? 'Use at least 6 characters.' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_rounded)), validator: (v) => v == null || v.isEmpty ? 'Confirm your password.' : null),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _accepted,
                onChanged: (value) => setState(() => _accepted = value ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text('I agree to the Terms & Privacy Policy.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              SizedBox(height: 54, child: FilledButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Account'))),
            ],
          ),
        ),
      ),
    );
  }
}
