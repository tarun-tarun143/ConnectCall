class Validators {
  const Validators._();

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final requiredResult = required(value, 'Email');
    if (requiredResult != null) return requiredResult;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value!.trim()) ? null : 'Enter a valid email';
  }

  static String? password(String? value) {
    final requiredResult = required(value, 'Password');
    if (requiredResult != null) return requiredResult;
    if (value!.length < 6) return 'Use at least 6 characters';
    return null;
  }
}
