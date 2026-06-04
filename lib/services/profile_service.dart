import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _profilePicsBucket = 'profile_pictures';

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

  Future<String> uploadProfilePicture({
    required String userId,
    required Uint8List imageBytes,
    String? fileName,
  }) async {
    try {
      final extension = _normalizeImageExtension(fileName);
      final filePath = '$userId/profile$extension';

      await _removeAllKnownProfilePicturePaths(userId);

      await _supabase.storage.from(_profilePicsBucket).uploadBinary(
        filePath,
        imageBytes,
        fileOptions: FileOptions(
          cacheControl: '0',
          upsert: true,
          contentType: _contentTypeFromExtension(extension),
        ),
      );

      final publicUrl =
      _supabase.storage.from(_profilePicsBucket).getPublicUrl(filePath);

      return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? gender,
    String? profilePicUrl,
    String? preferredStyleId,
  }) async {
    try {
      final fullName =
      '${firstName.trim()} ${lastName.trim()}'.trim();

      final updateData = <String, dynamic>{
        'user_name': fullName,
        'user_phone': phoneNumber.trim(),
        'updated_at': DateTime.now().toIso8601String(),
        'user_profile_pic':
        (profilePicUrl != null && profilePicUrl.trim().isNotEmpty)
            ? profilePicUrl.trim()
            : null,
        'user_gender':
        (gender != null && gender.trim().isNotEmpty) ? gender.trim() : null,
        'preferred_style_id':
        (preferredStyleId != null && preferredStyleId.trim().isNotEmpty)
            ? preferredStyleId.trim()
            : null,
      };

      await _supabase.from('users').update(updateData).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStyles() async {
    try {
      final response =
      await _supabase.from('styles').select().order('style_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch styles: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAiRecommendations() async {
    try {
      final response = await _supabase.rpc('recommend_outfit_set');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get AI recommendations: $e');
    }
  }

  Future<void> deleteProfilePicture(String userId) async {
    try {
      await _removeAllKnownProfilePicturePaths(userId);

      await _supabase.from('users').update({
        'user_profile_pic': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete profile picture: $e');
    }
  }

  String getProfilePictureUrl(String? picturePath, String userId) {
    if (picturePath == null || picturePath.trim().isEmpty) {
      return '';
    }

    final cleanPath = picturePath.trim();

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    final normalizedPath = cleanPath.startsWith('/')
        ? cleanPath.substring(1)
        : cleanPath;

    final publicUrl =
    _supabase.storage.from(_profilePicsBucket).getPublicUrl(normalizedPath);

    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  String _normalizeImageExtension(String? fileName) {
    if (fileName == null || !fileName.contains('.')) {
      return '.jpg';
    }

    final ext = '.${fileName.split('.').last.toLowerCase()}';

    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
        return ext;
      default:
        return '.jpg';
    }
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _removeAllKnownProfilePicturePaths(String userId) async {
    final paths = <String>[
      '$userId/profile.jpg',
      '$userId/profile.jpeg',
      '$userId/profile.png',
      '$userId/profile.webp',
      'profile_pictures/$userId/profile_$userId.jpg',
      'profile_pictures/$userId/profile_$userId.jpeg',
      'profile_pictures/$userId/profile_$userId.png',
      'profile_pictures/$userId/profile_$userId.webp',
    ];

    try {
      await _supabase.storage.from(_profilePicsBucket).remove(paths);
    } catch (_) {
    }
  }

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