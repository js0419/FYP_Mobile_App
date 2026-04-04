import 'package:flutter/material.dart';
import '../../services/shop_service.dart';
import '../../services/product_image_service.dart';
import 'checkout.dart';
import 'home.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _shopService = ShopService();
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _shopService.getCartItems();
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cart: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String cartId) async {
    try {
      await _shopService.removeFromCart(cartId);
      _loadCartItems(); // Reload after delete
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item: $e')),
      );
    }
  }

  double _calculateSubtotal() {
    double total = 0;
    for (var item in _cartItems) {
      final price = (item['products']['product_price'] ?? 0) as num;
      final qty = (item['quantity'] ?? 0) as num;
      total += (price * qty);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final subtotal = _calculateSubtotal();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'MY CART',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  const Text('YOUR CART IS EMPTY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('START SHOPPING'),
                  )
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final product = item['products'];
                      final quantityData = item['quantities'];
                      final imageUrl = ProductImageService.getPublicUrl(product['product_pic1']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported, color: Colors.black26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['product_name'].toString().toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Size: ${quantityData['size'].toString().toUpperCase()}  |  Qty: ${item['quantity']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('RM${product['product_price']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeItem(item['cart_id']),
                            )
                          ],
                        ),
                      );
                    },
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
                          const Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          Text('RM${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  cartItems: _cartItems,
                                  subtotal: subtotal,
                                ),
                              ),
                            );
                          },
                          child: const Text('PROCEED TO CHECKOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}