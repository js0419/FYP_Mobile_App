import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import '../../services/shop_service.dart';
import '../../services/profile_service.dart';
import 'receipt.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _shopService = ShopService();
  final _profileService = ProfileService();

  final TextEditingController _cardholderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryMonthController = TextEditingController();
  final TextEditingController _expiryYearController = TextEditingController();
  final TextEditingController _cashPayerNameController = TextEditingController();
  final TextEditingController _cashNoteController = TextEditingController();

  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;
  bool _isLoading = true;
  bool _isProcessing = false;
  double _deliveryFee = 0.00;
  String _selectedPaymentMethod = 'paypal';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cashPayerNameController.dispose();
    _cashNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final addresses = await _profileService.getUserAddresses(userId);

        if (!mounted) return;

        setState(() {
          _addresses = addresses;
          if (addresses.isNotEmpty) {
            _selectedAddressId = addresses
                .firstWhere(
                  (a) => a['is_default'] == true,
                  orElse: () => addresses.first,
                )['address_id'];
          }
          _isLoading = false;
        });

        _updateDeliveryFee();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _updateDeliveryFee() {
    if (_selectedAddressId == null) {
      setState(() => _deliveryFee = 0.00);
      return;
    }

    final selectedAddress = _addresses.firstWhere(
      (a) => a['address_id'] == _selectedAddressId,
    );
    final stateName = selectedAddress['state'].toString().toLowerCase();

    setState(() {
      if (stateName.contains('sabah') ||
          stateName.contains('sarawak') ||
          stateName.contains('labuan')) {
        _deliveryFee = 15.00;
      } else {
        _deliveryFee = 10.00;
      }
    });
  }

  String _extractLastFour(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length <= 4) return cleaned;
    return cleaned.substring(cleaned.length - 4);
  }

  String? _validateCardForm() {
    final holder = _cardholderController.text.trim();
    final number = _cardNumberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final month = int.tryParse(_expiryMonthController.text.trim());
    final yearText = _expiryYearController.text.trim();
    final year = int.tryParse(yearText);

    if (holder.isEmpty) return 'Please enter cardholder name';
    if (number.length < 12 || number.length > 19) {
      return 'Please enter a valid card number';
    }
    if (month == null || month < 1 || month > 12) {
      return 'Please enter a valid expiry month';
    }
    if (year == null || (yearText.length != 2 && yearText.length != 4)) {
      return 'Please enter a valid expiry year';
    }

    return null;
  }

  String? _validateCashForm() {
    if (_cashPayerNameController.text.trim().isEmpty) {
      return 'Please enter payer name';
    }
    return null;
  }

  Map<String, dynamic> _buildFakePaymentDetails() {
    if (_selectedPaymentMethod == 'card') {
      return {
        'method_label': 'Card Payment',
        'cardholder_name': _cardholderController.text.trim(),
        'last_four': _extractLastFour(_cardNumberController.text),
        'expiry_month': _expiryMonthController.text.trim(),
        'expiry_year': _expiryYearController.text.trim(),
      };
    }

    return {
      'method_label': 'Cash Payment',
      'payer_name': _cashPayerNameController.text.trim(),
      'note': _cashNoteController.text.trim(),
    };
  }

  String _extractPaypalReference(Map params) {
    final paymentId = params['paymentId']?.toString();
    final payerId = params['payerID']?.toString();
    final token = params['token']?.toString();

    if (paymentId != null && paymentId.isNotEmpty) return paymentId;
    if (payerId != null && payerId.isNotEmpty) return payerId;
    if (token != null && token.isNotEmpty) return token;
    return 'paypal-success';
  }

  Future<void> _completeCheckout({
    required String paymentMethod,
    required String paymentMethodLabel,
    String? providerReference,
    Map<String, dynamic>? paymentDetails,
  }) async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address')),
      );
      return;
    }

    final total = widget.subtotal + _deliveryFee;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    setState(() => _isProcessing = true);

    try {
      final orderId = await _shopService.processCheckout(
        addressId: _selectedAddressId!,
        cartItems: widget.cartItems,
        subtotal: widget.subtotal,
        deliveryFee: _deliveryFee,
        paymentMethod: paymentMethod,
        providerReference: providerReference,
        receiptEmail: email,
        paymentDetails: paymentDetails,
      );

      try {
        await _shopService.sendReceiptEmail(
          email: email,
          orderId: orderId,
          paymentMethodLabel: paymentMethodLabel,
          subtotal: widget.subtotal,
          deliveryFee: _deliveryFee,
          totalAmount: total,
          items: widget.cartItems,
        );
      } catch (_) {
        // keep checkout successful even if email function fails
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(
            orderId: orderId,
            paymentMethodLabel: paymentMethodLabel,
            totalAmount: total,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _completeFakePayment() async {
    String? error;

    if (_selectedPaymentMethod == 'card') {
      error = _validateCardForm();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }

      await _completeCheckout(
        paymentMethod: 'card',
        paymentMethodLabel: 'Card Payment',
        providerReference: 'fake-card-${DateTime.now().millisecondsSinceEpoch}',
        paymentDetails: _buildFakePaymentDetails(),
      );
      return;
    }

    error = _validateCashForm();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    await _completeCheckout(
      paymentMethod: 'cash_on_delivery',
      paymentMethodLabel: 'Cash Payment',
      providerReference: 'fake-cash-${DateTime.now().millisecondsSinceEpoch}',
      paymentDetails: _buildFakePaymentDetails(),
    );
  }

  void _startPayPalCheckout() {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address')),
      );
      return;
    }

    final total = widget.subtotal + _deliveryFee;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => PaypalCheckoutView(
          sandboxMode: true,
          clientId: "AZMAmLK0-uDdVsZvoARbH_pSWuH1KMLe0__-X0ocm5pHlvyTcJ1PB8_hj3B_8aDNfxJZnR2NNClucZun",
          secretKey: "ECKE7DaKCSJMRUi69s3y6jy6eBQDZ4Hy7ZgROAmuO4Qfo0pVLYtSnEn8lL9Y9-RSOgrQ0q1U4mZ5Iey9",
          transactions: [
            {
              "amount": {
                "total": total.toStringAsFixed(2),
                "currency": "MYR",
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
            await _completeCheckout(
              paymentMethod: 'paypal',
              paymentMethodLabel: 'PayPal',
              providerReference: _extractPaypalReference(params),
              paymentDetails: {
                'method_label': 'PayPal',
                'paypal_response': params,
              },
            );
          },
          onError: (error) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Payment Error: $error")),
            );
          },
          onCancel: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment Cancelled")),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentSelector({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: _isProcessing
          ? null
          : () {
              setState(() => _selectedPaymentMethod = value);
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.black : Colors.black12,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: selected ? const Color(0xFFF7F7F7) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: _isProcessing
                  ? null
                  : (val) {
                      setState(() => _selectedPaymentMethod = val ?? 'paypal');
                    },
              activeColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        TextField(
          controller: _cardholderController,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryMonthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expiry Month',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _expiryYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expiry Year',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashForm() {
    return Column(
      children: [
        TextField(
          controller: _cashPayerNameController,
          decoration: const InputDecoration(
            labelText: 'Payer Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cashNoteController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final total = widget.subtotal + _deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'CHECKOUT',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DELIVERY ADDRESS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_addresses.isEmpty)
                    const Text(
                      'No address found. Please add one in profile.',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedAddressId,
                      isExpanded: true,
                      items: _addresses
                          .map(
                            (a) => DropdownMenuItem(
                              value: a['address_id'] as String,
                              child: Text(
                                '${a['recipient_name']} - ${a['state']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isProcessing
                          ? null
                          : (val) {
                              setState(() => _selectedAddressId = val);
                              _updateDeliveryFee();
                            },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 28),
                  const Text(
                    'PAYMENT METHOD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentSelector(
                    value: 'paypal',
                    title: 'PayPal',
                    subtitle: 'Real PayPal UI flow',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _buildPaymentSelector(
                    value: 'card',
                    title: 'Card Payment',
                    subtitle: 'Fake card payment for prototype',
                    icon: Icons.credit_card_outlined,
                  ),
                  _buildPaymentSelector(
                    value: 'cash',
                    title: 'Cash Payment',
                    subtitle: 'Fake cash payment for prototype',
                    icon: Icons.payments_outlined,
                  ),
                  if (_selectedPaymentMethod == 'card') ...[
                    const SizedBox(height: 4),
                    _buildCardForm(),
                  ],
                  if (_selectedPaymentMethod == 'cash') ...[
                    const SizedBox(height: 4),
                    _buildCashForm(),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F7),
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: Colors.black54)),
                    Text('RM${widget.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee', style: TextStyle(color: Colors.black54)),
                    Text(
                      'RM${_deliveryFee.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: _deliveryFee > 10 ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'RM${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedPaymentMethod == 'paypal'
                          ? const Color(0xFF003087)
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: (_addresses.isEmpty || _isProcessing)
                        ? null
                        : () {
                            if (_selectedPaymentMethod == 'paypal') {
                              _startPayPalCheckout();
                            } else {
                              _completeFakePayment();
                            }
                          },
                    child: _isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _selectedPaymentMethod == 'paypal'
                                ? 'PAY WITH PAYPAL'
                                : 'COMPLETE PAYMENT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}