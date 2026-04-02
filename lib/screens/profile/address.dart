import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../services/validation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _profileService = ProfileService();
  late Future<List<Map<String, dynamic>>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _addressesFuture = _profileService.getUserAddresses(user.id);
    }
  }

  void _showAddressForm({Map<String, dynamic>? address}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormScreen(
          address: address,
          onSave: () {
            setState(() {
              _loadAddresses();
            });
          },
        ),
      ),
    );
  }

  void _deleteAddress(String addressId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _profileService.deleteAddress(addressId);
                setState(() {
                  _loadAddresses();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address deleted successfully'),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
          'DELIVERY ADDRESSES',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showAddressForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.black54),
              ),
            );
          }

          final addresses = snapshot.data ?? [];

          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off_outlined,
                        size: 64, color: Colors.black26),
                    const SizedBox(height: 16),
                    const Text(
                      'NO ADDRESSES YET',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a delivery address to get started',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 160,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _showAddressForm(),
                        child: const Text(
                          'ADD ADDRESS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              final isDefault = address['is_default'] ?? false;

              return Container(
                margin: EdgeInsets.only(
                  bottom: isSmallScreen ? 12.0 : 16.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDefault ? Colors.black : Colors.black12,
                    width: isDefault ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              address['recipient_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address['phone'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${address['address_line1']}, ${address['post_code']} ${address['city']}, ${address['state']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showAddressForm(address: address),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('EDIT'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () =>
                                _deleteAddress(address['address_id']),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('DELETE'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? address;
  final VoidCallback onSave;

  const AddressFormScreen({
    super.key,
    this.address,
    required this.onSave,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _profileService = ProfileService();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  bool _isDefault = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.address?['recipient_name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.address?['phone'] ?? '');
    _streetController =
        TextEditingController(text: widget.address?['address_line1'] ?? '');
    _cityController = TextEditingController(text: widget.address?['city'] ?? '');
    _stateController =
        TextEditingController(text: widget.address?['state'] ?? '');
    _postalCodeController =
        TextEditingController(text: widget.address?['post_code'] ?? '');
    _countryController =
        TextEditingController(text: widget.address?['country'] ?? 'Malaysia');
    _isDefault = widget.address?['is_default'] ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    // Validate all fields
    final nameError =
        ValidationService.validateName(_fullNameController.text, 'Full name');
    if (nameError != null) {
      setState(() {
        _errorMessage = nameError;
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

    final streetError =
        ValidationService.validateStreet(_streetController.text);
    if (streetError != null) {
      setState(() {
        _errorMessage = streetError;
      });
      return;
    }

    final cityError =
        ValidationService.validateCity(_cityController.text, 'City');
    if (cityError != null) {
      setState(() {
        _errorMessage = cityError;
      });
      return;
    }

    final stateError =
        ValidationService.validateCity(_stateController.text, 'State');
    if (stateError != null) {
      setState(() {
        _errorMessage = stateError;
      });
      return;
    }

    final postalError =
        ValidationService.validatePostalCode(_postalCodeController.text);
    if (postalError != null) {
      setState(() {
        _errorMessage = postalError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not found');

      if (widget.address != null) {
        await _profileService.updateAddress(
          addressId: widget.address!['address_id'],
          userId: user.id,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        await _profileService.addAddress(
          userId: user.id,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
          isDefault: _isDefault,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address != null
                ? 'Address updated successfully'
                : 'Address added successfully'),
            backgroundColor: Colors.black,
          ),
        );
        widget.onSave();
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
        title: Text(
          widget.address != null ? 'EDIT ADDRESS' : 'ADD ADDRESS',
          style: const TextStyle(
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

              _buildFormField(
                label: 'FULL NAME',
                controller: _fullNameController,
                hintText: 'e.g., John Doe',
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

              _buildFormField(
                label: 'STREET ADDRESS',
                controller: _streetController,
                hintText: 'e.g., 123 Jalan Merdeka',
                helperText: 'Min 5, Max 100 characters',
              ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'POSTAL CODE',
                controller: _postalCodeController,
                hintText: '50000',
                helperText: 'Malaysian format (5 digits)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'CITY',
                controller: _cityController,
                hintText: 'e.g., Kuala Lumpur',
                helperText: 'City name (2-50 characters)',
              ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'STATE',
                controller: _stateController,
                hintText: 'e.g., Selangor',
                helperText: 'State name (2-50 characters)',
              ),
              const SizedBox(height: 20),

              _buildFormField(
                label: 'COUNTRY',
                controller: _countryController,
                hintText: 'e.g., Malaysia',
              ),
              const SizedBox(height: 20),

              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                title: const Text(
                  'Set as default address',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                checkColor: Colors.white,
                activeColor: Colors.black,
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
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.address != null ? 'UPDATE ADDRESS' : 'ADD ADDRESS',
                          style: const TextStyle(
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
}