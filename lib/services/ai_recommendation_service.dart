import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    required double height,
    required double weight,
    required String preferredStyle,
    required String gender,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend_outfits'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'height': height,
        'weight': weight,
        'preferred_style': preferredStyle,
        'gender': gender,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get outfit recommendations: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}