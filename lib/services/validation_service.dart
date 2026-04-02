class ValidationService {
  // Phone number validation for Malaysia format: 601XXXXXXXXX or 01XXXXXXXXX
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Malaysian phone: 10-11 digits
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return 'Phone must be 10-11 digits (e.g., 0123456789)';
    }

    // Must start with 0 or 6 (after country code)
    if (!cleanPhone.startsWith('0') && !cleanPhone.startsWith('6')) {
      return 'Phone must start with 0 or 6';
    }

    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (value.length > 50) {
      return '$fieldName must be less than 50 characters';
    }

    // Only letters, spaces, and hyphens allowed
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, and hyphens';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 50) {
      return 'Password must be less than 50 characters';
    }

    return null;
  }

  // Postal code validation for Malaysia
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Postal code is required';
    }

    final cleanCode = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanCode.length != 5) {
      return 'Postal code must be 5 digits (e.g., 50000)';
    }

    return null;
  }

  // Street address validation
  static String? validateStreet(String? value) {
    if (value == null || value.isEmpty) {
      return 'Street address is required';
    }

    if (value.length < 5) {
      return 'Street address is too short';
    }

    if (value.length > 100) {
      return 'Street address is too long';
    }

    return null;
  }

  // City/State validation
  static String? validateCity(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < 2) {
      return '$fieldName is too short';
    }

    if (value.length > 50) {
      return '$fieldName is too long';
    }

    return null;
  }

  // Format phone number to display format
  static String formatPhoneDisplay(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return phone;

    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    }

    return phone;
  }

  // Format postal code
  static String formatPostalCode(String code) {
    final cleaned = code.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.substring(0, cleaned.length > 5 ? 5 : cleaned.length);
  }
}