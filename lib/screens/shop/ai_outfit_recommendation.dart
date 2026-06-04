import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/ai_recommendation_service.dart';
import '../../services/product_image_service.dart';
import '../../services/profile_service.dart';
import 'product_details.dart';

class AiOutfitRecommendationPage extends StatefulWidget {
  const AiOutfitRecommendationPage({super.key});

  @override
  State<AiOutfitRecommendationPage> createState() =>
      _AiOutfitRecommendationPageState();
}

class _AiOutfitRecommendationPageState
    extends State<AiOutfitRecommendationPage> {
  final _aiService = AiRecommendationService();
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();

  bool _isProfileLoading = true;
  bool _isLoading = false;
  bool _isPickingImage = false;

  String? _preferredStyleName;
  String _gender = 'unisex';

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  Map<String, dynamic>? _bodyAnalysis;
  List<Map<String, dynamic>> _outfits = [];
  String _errorMessage = '';

  final Map<String, Future<Map<String, dynamic>?>> _productFutureCache = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isProfileLoading = true;
      _errorMessage = '';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Please login first.');
      }

      final profile = await _profileService.getUserProfile(user.id);
      final styles = await _profileService.getStyles();

      if (profile == null) {
        throw Exception('Profile not found.');
      }

      final preferredStyleId = profile['preferred_style_id'];
      final userGender = (profile['user_gender'] ?? '')
          .toString()
          .toLowerCase();

      String? resolvedStyleName;
      if (preferredStyleId != null) {
        for (final style in styles) {
          if (style['style_id'] == preferredStyleId) {
            resolvedStyleName = style['style_name']?.toString();
            break;
          }
        }
      }

      String resolvedGender = 'unisex';
      if (userGender == 'male') {
        resolvedGender = 'men';
      } else if (userGender == 'female') {
        resolvedGender = 'women';
      }

      setState(() {
        _preferredStyleName = resolvedStyleName;
        _gender = resolvedGender;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isPickingImage = true;
      _errorMessage = '';
    });

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
        _bodyAnalysis = null;
        _outfits = [];
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _generateOutfits() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please upload a body image first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _bodyAnalysis = null;
      _outfits = [];
      _productFutureCache.clear();
    });

    try {
      final result = await _aiService.getRecommendedOutfits(
        userId: Supabase.instance.client.auth.currentUser?.id,
        imageFile: _selectedImage!,
        preferredStyle: _preferredStyleName,
        gender: _gender,
      );

      setState(() {
        _bodyAnalysis = result['body_analysis'] == null
            ? null
            : Map<String, dynamic>.from(result['body_analysis']);
        _outfits = List<Map<String, dynamic>>.from(result['outfits'] ?? []);
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to get outfit recommendations: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchFullProductById(String productId) async {
    try {
      final fullProduct = await Supabase.instance.client
          .from('products')
          .select('*')
          .eq('product_id', productId)
          .single();

      return Map<String, dynamic>.from(fullProduct);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getProductFuture(String productId) {
    return _productFutureCache.putIfAbsent(
      productId,
      () => _fetchFullProductById(productId),
    );
  }

  Future<void> _openProduct(dynamic item) async {
    if (item == null) return;

    try {
      final product = Map<String, dynamic>.from(item);
      final productId = product['product_id']?.toString();

      if (productId == null || productId.isEmpty) {
        throw Exception('Invalid product ID');
      }

      final fullProduct = await _getProductFuture(productId);

      if (fullProduct == null) {
        throw Exception('Product not found');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsPage(product: fullProduct),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open product: $e')));
    }
  }

  Widget _buildInfoBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _selectedImageBytes == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 48, color: Colors.black38),
                SizedBox(height: 10),
                Text(
                  'Upload a full-body image',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
            ),
    );
  }

  Widget _buildBodyAnalysisCard() {
    if (_bodyAnalysis == null) return const SizedBox.shrink();

    final bodyShape = (_bodyAnalysis!['body_shape'] ?? 'unknown').toString();
    final confidence =
        ((_bodyAnalysis!['confidence'] as num?)?.toDouble() ?? 0.0) * 100;
    final summary = (_bodyAnalysis!['style_summary'] ?? '').toString();

    final recommendedFocus = List<String>.from(
      _bodyAnalysis!['recommended_focus'] ?? [],
    );
    final avoid = List<String>.from(_bodyAnalysis!['avoid'] ?? []);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI BODY ANALYSIS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Detected body shape: ${bodyShape.toUpperCase()}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence: ${confidence.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(summary, style: const TextStyle(fontSize: 12)),
          ],
          if (recommendedFocus.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Recommended focus: ${recommendedFocus.join(', ')}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          if (avoid.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Avoid / be careful with: ${avoid.join(', ')}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageBox(String imageUrl) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          : const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildProductCard(String label, dynamic item) {
    if (item == null) return const SizedBox.shrink();

    final product = Map<String, dynamic>.from(item);
    final productId = product['product_id']?.toString();

    if (productId == null || productId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getProductFuture(productId),
      builder: (context, snapshot) {
        final fullProduct = snapshot.data;
        final imageUrl = fullProduct == null
            ? ''
            : ProductImageService.getPrimaryImageUrl(fullProduct);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openProduct(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (snapshot.connectionState == ConnectionState.waiting)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    )
                  else
                    _buildImageBox(imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${label.toUpperCase()}: ${product['product_name']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'RM ${product['product_price']} | Sizes: ${product['recommended_size']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Score ${(product['score'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit, int index) {
    final items = Map<String, dynamic>.from(outfit['outfit_items'] ?? {});
    final score = (outfit['score'] as num?)?.toDouble() ?? 0.0;
    final outfitType = outfit['outfit_type']?.toString() ?? 'outfit_set';
    final reason = (outfit['reason'] ?? '').toString();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OUTFIT SET ${index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$outfitType | Match Score: ${score.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.black54),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 12),
            _buildProductCard('Top', items['top']),
            _buildProductCard('Bottom', items['bottom']),
            _buildProductCard('Outerwear', items['outerwear']),
            _buildProductCard('Dress', items['dress']),
            _buildProductCard('Accessory', items['accessory']),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProfileLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI OUTFIT RECOMMENDATION'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,

      // FIX: Make the whole page scroll
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            Row(
              children: [
                _buildInfoBox('STYLE', _preferredStyleName ?? 'ANY'),
                const SizedBox(width: 12),
                _buildInfoBox('GENDER', _gender.toUpperCase()),
              ],
            ),

            const SizedBox(height: 16),

            _buildImagePreview(),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isPickingImage ? null : _pickImage,
                    child: _isPickingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _selectedImage == null
                                ? 'UPLOAD BODY IMAGE'
                                : 'CHANGE IMAGE',
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateOutfits,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('GENERATE OUTFITS'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_bodyAnalysis == null && _outfits.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text(
                    'Upload a full-body image and generate outfit recommendations.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              _buildBodyAnalysisCard(),

              ...List.generate(
                _outfits.length,
                (index) => _buildOutfitCard(_outfits[index], index),
              ),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
