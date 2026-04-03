import 'package:supabase_flutter/supabase_flutter.dart';

class ShopService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<void> addToCart(String productId, int quantityId, int quantity) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Please login to add to cart');

    // Check if item already in cart
    final existing = await _supabase
        .from('cart')
        .select()
        .eq('user_id', userId)
        .eq('quantity_id', quantityId)
        .maybeSingle();

    if (existing != null) {
      // Update quantity
      await _supabase.from('cart').update({
        'quantity': existing['quantity'] + quantity,
      }).eq('cart_id', existing['cart_id']);
    } else {
      // Insert new
      await _supabase.from('cart').insert({
        'user_id': userId,
        'product_id': productId,
        'quantity_id': quantityId,
        'quantity': quantity,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('cart')
        .select('cart_id, quantity, product_id, quantity_id, products(product_name, product_price, product_pic1), quantities(size, product_stock)')
        .eq('user_id', userId)
        .order('added_time', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> removeFromCart(String cartId) async {
    await _supabase.from('cart').delete().eq('cart_id', cartId);
  }

  // --- CHECKOUT & ORDER OPERATIONS ---

  Future<String> processCheckout({
    required String addressId,
    required List<Map<String, dynamic>> cartItems,
    required double subtotal,
    required double deliveryFee,
    required String paymentMethod,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final totalAmount = subtotal + deliveryFee;

    try {
      // 1. Create Delivery Record
      final delivery = await _supabase.from('deliveries').insert({
        'address_id': addressId,
        'delivery_fee': deliveryFee,
        'delivery_status': 'pending',
      }).select().single();
      final deliveryId = delivery['delivery_id'];

      // 2. Create Order
      final order = await _supabase.from('orders').insert({
        'user_id': userId,
        'delivery_id': deliveryId,
        'order_subtotal': subtotal,
        'orders_status': 'confirmed',
      }).select().single();
      final orderId = order['order_id'];

      // 3. Create Order Details & Deduct Stock
      for (var item in cartItems) {
        final productId = item['product_id'];
        final quantityId = item['quantity_id'];
        final quantity = item['quantity'];
        final unitPrice = item['products']['product_price'];

        await _supabase.from('order_details').insert({
          'order_id': orderId,
          'product_id': productId,
          'quantity_id': quantityId,
          'quantity': quantity,
          'unit_price': unitPrice,
        });

        // Deduct stock and increment sold count
        final stockData = await _supabase.from('quantities').select('product_stock, product_sold').eq('quantity_id', quantityId).single();
        await _supabase.from('quantities').update({
          'product_stock': stockData['product_stock'] - quantity,
          'product_sold': stockData['product_sold'] + quantity,
        }).eq('quantity_id', quantityId);
      }

      // 4. Record Payment
      await _supabase.from('payments').insert({
        'order_id': orderId,
        'user_id': userId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'payment_status': 'paid',
      });

      // 5. Clear Cart
      await _supabase.from('cart').delete().eq('user_id', userId);

      return orderId;
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }
}