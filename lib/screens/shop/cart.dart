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

  static const Map<String, int> _sizeSortOrder = {
    'xs': 0,
    's': 1,
    'm': 2,
    'l': 3,
    'xl': 4,
    'xxl': 5,
    'free_size': 6,
  };

  List<Map<String, dynamic>> _cartItems = [];
  final Set<String> _busyCartIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadCartItems({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    }

    try {
      final items = await _shopService.getCartItems();
      if (!mounted) return;

      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load cart: $e')));
    }
  }

  Future<void> _removeItem(String cartId) async {
    try {
      await _shopService.removeFromCart(cartId);
      await _loadCartItems(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove item: $e')));
    }
  }

  Future<void> _changeQuantity(Map<String, dynamic> item, int nextQty) async {
    final cartId = item['cart_id'].toString();

    setState(() => _busyCartIds.add(cartId));
    try {
      await _shopService.updateCartItem(
        cartId: cartId,
        productId: item['product_id'].toString(),
        newQuantityId: _toInt(item['quantity_id']),
        newQuantity: nextQty,
      );
      await _loadCartItems(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update quantity: $e')));
    } finally {
      if (mounted) {
        setState(() => _busyCartIds.remove(cartId));
      }
    }
  }

  Future<void> _showSizePicker(Map<String, dynamic> item) async {
    final productId = item['product_id'].toString();
    final cartId = item['cart_id'].toString();

    try {
      final rawSizes = await _shopService.getAvailableSizesForProduct(productId);

      rawSizes.sort((a, b) {
        final left = _sizeSortOrder[(a['size'] ?? '').toString().toLowerCase()] ?? 999;
        final right = _sizeSortOrder[(b['size'] ?? '').toString().toLowerCase()] ?? 999;
        return left.compareTo(right);
      });

      if (!mounted) return;

      final picked = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: Colors.white,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT SIZE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...rawSizes.map((sizeRow) {
                    final isCurrent =
                        _toInt(sizeRow['quantity_id']) == _toInt(item['quantity_id']);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text((sizeRow['size'] ?? '').toString().toUpperCase()),
                      subtitle: Text('${_toInt(sizeRow['product_stock'])} available'),
                      trailing: isCurrent
                          ? const Icon(Icons.check, color: Colors.black)
                          : null,
                      onTap: () => Navigator.pop(context, sizeRow),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );

      if (picked == null) return;

      setState(() => _busyCartIds.add(cartId));
      final pickedStock = _toInt(picked['product_stock']);
      final currentQty = _toInt(item['quantity']);
      final safeQty = currentQty > pickedStock ? pickedStock : currentQty;

      await _shopService.updateCartItem(
        cartId: cartId,
        productId: productId,
        newQuantityId: _toInt(picked['quantity_id']),
        newQuantity: safeQty,
      );

      await _loadCartItems(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to change size: $e')));
    } finally {
      if (mounted) {
        setState(() => _busyCartIds.remove(cartId));
      }
    }
  }

  double _calculateSubtotal() {
    double total = 0;
    for (final item in _cartItems) {
      final product = Map<String, dynamic>.from(item['products'] ?? {});
      final price = (product['product_price'] ?? 0) as num;
      final qty = (item['quantity'] ?? 0) as num;
      total += price * qty;
    }
    return total;
  }

  Widget _buildQuantityControl(Map<String, dynamic> item) {
    final cartId = item['cart_id'].toString();
    final busy = _busyCartIds.contains(cartId);

    final quantityData = Map<String, dynamic>.from(item['quantities'] ?? {});
    final currentQty = _toInt(item['quantity']);
    final maxStock = _toInt(quantityData['product_stock']);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: busy
          ? const SizedBox(
              width: 108,
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  splashRadius: 18,
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: currentQty <= 1
                      ? null
                      : () => _changeQuantity(item, currentQty - 1),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$currentQty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  splashRadius: 18,
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: currentQty >= maxStock
                      ? null
                      : () => _changeQuantity(item, currentQty + 1),
                ),
              ],
            ),
    );
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
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'YOUR CART IS EMPTY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('START SHOPPING'),
                  ),
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
                      final product = Map<String, dynamic>.from(item['products'] ?? {});
                      final quantityData = Map<String, dynamic>.from(item['quantities'] ?? {});
                      final imageUrl = ProductImageService.getPublicUrl(
                        product['product_pic1'],
                      );
                      final cartId = item['cart_id'].toString();
                      final isBusy = _busyCartIds.contains(cartId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.black26,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (product['product_name'] ?? '')
                                        .toString()
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'RM${product['product_price']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      OutlinedButton(
                                        onPressed: isBusy
                                            ? null
                                            : () => _showSizePicker(item),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          side: const BorderSide(
                                            color: Colors.black12,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: Text(
                                          'SIZE: ${(quantityData['size'] ?? '').toString().toUpperCase()}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      _buildQuantityControl(item),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: isBusy
                                  ? null
                                  : () => _removeItem(cartId),
                            ),
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
                          const Text(
                            'SUBTOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'RM${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                          child: const Text(
                            'PROCEED TO CHECKOUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
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