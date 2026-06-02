class EmailValidationService {
  /// Returns a human-readable error message describing why [email] is invalid,
  /// or `null` if it is a valid email address.
  static String? errorMessage(String email) {
    if (email.isEmpty) {
      return 'Email address cannot be empty';
    }

    final atCount = '@'.allMatches(email).length;
    if (atCount == 0) {
      return 'Email address must contain an @ symbol';
    }
    if (atCount > 1) {
      return 'Email address must contain only one @ symbol';
    }

    final parts = email.split('@');
    final local = parts[0];
    final domain = parts[1];

    if (local.isEmpty) {
      return 'Email address is missing the part before the @';
    }
    if (domain.isEmpty) {
      return 'Email address is missing a domain';
    }
    if (!domain.contains('.')) {
      return 'Email domain must include an extension (e.g. .com)';
    }
    if (domain.endsWith('.') || RegExp(r'\.[a-zA-Z]{0,1}$').hasMatch(domain)) {
      return 'Email domain extension is too short';
    }

    // Final structural check (valid characters / overall shape).
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Email address contains invalid characters';
    }

    return null;
  }
}
