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
// FULL ADDRESS FORM SCREEN (With Postcode Validation)
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
  final _postalCodeController = TextEditingController();
  
  String? _selectedState;
  
  final List<String> _malaysiaStates = [
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Melaka',
    'Negeri Sembilan', 'Pahang', 'Perak', 'Perlis', 'Pulau Pinang',
    'Putrajaya', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu'
  ];

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
      _postalCodeController.text = widget.address!['post_code'] ?? '';
      
      final savedState = widget.address!['state'] ?? '';
      if (_malaysiaStates.contains(savedState)) {
        _selectedState = savedState;
      }
      
      _isDefault = widget.address!['is_default'] ?? false;
    } else {
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
      // Ignore
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // POSTCODE VALIDATION LOGIC FOR MALAYSIA
  bool _isValidPostcodeForState(String postcode, String state) {
    if (postcode.length != 5) return false;
    final prefix = postcode.substring(0, 2);

    final Map<String, List<String>> validPrefixes = {
      'Johor': ['79', '80', '81', '82', '83', '84', '85', '86'],
      'Kedah': ['05', '06', '07', '08', '09'],
      'Kelantan': ['15', '16', '17', '18'],
      'Kuala Lumpur': ['50', '51', '52', '53', '54', '55', '56', '57', '58', '59', '60'],
      'Labuan': ['87'],
      'Melaka': ['75', '76', '77', '78'],
      'Negeri Sembilan': ['70', '71', '72', '73'],
      'Pahang': ['25', '26', '27', '28', '39', '49', '69'],
      'Perak': ['30', '31', '32', '33', '34', '35', '36', '39'],
      'Perlis': ['01', '02'],
      'Pulau Pinang': ['10', '11', '12', '13', '14'],
      'Putrajaya': ['62'],
      'Sabah': ['88', '89', '90', '91'],
      'Sarawak': ['93', '94', '95', '96', '97', '98'],
      'Selangor': ['40', '41', '42', '43', '44', '45', '46', '47', '48', '63', '64'],
      'Terengganu': ['20', '21', '22', '23', '24'],
    };

    final allowedPrefixes = validPrefixes[state];
    if (allowedPrefixes == null) return true; // Failsafe
    return allowedPrefixes.contains(prefix);
  }

  Future<void> _saveAddress() async {
    final postcode = _postalCodeController.text.trim();

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || 
        _streetController.text.isEmpty || _cityController.text.isEmpty || 
        postcode.isEmpty || _selectedState == null) {
      setState(() {
        _errorMessage = 'Please fill in all fields and select a state';
      });
      return;
    }

    // CHECK POSTCODE MATCHES STATE
    if (!_isValidPostcodeForState(postcode, _selectedState!)) {
      setState(() {
        _errorMessage = 'Postcode "$postcode" does not match $_selectedState state. Please check again.';
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
        await _profileService.addAddress(
          userId: userId,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _selectedState!,
          postalCode: postcode,
          country: 'Malaysia',
          isDefault: _isDefault,
        );
      } else {
        await _profileService.updateAddress(
          addressId: widget.address!['address_id'],
          userId: userId,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _selectedState!,
          postalCode: postcode,
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
                Expanded(child: _buildField('POSTCODE', _postalCodeController, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('CITY', _cityController)),
              ],
            ),
            const SizedBox(height: 20),
            
            const Text('STATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedState,
              hint: const Text('Select State', style: TextStyle(fontSize: 13, color: Colors.black45)),
              items: _malaysiaStates.map((state) => DropdownMenuItem(
                value: state,
                child: Text(state),
              )).toList(),
              onChanged: (val) => setState(() => _selectedState = val),
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFFF7F7F7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
              ),
            ),
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

  Widget _buildField(String label, TextEditingController controller, {bool isPhone = false, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : (isNumber ? TextInputType.number : TextInputType.text),
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