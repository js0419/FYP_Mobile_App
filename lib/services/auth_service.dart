import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'validation_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _emailKey = 'stored_email';
  static const String _passwordKey = 'stored_password';
  static const String _rememberMeKey = 'remember_me';

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
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Register with email and password - Fixed to insert phone number
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

      final firstNameError = ValidationService.validateName(firstName, 'First name');
      if (firstNameError != null) throw Exception(firstNameError);

      final lastNameError = ValidationService.validateName(lastName, 'Last name');
      if (lastNameError != null) throw Exception(lastNameError);

      final phoneError = ValidationService.validatePhone(phoneNumber);
      if (phoneError != null) throw Exception(phoneError);

      final passwordError = ValidationService.validatePassword(password);
      if (passwordError != null) throw Exception(passwordError);

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        // Create user profile with phone number
        await _supabase.from('users').insert({
          'user_id': response.user!.id,
          'user_email': email.trim(),
          'user_name': '${firstName.trim()} ${lastName.trim()}',
          'user_phone': phoneNumber.trim(),
          'status': 'active',
          'role': 'customer',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      await _clearStoredCredentials();
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
      final passwordError = ValidationService.validatePassword(newPassword);
      if (passwordError != null) throw Exception(passwordError);

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
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
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);

    return {
      'email': email ?? '',
      'password': password ?? '',
    };
  }

  Future<bool> autoLogin() async {
    try {
      if (!await hasSavedCredentials()) {
        return false;
      }

      final credentials = await getSavedCredentials();
      if (credentials['email']!.isEmpty || credentials['password']!.isEmpty) {
        return false;
      }

      await login(
        email: credentials['email']!,
        password: credentials['password']!,
        rememberMe: true,
      );

      return true;
    } catch (e) {
      await _clearStoredCredentials();
      return false;
    }
  }

  Future<void> _clearStoredCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _rememberMeKey);
  }
}