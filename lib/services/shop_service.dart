import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User _requireUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Please login first');
    }
    return user;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> addToCart(String productId, int quantityId, int quantity) async {
    final user = _requireUser();

    final quantityRow = await _supabase
        .from('quantities')
        .select('quantity_id, product_id, product_stock')
        .eq('quantity_id', quantityId)
        .single();

    final stock = _toInt(quantityRow['product_stock']);
    if (stock <= 0) {
      throw Exception('Selected size is out of stock');
    }

    final safeQty = min(max(quantity, 1), stock);

    final existing = await _supabase
        .from('cart')
        .select('cart_id, quantity')
        .eq('user_id', user.id)
        .eq('quantity_id', quantityId)
        .maybeSingle();

    if (existing != null) {
      final mergedQty = min(_toInt(existing['quantity']) + safeQty, stock);

      await _supabase
          .from('cart')
          .update({'quantity': mergedQty})
          .eq('cart_id', existing['cart_id'])
          .eq('user_id', user.id);
      return;
    }

    await _supabase.from('cart').insert({
      'user_id': user.id,
      'product_id': productId,
      'quantity_id': quantityId,
      'quantity': safeQty,
      'added_time': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('cart')
        .select(
          'cart_id, user_id, product_id, quantity_id, quantity, added_time, '
          'products(*), '
          'quantities(quantity_id, size, product_stock)',
        )
        .eq('user_id', user.id)
        .order('added_time', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> removeFromCart(String cartId) async {
    final user = _requireUser();

    await _supabase
        .from('cart')
        .delete()
        .eq('cart_id', cartId)
        .eq('user_id', user.id);
  }

  Future<void> updateCartItem({
    required String cartId,
    required String productId,
    required int newQuantityId,
    required int newQuantity,
  }) async {
    final user = _requireUser();

    if (newQuantity < 1) {
      await removeFromCart(cartId);
      return;
    }

    final targetQuantity = await _supabase
        .from('quantities')
        .select('quantity_id, product_id, product_stock')
        .eq('quantity_id', newQuantityId)
        .single();

    final targetStock = _toInt(targetQuantity['product_stock']);
    if (targetStock <= 0) {
      throw Exception('Selected size is out of stock');
    }

    final safeQty = min(newQuantity, targetStock);

    final existingOther = await _supabase
        .from('cart')
        .select('cart_id, quantity')
        .eq('user_id', user.id)
        .eq('quantity_id', newQuantityId)
        .neq('cart_id', cartId)
        .maybeSingle();

    if (existingOther != null) {
      final mergedQty = min(_toInt(existingOther['quantity']) + safeQty, targetStock);

      await _supabase
          .from('cart')
          .update({'quantity': mergedQty})
          .eq('cart_id', existingOther['cart_id'])
          .eq('user_id', user.id);

      await _supabase
          .from('cart')
          .delete()
          .eq('cart_id', cartId)
          .eq('user_id', user.id);

      return;
    }

    await _supabase
        .from('cart')
        .update({
          'product_id': productId,
          'quantity_id': newQuantityId,
          'quantity': safeQty,
        })
        .eq('cart_id', cartId)
        .eq('user_id', user.id);
  }

  Future<List<Map<String, dynamic>>> getAvailableSizesForProduct(
    String productId,
  ) async {
    final response = await _supabase
        .from('quantities')
        .select('quantity_id, size, product_stock')
        .eq('product_id', productId)
        .gt('product_stock', 0);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getWishlistItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('wishlists')
        .select('wishlist_id, user_id, product_id, added_time, products(*)')
        .eq('user_id', user.id)
        .order('added_time', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<bool> isInWishlist(String productId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final response = await _supabase
        .from('wishlists')
        .select('wishlist_id')
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();

    return response != null;
  }

  Future<void> addToWishlist(String productId) async {
    final user = _requireUser();

    await _supabase.from('wishlists').upsert(
      {
        'user_id': user.id,
        'product_id': productId,
        'added_time': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,product_id',
    );
  }

  Future<void> removeFromWishlistByProductId(String productId) async {
    final user = _requireUser();

    await _supabase
        .from('wishlists')
        .delete()
        .eq('user_id', user.id)
        .eq('product_id', productId);
  }

  Future<String> processCheckout({
    required String addressId,
    required List<Map<String, dynamic>> cartItems,
    required double subtotal,
    required double deliveryFee,
    required String paymentMethod,
    String? providerReference,
    String? receiptEmail,
    Map<String, dynamic>? paymentDetails,
  }) async {
    _requireUser();

    final payload = cartItems.map((item) {
      final product = Map<String, dynamic>.from(item['products'] ?? {});
      return {
        'product_id': item['product_id'],
        'quantity_id': item['quantity_id'],
        'quantity': item['quantity'],
        'unit_price': _toDouble(product['product_price']),
      };
    }).toList();

    final response = await _supabase.rpc(
      'process_checkout_payment',
      params: {
        'p_address_id': addressId,
        'p_cart_items': payload,
        'p_subtotal': subtotal,
        'p_delivery_fee': deliveryFee,
        'p_payment_method': paymentMethod,
        'p_provider_reference': providerReference,
        'p_receipt_email': receiptEmail,
        'p_payment_metadata': paymentDetails ?? {},
      },
    );

    return response.toString();
  }

  Future<void> sendReceiptEmail({
    required String email,
    required String orderId,
    required String paymentMethodLabel,
    required double subtotal,
    required double deliveryFee,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    if (email.trim().isEmpty) return;

    final simplifiedItems = items.map((item) {
      final product = Map<String, dynamic>.from(item['products'] ?? {});
      return {
        'name': (product['product_name'] ?? 'Item').toString(),
        'qty': _toInt(item['quantity']),
        'price': _toDouble(product['product_price']),
      };
    }).toList();

    final response = await _supabase.functions.invoke(
      'send-receipt-email',
      body: {
        'email': email,
        'orderId': orderId,
        'paymentMethod': paymentMethodLabel,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'items': simplifiedItems,
      },
    );

    if (response.status >= 400) {
      throw Exception(response.data?.toString() ?? 'Failed to send receipt email');
    }
  }
}