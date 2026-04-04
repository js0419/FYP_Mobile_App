import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_footer.dart';
import '../../widgets/custom_drawer.dart';
import 'product_details.dart';
import 'product.dart';
import '../../services/product_image_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _hotSalesFuture;

  @override
  void initState() {
    super.initState();
    _fetchHotSales();
  }

  void _fetchHotSales() {
    _hotSalesFuture = () async {
      try {
        final data = await Supabase.instance.client
            .from('products')
            .select('*')
            .eq('product_status', 'active')
            .limit(4);

        return List<Map<String, dynamic>>.from(data);
      } catch (e, st) {
        debugPrint('Hot sales fetch error: $e');
        debugPrintStack(stackTrace: st);
        rethrow;
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductsPage()),
                );
              },
              child: _buildFashionBanner(screenWidth),
            ),
            SizedBox(height: screenWidth > 600 ? 50 : 30),
            Text(
              'TRENDING NOW',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 16 : 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenWidth > 600 ? 24 : 16),
            _buildHotSalesGrid(screenWidth),
            SizedBox(height: screenWidth > 600 ? 60 : 40),
            const CustomFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFashionBanner(double screenWidth) {
    // Responsive banner height
    final bannerHeight = screenWidth > 600 ? 500.0 : 300.0;

    return Container(
      width: double.infinity,
      height: bannerHeight,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Text(
          'NEW COLLECTION',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth > 600 ? 28 : 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 5.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHotSalesGrid(double screenWidth) {
    // Responsive crossAxisCount
    final crossAxisCount = screenWidth > 600 ? 2 : 1;
    final childAspectRatio = screenWidth > 600 ? 0.55 : 0.65;
    final horizontalPadding = screenWidth > 600 ? 16.0 : 12.0;
    final crossAxisSpacing = screenWidth > 600 ? 16.0 : 12.0;
    final mainAxisSpacing = screenWidth > 600 ? 32.0 : 24.0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _hotSalesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.black),
            ),
          );
        }

        final products = snapshot.data;
        if (products == null || products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'NO PRODUCTS AVAILABLE',
                style: TextStyle(color: Colors.black54, letterSpacing: 2.0),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final priceStr = product['product_price']?.toString() ?? '0.00';
              final imageUrl = ProductImageService.getPrimaryImageUrl(product);
              final productName = (product['product_name'] ?? 'Unknown')
                  .toString()
                  .toUpperCase();

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailsPage(product: product),
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
                        child: _buildProductImage(imageUrl),
                      ),
                    ),
                    SizedBox(height: screenWidth > 600 ? 12 : 8),
                    Text(
                      productName,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                        fontSize: screenWidth > 600 ? 12 : 11,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth > 600 ? 4 : 2),
                    Text(
                      'RM $priceStr',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w300,
                        fontSize: screenWidth > 600 ? 12 : 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 40,
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
      },
    );
  }
}