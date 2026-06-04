import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _adminService = AdminService();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _adminService.getOrders();
      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await _adminService.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('MANAGE ORDERS'),
        backgroundColor: const Color(0xFFF8F8F8),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final userData =
                      (order['users'] as Map<String, dynamic>?) ?? {};
                  final deliveryData =
                      (order['deliveries'] as Map<String, dynamic>?) ?? {};
                  final payments = (order['payments'] as List<dynamic>?) ?? [];

                  String paymentText = 'No payment';
                  if (payments.isNotEmpty) {
                    final payment = payments.first as Map<String, dynamic>;
                    paymentText =
                        '${payment['payment_method']} / ${payment['payment_status']}';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${order['order_id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('User: ${userData['user_name'] ?? '-'}'),
                        Text('Email: ${userData['user_email'] ?? '-'}'),
                        Text('Subtotal: RM${order['order_subtotal'] ?? 0}'),
                        Text('Delivery: ${deliveryData['delivery_status'] ?? '-'}'),
                        Text('Payment: $paymentText'),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: order['orders_status'],
                          decoration: InputDecoration(
                            labelText: 'Order Status',
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                            DropdownMenuItem(value: 'processing', child: Text('Processing')),
                            DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                            DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                          ],
                          onChanged: (value) {
                            if (value != null &&
                                value != order['orders_status']) {
                              _updateStatus(order['order_id'], value);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}