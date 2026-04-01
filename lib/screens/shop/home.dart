import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_footer.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      drawer: _buildDrawer(context),
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
              child: _buildFashionBanner(),
            ),
            const SizedBox(height: 50),
            const Text(
              'TRENDING NOW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            _buildHotSalesGrid(),
            const SizedBox(height: 60),
            const CustomFooter(),
          ],
        ),
      ),
    );
  }

  Future<void> _openNamedRoute(
    BuildContext context,
    String routeName,
    String pageName,
  ) async {
    Navigator.pop(context);

    try {
      await Navigator.pushNamed(context, routeName);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$pageName route not found. Change the route name if your app uses a different one.',
          ),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'MENU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined, color: Colors.black),
            title: const Text('PRODUCT PAGE'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.black),
            title: const Text('ABOUT US PAGE'),
            onTap: () => _openNamedRoute(context, '/about', 'About Us'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.black),
            title: const Text('FAQ PAGE'),
            onTap: () => _openNamedRoute(context, '/faq', 'FAQ'),
          ),
          ListTile(
            leading: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.black,
            ),
            title: const Text('CART PAGE'),
            onTap: () => _openNamedRoute(context, '/cart', 'Cart'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.black),
            title: const Text('PROFILE PAGE'),
            onTap: () => _openNamedRoute(context, '/profile', 'Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildFashionBanner() {
    return Container(
      width: double.infinity,
      height: 500,
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
        child: const Text(
          'NEW COLLECTION',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: 5.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHotSalesGrid() {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
