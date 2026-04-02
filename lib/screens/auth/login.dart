import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../shop/home.dart';
import 'register.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final hasSaved = await _authService.hasSavedCredentials();
    if (hasSaved) {
      final credentials = await _authService.getSavedCredentials();
      setState(() {
        _emailController.text = credentials['email'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.05),

                // Logo/Title - CLICKABLE TO HOME PAGE
                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'K&P',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.08),

                // Heading
                const Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue shopping',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    letterSpacing: 0.3,
                  ),
                ),

                SizedBox(height: screenHeight * 0.06),

                // Error Message
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

                // Email Field
                const Text(
                  'EMAIL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.black45),
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
                const SizedBox(height: 20),

                // Password Field
                const Text(
                  'PASSWORD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.black45),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.black54,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
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
                const SizedBox(height: 12),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        title: const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        checkColor: Colors.white,
                        activeColor: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.08),

                // Login Button
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
                    onPressed: _isLoading ? null : _handleLogin,
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
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Register Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
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
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'REGISTER',
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
      ),
    );
  }
}