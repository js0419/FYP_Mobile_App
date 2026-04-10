import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_service.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _profileService = ProfileService();
  
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  String _errorMessage = '';
  String _successMessage = '';
  String? _oldPasswordError; // Error specifically for the old password field

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    // 1. Basic empty field validation
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
        _oldPasswordError = null;
      });
      return;
    }

    // 2. Check if new passwords match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
        _oldPasswordError = null;
      });
      return;
    }

    // 3. Check new password length
    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'New password must be at least 6 characters';
        _oldPasswordError = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
      _oldPasswordError = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('User is not logged in properly.');
      }

      // 4. VERIFY OLD PASSWORD FIRST
      // We do this by attempting a sign-in with the current email and the old password
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: currentUser.email!,
          password: _oldPasswordController.text,
        );
      } on AuthException catch (_) {
        // If this throws, the old password was wrong!
        setState(() {
          _oldPasswordError = 'Incorrect current password';
          _isLoading = false;
        });
        return; // Stop the process here
      }

      // 5. IF OLD PASSWORD IS CORRECT, UPDATE TO NEW PASSWORD
      await _profileService.updatePassword(_newPasswordController.text);

      setState(() {
        _successMessage = 'Password updated successfully!';
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      // Pop after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'CHANGE PASSWORD',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // General Error Message (Top)
              if (_errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              // Success Message
              if (_successMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    border: Border.all(color: Colors.green[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),

              const Text(
                'PASSWORD REQUIREMENTS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '• At least 6 characters long\n• Use a strong combination of letters, numbers, and symbols',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.6),
                ),
              ),
              const SizedBox(height: 32),

              // OLD PASSWORD FIELD
              const Text(
                'CURRENT PASSWORD',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _oldPasswordController,
                obscureText: _obscureOldPassword,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Enter current password',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black54,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), 
                    borderSide: BorderSide(color: _oldPasswordError != null ? Colors.red : Colors.black12)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), 
                    borderSide: BorderSide(color: _oldPasswordError != null ? Colors.red : Colors.black, width: 1.5)
                  ),
                ),
              ),
              // ERROR MESSAGE DISPLAYED DIRECTLY UNDER THE OLD PASSWORD FIELD
              if (_oldPasswordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    _oldPasswordError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                
              const SizedBox(height: 24),

              // NEW PASSWORD FIELD
              const Text(
                'NEW PASSWORD',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black54,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // CONFIRM PASSWORD FIELD
              const Text(
                'CONFIRM NEW PASSWORD',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black54,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                ),
              ),
              const SizedBox(height: 32),

              // UPDATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _updatePassword,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'UPDATE PASSWORD',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}