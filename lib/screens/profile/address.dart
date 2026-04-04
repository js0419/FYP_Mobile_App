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
          style: TextStyle(color: Colors.black, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.w600),
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
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black54)));
          }

          final addresses = snapshot.data ?? [];

          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off_outlined, size: 64, color: Colors.black26),
                    const SizedBox(height: 16),
                    const Text('NO ADDRESSES YET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    const Text('Add a delivery address to get started', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 160, height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () => _showAddressForm(),
                        child: const Text('ADD ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
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
                          Row(
                            children: [
                              Text(
                                address['recipient_name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ),
                              ]
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showAddressForm(address: address),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                onPressed: () => _deleteAddress(address['address_id']),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(address['phone'] ?? '', style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(address['address_line1'] ?? '', style: const TextStyle(color: Colors.black54)),
                      Text('${address['post_code']} ${address['city']}, ${address['state']}', style: const TextStyle(color: Colors.black54)),
                      Text(address['country'] ?? '', style: const TextStyle(color: Colors.black54)),
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

// ----------------------------------------------------
// FULL ADDRESS FORM SCREEN (With Auto-Fill User Info)
// ----------------------------------------------------
class AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? address;
  final VoidCallback onSave;

  const AddressFormScreen({super.key, this.address, required this.onSave});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _profileService = ProfileService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  bool _isDefault = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _nameController.text = widget.address!['recipient_name'] ?? '';
      _phoneController.text = widget.address!['phone'] ?? '';
      _streetController.text = widget.address!['address_line1'] ?? '';
      _cityController.text = widget.address!['city'] ?? '';
      _stateController.text = widget.address!['state'] ?? '';
      _postalCodeController.text = widget.address!['post_code'] ?? '';
      _isDefault = widget.address!['is_default'] ?? false;
    } else {
      // PRE-FILL USER DATA FOR NEW ADDRESS
      _loadUserDataForNewAddress();
    }
  }

  Future<void> _loadUserDataForNewAddress() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await Supabase.instance.client
            .from('users')
            .select('user_name, user_phone')
            .eq('user_id', user.id)
            .single();
        
        if (mounted) {
          setState(() {
            _nameController.text = userData['user_name'] ?? '';
            _phoneController.text = userData['user_phone'] ?? '';
          });
        }
      }
    } catch (e) {
      // Safely ignore if user profile data fails to load
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    // Validate fields manually to show error
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _streetController.text.isEmpty || _cityController.text.isEmpty || _stateController.text.isEmpty || _postalCodeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      if (widget.address == null) {
        // Create new address
        await _profileService.addAddress(
          userId: userId,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: 'Malaysia',
          isDefault: _isDefault,
        );
      } else {
        // Update existing address
        await _profileService.updateAddress(
          addressId: widget.address!['address_id'],
          userId: userId,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: 'Malaysia',
          isDefault: _isDefault,
        );
      }

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.address == null ? 'ADD NEW ADDRESS' : 'EDIT ADDRESS',
          style: const TextStyle(color: Colors.black, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), border: Border.all(color: Colors.red[200]!), borderRadius: BorderRadius.circular(8)),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
              
            _buildField('FULL NAME', _nameController),
            const SizedBox(height: 20),
            _buildField('PHONE NUMBER', _phoneController, isPhone: true),
            const SizedBox(height: 20),
            _buildField('STREET ADDRESS', _streetController),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: _buildField('POSTCODE', _postalCodeController)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('CITY', _cityController)),
              ],
            ),
            const SizedBox(height: 20),
            _buildField('STATE', _stateController),
            const SizedBox(height: 20),
            
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set as default address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              value: _isDefault,
              activeColor: Colors.black,
              onChanged: (bool value) {
                setState(() => _isDefault = value);
              },
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _isLoading ? null : _saveAddress,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFF7F7F7),
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