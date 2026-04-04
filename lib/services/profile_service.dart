import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _profilePicsBucket = 'profile_pictures';

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

  // Upload profile picture to storage and get public URL
  Future<String> uploadProfilePicture({
    required String userId,
    required Uint8List imageBytes, // Changed from File to Uint8List
  }) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final filePath = 'profile_pictures/$userId/$fileName';

      // Delete old picture if exists
      try {
        await _supabase.storage.from(_profilePicsBucket).remove([
          'profile_pictures/$userId/$fileName',
        ]);
      } catch (e) {
        print('No previous file to delete: $e');
      }

      // Upload new picture using uploadBinary (works on Web & Mobile)
      await _supabase.storage
          .from(_profilePicsBucket)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_profilePicsBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Update user profile with picture URL
  Future<void> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? gender,
    String? profilePicUrl,
    double? height,
    double? weight,
    String? preferredStyleId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'user_name': '$firstName $lastName',
        'user_phone': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (gender != null && gender.isNotEmpty) {
        updateData['user_gender'] = gender;
      }
      if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
        updateData['user_profile_pic'] = profilePicUrl;
      }
      if (height != null) updateData['height_cm'] = height;
      if (weight != null) updateData['weight_kg'] = weight;
      if (preferredStyleId != null) updateData['preferred_style_id'] = preferredStyleId;

      await _supabase.from('users').update(updateData).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Fetch all available styles for the dropdown
  Future<List<Map<String, dynamic>>> getStyles() async {
    try {
      final response = await _supabase
          .from('styles')
          .select()
          .order('style_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch styles: $e');
    }
  }

  // CALL THE AI RECOMMENDATION FUNCTION
  Future<List<Map<String, dynamic>>> getAiRecommendations() async {
    try {
      // This calls the recommend_outfit_set function in your Supabase DB
      final response = await _supabase.rpc('recommend_outfit_set');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get AI recommendations: $e');
    }
  }

  // Delete profile picture
  Future<void> deleteProfilePicture(String userId) async {
    try {
      await _supabase.storage.from(_profilePicsBucket).remove([
        'profile_pictures/$userId/profile_$userId.jpg',
      ]);
    } catch (e) {
      throw Exception('Failed to delete profile picture: $e');
    }
  }

  // Get profile picture URL
  String getProfilePictureUrl(String? picturePath, String userId) {
    if (picturePath == null || picturePath.isEmpty) {
      return '';
    }

    if (picturePath.startsWith('http://') ||
        picturePath.startsWith('https://')) {
      return picturePath;
    }

    return _supabase.storage
        .from(_profilePicsBucket)
        .getPublicUrl('profile_pictures/$userId/$picturePath');
  }

  // ... rest of the existing methods (addresses, orders, etc.)

  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

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

      await _supabase
          .from('addresses')
          .update({
            'recipient_name': fullName,
            'phone': phoneNumber,
            'address_line1': street,
            'city': city,
            'state': state,
            'post_code': postalCode,
            'country': country,
            'is_default': isDefault,
          })
          .eq('address_id', addressId);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _supabase.from('addresses').delete().eq('address_id', addressId);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrderHistory(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select(
            'order_id, order_date, order_subtotal, orders_status, delivery_id, created_at',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch order history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrderDetails(String orderId) async {
    try {
      final response = await _supabase
          .from('order_details')
          .select(
            'order_detail_id, quantity_id, quantity, unit_price, product_id, products(product_id, product_name, product_price), quantities(size)',
          )
          .eq('order_id', orderId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }
}
