import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';
import '../../services/validation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

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
  
  // AI Data Controllers
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String? _selectedGender;
  String? _selectedStyleId;
  List<Map<String, dynamic>> _styles = [];

  XFile? _selectedImage;
  String? _profilePicUrl;
  bool _isLoadingImage = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStyles();
    
    final rawName = (widget.userProfile['user_name'] ?? '').toString().trim();
    final nameParts = rawName.isNotEmpty ? rawName.split(RegExp(r'\s+')) : [];
    
    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts[0] : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    
    _phoneController = TextEditingController(
      text: (widget.userProfile['user_phone'] ?? '').toString().trim()
    );
    
    _emailController = TextEditingController(
        text: Supabase.instance.client.auth.currentUser?.email ?? '');

    // AI Fields
    _heightController = TextEditingController(
      text: widget.userProfile['height_cm']?.toString() ?? ''
    );
    _weightController = TextEditingController(
      text: widget.userProfile['weight_kg']?.toString() ?? ''
    );
    _selectedStyleId = widget.userProfile['preferred_style_id'];

    _profilePicUrl = widget.userProfile['user_profile_pic'];

    final gender = widget.userProfile['user_gender'];
    if (gender != null && gender.toString().isNotEmpty) {
      _selectedGender = gender[0].toUpperCase() + gender.substring(1);
    }
  }

  Future<void> _loadStyles() async {
    try {
      final styles = await _profileService.getStyles();
      setState(() {
        _styles = styles;
      });
    } catch (e) {
      print('Error loading styles: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _profilePicUrl = null;
    });
  }

  Future<void> _updateProfile() async {
    final firstNameError = ValidationService.validateName(_firstNameController.text, 'First name');
    if (firstNameError != null) { setState(() { _errorMessage = firstNameError; }); return; }

    final lastNameError = ValidationService.validateName(_lastNameController.text, 'Last name');
    if (lastNameError != null) { setState(() { _errorMessage = lastNameError; }); return; }

    final phoneError = ValidationService.validatePhone(_phoneController.text);
    if (phoneError != null) { setState(() { _errorMessage = phoneError; }); return; }

    // Validate Height & Weight manually
    double? height;
    double? weight;
    if (_heightController.text.isNotEmpty) {
      height = double.tryParse(_heightController.text);
      if (height == null || height < 100 || height > 250) {
        setState(() { _errorMessage = 'Height must be between 100cm and 250cm'; }); return;
      }
    }
    if (_weightController.text.isNotEmpty) {
      weight = double.tryParse(_weightController.text);
      if (weight == null || weight < 20 || weight > 300) {
        setState(() { _errorMessage = 'Weight must be between 20kg and 300kg'; }); return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not found');

      String? uploadedPicUrl = _profilePicUrl;

      if (_selectedImage != null) {
        setState(() { _isLoadingImage = true; });
        final bytes = await _selectedImage!.readAsBytes();
        uploadedPicUrl = await _profileService.uploadProfilePicture(
          userId: user.id,
          imageBytes: bytes,
        );
        setState(() { _isLoadingImage = false; });
      }

      await _profileService.updateUserProfile(
        userId: user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gender: _selectedGender?.toLowerCase(),
        profilePicUrl: uploadedPicUrl,
        height: height,
        weight: weight,
        preferredStyleId: _selectedStyleId,
      );

      setState(() {
        _successMessage = 'Profile updated successfully!';
        _selectedImage = null;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _isLoading = false; _isLoadingImage = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'EDIT PROFILE',
          style: TextStyle(color: Colors.black, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.w600),
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
                  width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), border: Border.all(color: Colors.red[200]!), borderRadius: BorderRadius.circular(8)),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),

              if (_successMessage.isNotEmpty)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), border: Border.all(color: Colors.green[200]!), borderRadius: BorderRadius.circular(8)),
                  child: Text(_successMessage, style: const TextStyle(color: Colors.green, fontSize: 12)),
                ),

              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(60), border: Border.all(color: Colors.black12, width: 2)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: _selectedImage != null
                            ? (kIsWeb ? Image.network(_selectedImage!.path, fit: BoxFit.cover) : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                            : _profilePicUrl != null && _profilePicUrl!.isNotEmpty
                                ? Image.network(_profilePicUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.person, size: 60, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200, height: 40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                        onPressed: _isLoadingImage ? null : _pickImage,
                        icon: _isLoadingImage ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.image_outlined, size: 18),
                        label: Text(_selectedImage != null ? 'CHANGE PICTURE' : 'UPLOAD PICTURE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty || _selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: 200, height: 40,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                            onPressed: _removeImage, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('REMOVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text('PERSONAL DETAILS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
              const Divider(),
              const SizedBox(height: 16),

              _buildFormField(label: 'FIRST NAME', controller: _firstNameController, hintText: 'e.g., John'),
              const SizedBox(height: 20),
              _buildFormField(label: 'LAST NAME', controller: _lastNameController, hintText: 'e.g., Doe'),
              const SizedBox(height: 20),
              _buildFormField(label: 'PHONE NUMBER', controller: _phoneController, hintText: '0123456789', keyboardType: TextInputType.phone),
              const SizedBox(height: 20),

              const Text('GENDER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender, isExpanded: true,
                    hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Select your gender', style: TextStyle(color: Colors.black45, fontSize: 13))),
                    items: _genderOptions.map((String value) { return DropdownMenuItem<String>(value: value, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(value))); }).toList(),
                    onChanged: (String? newValue) { setState(() { _selectedGender = newValue; }); },
                    icon: const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.arrow_drop_down, color: Colors.black54, size: 24)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text('AI RECOMMENDATION DATA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Colors.blueAccent)),
              const Text('Used to recommend perfect outfits & sizes for you', style: TextStyle(fontSize: 11, color: Colors.black54)),
              const Divider(),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildFormField(label: 'HEIGHT (CM)', controller: _heightController, hintText: '175', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFormField(label: 'WEIGHT (KG)', controller: _weightController, hintText: '65.5', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 20),

              const Text('PREFERRED STYLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStyleId, isExpanded: true,
                    hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Select a style you like', style: TextStyle(color: Colors.black45, fontSize: 13))),
                    items: _styles.map((style) { return DropdownMenuItem<String>(value: style['style_id'], child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(style['style_name']))); }).toList(),
                    onChanged: (String? newValue) { setState(() { _selectedStyleId = newValue; }); },
                    icon: const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.arrow_drop_down, color: Colors.black54, size: 24)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SAVE CHANGES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required TextEditingController controller, required String hintText, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, keyboardType: keyboardType, cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hintText, hintStyle: const TextStyle(fontSize: 13, color: Colors.black45), filled: true, fillColor: const Color(0xFFF7F7F7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
          ),
        ),
      ],
    );
  }
}