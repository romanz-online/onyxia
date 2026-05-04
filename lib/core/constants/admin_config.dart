/// Configuration class for admin-related settings
class AdminConfig {
  /// List of admin email addresses that have access to all projects
  /// regardless of whether they've been added to the project
  static const List<String> adminEmails = [];

  /// Checks if the given email is an admin email
  static bool isAdminEmail(String email) => adminEmails.contains(email.toLowerCase().trim());
}
