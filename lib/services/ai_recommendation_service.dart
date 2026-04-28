import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AiRecommendationService {
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://localhost:8000';
    }
  }

  Future<Map<String, dynamic>> getRecommendedOutfits({
    required String? userId,
    required XFile imageFile,
    String? preferredStyle,
    String? gender,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/recommend_outfits'),
    );

    if (userId != null && userId.isNotEmpty) {
      request.fields['user_id'] = userId;
    }

    if (preferredStyle != null && preferredStyle.trim().isNotEmpty) {
      request.fields['preferred_style'] = preferredStyle.trim();
    }

    if (gender != null && gender.trim().isNotEmpty) {
      request.fields['gender'] = gender.trim();
    }

    final bytes = await imageFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get outfit recommendations: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}