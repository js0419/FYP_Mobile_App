import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'validation_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me_enabled';

  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final emailError = ValidationService.validateEmail(email);
      if (emailError != null) throw Exception(emailError);

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (rememberMe) {
        await _secureStorage.write(key: _emailKey, value: email.trim());
        await _secureStorage.write(key: _passwordKey, value: password);
        await _secureStorage.write(key: _rememberMeKey, value: 'true');
      } else {
        await _clearStoredCredentials();
      }

      return response;
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();

      if (message.contains('invalid login credentials') ||
          message.contains('invalid email or password') ||
          e.statusCode == '400') {
        throw Exception('Email or password is wrong');
      }

      if (message.contains('email not confirmed')) {
        throw Exception('Please verify your email before logging in');
      }

      if (message.contains('too many requests') ||
          message.contains('rate limit') ||
          e.statusCode == '429') {
        throw Exception('Too many login attempts. Please try again later');
      }

      throw Exception('Login failed. Please try again');
    } catch (e) {
      throw Exception('Login failed. Please try again');
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      // Validate inputs
      final emailError = ValidationService.validateEmail(email);
      if (emailError != null) throw Exception(emailError);

      final firstNameError = ValidationService.validateName(
        firstName,
        'First name',
      );
      if (firstNameError != null) throw Exception(firstNameError);

      final lastNameError = ValidationService.validateName(
        lastName,
        'Last name',
      );
      if (lastNameError != null) throw Exception(lastNameError);

      final phoneError = ValidationService.validatePhone(phoneNumber);
      if (phoneError != null) throw Exception(phoneError);

      final passwordError = _validatePasswordStrength(password);
      if (passwordError != null) throw Exception(passwordError);

      // Sign up with Supabase Auth AND pass user data as metadata
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': '${firstName.trim()} ${lastName.trim()}',
          'phone': phoneNumber.trim(),
        },
      );

      if (response.user != null) {
        try {
          final userId = response.user!.id;
          final fullName = '${firstName.trim()} ${lastName.trim()}';
          final now = DateTime.now().toIso8601String();

          print('DEBUG: Creating user profile for $userId');
          print('DEBUG: Name: $fullName, Phone: $phoneNumber, Email: $email');

          // Insert user profile (trigger will create base profile, this updates it)
          final existingUser = await _supabase
              .from('users')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

          if (existingUser != null) {
            // Update existing profile created by trigger
            await _supabase
                .from('users')
                .update({
                  'user_name': fullName,
                  'user_phone': phoneNumber.trim(),
                  'user_email': email.trim(),
                  'updated_at': now,
                })
                .eq('user_id', userId);

            print('DEBUG: User profile updated with phone and name');
          } else {
            // Insert if trigger didn't create it
            await _supabase.from('users').insert({
              'user_id': userId,
              'user_name': fullName,
              'user_phone': phoneNumber.trim(),
              'user_email': email.trim(),
              'status': 'active',
              'role': 'customer',
              'created_at': now,
              'updated_at': now,
            });

            print('DEBUG: User profile created');
          }
        } catch (dbError) {
          print('ERROR: Failed to update user profile: $dbError');
          // Don't rethrow - signup was successful
        }
      }

      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<String?> getCurrentUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final row = await _supabase
        .from('users')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    return row?['role']?.toString();
  }

  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  String? _validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 50) {
      return 'Password must be less than 50 characters';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must include at least one special character (!@#\$%^&*)';
    }

    return null;
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      final emailError = ValidationService.validateEmail(email);
      if (emailError != null) throw Exception(emailError);

      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );
    } on AuthException catch (e) {
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final passwordError = _validatePasswordStrength(newPassword);
      if (passwordError != null) throw Exception(passwordError);

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  Future<bool> hasSavedCredentials() async {
    final rememberMe = await _secureStorage.read(key: _rememberMeKey);
    return rememberMe == 'true';
  }

  Future<Map<String, String>> getSavedCredentials() async {
    final email = await _secureStorage.read(key: _emailKey) ?? '';
    final password = await _secureStorage.read(key: _passwordKey) ?? '';

    return {'email': email, 'password': password};
  }

  Future<void> forgetDevice() async {
    await _clearStoredCredentials();
  }

  Future<void> _clearStoredCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _rememberMeKey);
  }
}
