import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_app_bar.dart';
import 'product_details.dart';
import '../../services/product_image_service.dart';

class ProductsPage extends StatefulWidget {
  final String? gender; // Optional gender parameter

  const ProductsPage({super.key, this.gender});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() {
  _productsFuture = () async {
    try {
      var query = Supabase.instance.client
          .from('products')
          .select('*')
          .eq('product_status', 'active');

      if (widget.gender != null) {
        query = query.eq('product_gender', widget.gender!);
      }

      final data = await query;
      debugPrint('Products fetched: ${data.length}');
      return List<Map<String, dynamic>>.from(data);
    } catch (e, st) {
      debugPrint('Products fetch error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }();
}

  @override
  Widget build(BuildContext context) {
    // Determine the page title based on the filter
    String pageTitle = 'ALL COLLECTION';
    if (widget.gender == 'women') pageTitle = 'WOMEN COLLECTION';
    if (widget.gender == 'men') pageTitle = 'MEN COLLECTION';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              pageTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final products = snapshot.data;
                if (products == null || products.isEmpty) {
                  return Center(
                    child: Text(
                      'NO PRODUCTS FOUND FOR $pageTitle',
                      style: const TextStyle(letterSpacing: 2.0, color: Colors.black54),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 32,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final priceStr = product['product_price']?.toString() ?? '0.00';
                    final imageUrl = ProductImageService.getPublicUrl(product['product_pic1']);
                    final productName = (product['product_name'] ?? 'Unknown').toString().toUpperCase();

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(product: product),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: const Color(0xFFF5F5F5),
                              child: imageUrl != null && imageUrl.toString().isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.broken_image, color: Colors.grey),
                                    )
                                  : const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            productName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM $priceStr',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}