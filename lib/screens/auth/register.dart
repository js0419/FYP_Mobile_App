import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/validation_service.dart';
import '../shop/home.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validate all fields
    final firstNameError =
        ValidationService.validateName(_firstNameController.text, 'First name');
    if (firstNameError != null) {
      setState(() {
        _errorMessage = firstNameError;
      });
      return;
    }

    final lastNameError =
        ValidationService.validateName(_lastNameController.text, 'Last name');
    if (lastNameError != null) {
      setState(() {
        _errorMessage = lastNameError;
      });
      return;
    }

    final emailError = ValidationService.validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() {
        _errorMessage = emailError;
      });
      return;
    }

    final phoneError =
        ValidationService.validatePhone(_phoneController.text);
    if (phoneError != null) {
      setState(() {
        _errorMessage = phoneError;
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    final passwordError =
        ValidationService.validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() {
        _errorMessage = passwordError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      setState(() {
        _successMessage =
            'Registration successful! Please check your email to confirm your account.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Registration successful! Check your email to confirm. Redirecting to login...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Wait 3 seconds then redirect to login
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('AuthException: ', '');
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
          'CREATE ACCOUNT',
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
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

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
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),

              _buildFormField(
                label: 'FIRST NAME',
                controller: _firstNameController,
                hintText: 'e.g., John',
                helperText: 'Letters only (2-50 characters)',
              ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'LAST NAME',
                controller: _lastNameController,
                hintText: 'e.g., Doe',
                helperText: 'Letters only (2-50 characters)',
              ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'EMAIL',
                controller: _emailController,
                hintText: 'email@example.com',
                helperText: 'You\'ll use this to login',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'PHONE NUMBER',
                controller: _phoneController,
                hintText: '0123456789',
                helperText: 'Malaysian format (10-11 digits)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                label: 'PASSWORD',
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                hintText: 'Enter password',
                helperText: 'At least 6 characters',
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                label: 'CONFIRM PASSWORD',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                hintText: 'Confirm password',
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'REGISTER',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required String hintText,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.black54,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ]
      ],
    );
  }
}