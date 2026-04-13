import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ai_recommendation_service.dart';
import '../../services/profile_service.dart';
import '../../services/product_image_service.dart';
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

  bool _isProfileLoading = true;
  bool _isLoading = false;

  double? _height;
  double? _weight;
  String? _preferredStyleName;
  String _gender = 'unisex';

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

      final heightValue = profile['height_cm'];
      final weightValue = profile['weight_kg'];
      final preferredStyleId = profile['preferred_style_id'];
      final userGender = (profile['user_gender'] ?? '').toString().toLowerCase();

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
        _height = heightValue == null ? null : (heightValue as num).toDouble();
        _weight = weightValue == null ? null : (weightValue as num).toDouble();
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

  Future<void> _generateOutfits() async {
    if (_height == null || _weight == null || _preferredStyleName == null) {
      setState(() {
        _errorMessage =
            'Please complete your height, weight, and preferred style in Profile > Edit Profile first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _productFutureCache.clear();
    });

    try {
      final result = await _aiService.getRecommendedOutfits(
        userId: Supabase.instance.client.auth.currentUser?.id,
        height: _height!,
        weight: _weight!,
        preferredStyle: _preferredStyleName!,
        gender: _gender,
      );

      setState(() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open product: $e')),
      );
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
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                ),
              ),
            )
          : const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
            ),
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
                          'RM ${product['product_price']} | Size: ${product['recommended_size']}',
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
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                _buildInfoBox(
                  'HEIGHT',
                  _height == null ? '-' : '${_height!.toStringAsFixed(0)} cm',
                ),
                const SizedBox(width: 12),
                _buildInfoBox(
                  'WEIGHT',
                  _weight == null ? '-' : '${_weight!.toStringAsFixed(0)} kg',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoBox('STYLE', _preferredStyleName ?? '-'),
                const SizedBox(width: 12),
                _buildInfoBox('GENDER', _gender.toUpperCase()),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateOutfits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GENERATE OUTFIT SETS'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _outfits.isEmpty
                  ? const Center(
                      child: Text('No outfit recommendations yet'),
                    )
                  : ListView.builder(
                      itemCount: _outfits.length,
                      itemBuilder: (context, index) {
                        return _buildOutfitCard(_outfits[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}