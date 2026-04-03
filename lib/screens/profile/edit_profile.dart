import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../services/validation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileService = ProfileService();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _profilePicController;

  String? _selectedGender;
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final nameParts = (widget.userProfile['user_name'] ?? '').toString().split(' ');
    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts[0] : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _phoneController =
        TextEditingController(text: widget.userProfile['user_phone'] ?? '');
    _emailController = TextEditingController(
        text: Supabase.instance.client.auth.currentUser?.email ?? '');
    _profilePicController =
        TextEditingController(text: widget.userProfile['user_profile_pic'] ?? '');

    // Set initial gender
    final gender = widget.userProfile['user_gender'];
    if (gender != null) {
      _selectedGender = gender[0].toUpperCase() + gender.substring(1);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _profilePicController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
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

    final phoneError =
        ValidationService.validatePhone(_phoneController.text);
    if (phoneError != null) {
      setState(() {
        _errorMessage = phoneError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not found');
      }

      await _profileService.updateUserProfile(
        userId: user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gender: _selectedGender?.toLowerCase(),
        profilePic: _profilePicController.text.trim(),
      );

      setState(() {
        _successMessage = 'Profile updated successfully!';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context, true);
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
          'EDIT PROFILE',
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
                label: 'PHONE NUMBER',
                controller: _phoneController,
                hintText: '0123456789',
                helperText: 'Malaysian format (10-11 digits)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Gender Dropdown
              const Text(
                'GENDER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Select your gender',
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    ),
                    items: _genderOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.arrow_drop_down,
                          color: Colors.black54, size: 24),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Picture URL
              _buildFormField(
                label: 'PROFILE PICTURE URL',
                controller: _profilePicController,
                hintText: 'e.g., profile.png',
                helperText: 'Image filename from storage (optional)',
              ),
              const SizedBox(height: 8),
              if (_profilePicController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📸 Current Profile Picture:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _profilePicController.text,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'EMAIL',
                controller: _emailController,
                hintText: 'email@example.com',
                enabled: false,
                helperText: 'Email cannot be changed',
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
                  onPressed: _isLoading ? null : _updateProfile,
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
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
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
    bool enabled = true,
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
          enabled: enabled,
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                const TextStyle(fontSize: 13, color: Colors.black45),
            filled: true,
            fillColor:
                enabled ? const Color(0xFFF7F7F7) : const Color(0xFFF0F0F0),
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
}