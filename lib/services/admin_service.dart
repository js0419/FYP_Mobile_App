import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isCurrentUserAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final row = await _supabase
        .from('users')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    return row != null && row['role'] == 'admin';
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final users = await _supabase.from('users').select('user_id');
    final products = await _supabase.from('products').select('product_id');
    final orders = await _supabase.from('orders').select('order_id');
    final payments = await _supabase
        .from('payments')
        .select('total_amount, payment_status');

    double revenue = 0;
    for (final row in payments) {
      if (row['payment_status'] == 'paid') {
        revenue += (row['total_amount'] ?? 0).toDouble();
      }
    }

    return {
      'users': users.length,
      'products': products.length,
      'orders': orders.length,
      'revenue': revenue,
    };
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _supabase
        .from('users')
        .select(
          'user_id, user_name, user_email, user_phone, status, role, created_at',
        )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateUser({
    required String userId,
    String? role,
    String? status,
  }) async {
    final data = <String, dynamic>{};

    if (role != null) data['role'] = role;
    if (status != null) data['status'] = status;

    await _supabase.from('users').update(data).eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _supabase
        .from('categories')
        .select('category_id, category_name')
        .order('category_name');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await _supabase
        .from('products')
        .select(
          'product_id, category_id, product_name, product_description, '
          'product_gender, product_type, fit_type, color, material, '
          'product_price, product_status, product_pic1, product_pic2, '
          'product_pic3, product_pic4, '
          'categories(category_name), '
          'quantities(quantity_id, size, product_stock)',
        )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addProduct({
    required String categoryId,
    required String name,
    required String description,
    required String gender,
    required String type,
    required String fitType,
    required String color,
    required String material,
    required double price,
    required String status,
    String? pic1,
    String? pic2,
    String? pic3,
    String? pic4,
    required Map<String, int> stocks,
  }) async {
    final inserted = await _supabase
        .from('products')
        .insert({
          'category_id': categoryId,
          'product_name': name,
          'product_description': description,
          'product_gender': gender,
          'product_type': type,
          'fit_type': fitType,
          'color': color,
          'material': material,
          'product_price': price,
          'product_status': status,
          'product_pic1': pic1,
          'product_pic2': pic2,
          'product_pic3': pic3,
          'product_pic4': pic4,
        })
        .select('product_id')
        .single();

    final productId = inserted['product_id'];

    for (final entry in stocks.entries) {
      await _supabase.from('quantities').upsert({
        'product_id': productId,
        'size': entry.key,
        'product_stock': entry.value,
        'product_sold': 0,
      }, onConflict: 'product_id,size');
    }
  }

  Future<void> updateProduct({
    required String productId,
    required String categoryId,
    required String name,
    required String description,
    required String gender,
    required String type,
    required String fitType,
    required String color,
    required String material,
    required double price,
    required String status,
    String? pic1,
    String? pic2,
    String? pic3,
    String? pic4,
    required Map<String, int> stocks,
  }) async {
    await _supabase
        .from('products')
        .update({
          'category_id': categoryId,
          'product_name': name,
          'product_description': description,
          'product_gender': gender,
          'product_type': type,
          'fit_type': fitType,
          'color': color,
          'material': material,
          'product_price': price,
          'product_status': status,
          'product_pic1': pic1,
          'product_pic2': pic2,
          'product_pic3': pic3,
          'product_pic4': pic4,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('product_id', productId);

    for (final entry in stocks.entries) {
      await _supabase.from('quantities').upsert({
        'product_id': productId,
        'size': entry.key,
        'product_stock': entry.value,
      }, onConflict: 'product_id,size');
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('product_id', productId);
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await _supabase
        .from('orders')
        .select(
          'order_id, order_date, order_subtotal, orders_status, '
          'users(user_name, user_email), '
          'deliveries(delivery_status), '
          'payments(total_amount, payment_method, payment_status)',
        )
        .order('order_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _supabase
        .from('orders')
        .update({'orders_status': status})
        .eq('order_id', orderId);
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    final response = await _supabase
        .from('payments')
        .select(
          'payment_id, total_amount, payment_method, payment_status, payment_date, '
          'tax, discount, receipt_email, provider_reference, '
          'users(user_name, user_email), '
          'orders(order_id)',
        )
        .order('payment_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> uploadProductImage({
    required Uint8List imageBytes,
    required String originalFileName,
  }) async {
    final fileName = originalFileName.replaceAll(' ', '_');

    await _supabase.storage
        .from('product_images')
        .uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return fileName;
  }

  Future<void> deleteProductImage(String? fileName) async {
    final name = (fileName ?? '').trim();
    if (name.isEmpty) return;

    await _supabase.storage.from('product_images').remove([name]);
  }
}
