import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Update user profile - Now includes gender and profile picture
  Future<void> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? gender,
    String? profilePic,
  }) async {
    try {
      final updateData = {
        'user_name': '$firstName $lastName',
        'user_phone': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields if provided
      if (gender != null && gender.isNotEmpty) {
        updateData['user_gender'] = gender;
      }
      if (profilePic != null && profilePic.isNotEmpty) {
        updateData['user_profile_pic'] = profilePic;
      }

      await _supabase.from('users').update(updateData).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Get user addresses
  Future<List<Map<String, dynamic>>> getUserAddresses(String userId) async {
    try {
      final response = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  // Add new address
  Future<void> addAddress({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required String street,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required bool isDefault,
  }) async {
    try {
      if (isDefault) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      await _supabase.from('addresses').insert({
        'user_id': userId,
        'recipient_name': fullName,
        'phone': phoneNumber,
        'address_line1': street,
        'city': city,
        'state': state,
        'post_code': postalCode,
        'country': country,
        'is_default': isDefault,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  // Update address
  Future<void> updateAddress({
    required String addressId,
    required String userId,
    required String fullName,
    required String phoneNumber,
    required String street,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required bool isDefault,
  }) async {
    try {
      if (isDefault) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      await _supabase.from('addresses').update({
        'recipient_name': fullName,
        'phone': phoneNumber,
        'address_line1': street,
        'city': city,
        'state': state,
        'post_code': postalCode,
        'country': country,
        'is_default': isDefault,
      }).eq('address_id', addressId);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  // Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      await _supabase.from('addresses').delete().eq('address_id', addressId);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Get order history
  Future<List<Map<String, dynamic>>> getOrderHistory(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select(
              'order_id, order_date, order_subtotal, orders_status, delivery_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch order history: $e');
    }
  }

  // Get order details
  Future<List<Map<String, dynamic>>> getOrderDetails(String orderId) async {
    try {
      final response = await _supabase
          .from('order_details')
          .select(
              'order_detail_id, quantity_id, quantity, unit_price, product_id, products(product_id, product_name, product_price), quantities(size)')
          .eq('order_id', orderId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }
}