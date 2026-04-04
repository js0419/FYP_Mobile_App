import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import '../../services/shop_service.dart';
import '../../services/profile_service.dart';
import 'receipt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;

  const CheckoutScreen({super.key, required this.cartItems, required this.subtotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _shopService = ShopService();
  final _profileService = ProfileService();
  
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;
  bool _isLoading = true;
  final double _deliveryFee = 10.00; // Flat rate for example

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final addresses = await _profileService.getUserAddresses(userId);
        setState(() {
          _addresses = addresses;
          if (addresses.isNotEmpty) {
            _selectedAddressId = addresses.firstWhere((a) => a['is_default'] == true, orElse: () => addresses.first)['address_id'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startPayPalCheckout() {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an address')));
      return;
    }

    final total = widget.subtotal + _deliveryFee;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => PaypalCheckoutView(
        sandboxMode: true, // Set to false when going live
        clientId: "YOUR_PAYPAL_CLIENT_ID_HERE", // Get from PayPal Developer Dashboard
        secretKey: "YOUR_PAYPAL_SECRET_KEY_HERE", 
        transactions: [
          {
            "amount": {
              "total": total.toStringAsFixed(2),
              "currency": "MYR", // Or USD depending on your PayPal account support
              "details": {
                "subtotal": widget.subtotal.toStringAsFixed(2),
                "shipping": _deliveryFee.toStringAsFixed(2),
                "shipping_discount": 0
              }
            },
            "description": "K&P E-Commerce Order",
          }
        ],
        note: "Contact us for any questions on your order.",
        onSuccess: (Map params) async {
          // Payment Successful! Process the order in DB
          try {
            final orderId = await _shopService.processCheckout(
              addressId: _selectedAddressId!,
              cartItems: widget.cartItems,
              subtotal: widget.subtotal,
              deliveryFee: _deliveryFee,
              paymentMethod: 'card', // mapped to enum
            );

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => ReceiptScreen(orderId: orderId)),
                (route) => false,
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Database Error: $e")));
          }
        },
        onError: (error) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Error: $error")));
        },
        onCancel: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Cancelled")));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
    final total = widget.subtotal + _deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CHECKOUT', style: TextStyle(color: Colors.black, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DELIVERY ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            if (_addresses.isEmpty)
              const Text('No address found. Please add one in profile.', style: TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedAddressId,
                isExpanded: true,
                items: _addresses.map((a) => DropdownMenuItem(
                  value: a['address_id'] as String,
                  child: Text('${a['recipient_name']} - ${a['address_line1']}, ${a['city']}'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedAddressId = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            
            const Spacer(),
            const Divider(),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Subtotal', style: TextStyle(color: Colors.black54)),
              Text('RM${widget.subtotal.toStringAsFixed(2)}')
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Delivery Fee', style: TextStyle(color: Colors.black54)),
              Text('RM${_deliveryFee.toStringAsFixed(2)}')
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('RM${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003087), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _addresses.isEmpty ? null : _startPayPalCheckout,
                child: const Text('PAY WITH PAYPAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}