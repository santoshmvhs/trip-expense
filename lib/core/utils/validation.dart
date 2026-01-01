/// Input validation utilities for security
class ValidationUtils {
  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validate text length
  static bool isValidLength(String text, {int min = 1, int? max}) {
    if (text.length < min) return false;
    if (max != null && text.length > max) return false;
    return true;
  }

  /// Validate numeric amount (positive, within range)
  static bool isValidAmount(double amount, {double min = 0, double? max}) {
    if (amount < min) return false;
    if (max != null && amount > max) return false;
    if (amount.isNaN || amount.isInfinite) return false;
    return true;
  }

  /// Sanitize text input (remove potentially dangerous characters)
  static String sanitizeText(String text) {
    // Remove null bytes and control characters
    return text.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  /// Validate file type for receipts
  static bool isValidReceiptFileType(String mimeType) {
    const allowedTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'application/pdf',
    ];
    return allowedTypes.contains(mimeType.toLowerCase());
  }

  /// Validate file size (in bytes)
  static bool isValidFileSize(int sizeInBytes, {int maxSizeMB = 5}) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return sizeInBytes <= maxSizeBytes && sizeInBytes > 0;
  }

  /// Validate password strength
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strength = 0;
    if (hasUpper) strength++;
    if (hasLower) strength++;
    if (hasDigit) strength++;
    if (hasSpecial) strength++;
    if (password.length >= 12) strength++;

    if (strength <= 2) return PasswordStrength.weak;
    if (strength <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Validate UUID format
  static bool isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}

