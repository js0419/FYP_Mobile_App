import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
    // Fetch 4 active products to display in the Hot Sales section
    _hotSalesFuture = Supabase.instance.client
        .from('products')
        .select('product_id, product_name, product_price, product_pic1')
        .eq('product_status', 'active')
        .limit(4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center align for high-fashion feel
          children: [
            // 1. Fashion Hero Banner
            _buildFashionBanner(),

            const SizedBox(height: 50),

            // 2. Minimalist Section Title
            const Text(
              'TRENDING NOW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0, // Wide spacing for luxury look
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // 3. Hot Sales Grid (Fetched from Supabase)
            _buildHotSalesGrid(),

            const SizedBox(height: 60),

            // 4. Reusable Footer
            const CustomFooter(),
          ],
        ),
      ),
    );
  }

  // --- UI Builder Methods ---

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Text(
              'COLLECTIONS',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 20, 
                letterSpacing: 2.0,
              ),
            ),
          ),
          ListTile(
            title: const Text('WOMEN', style: TextStyle(letterSpacing: 1.5, fontSize: 14)),
            onTap: () {},
          ),
          ListTile(
            title: const Text('MEN', style: TextStyle(letterSpacing: 1.5, fontSize: 14)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFashionBanner() {
    return Container(
      width: double.infinity,
      height: 500, // Taller image for editorial look
      decoration: const BoxDecoration(
        image: DecorationImage(
          // Black and white or high-contrast fashion image
          image: NetworkImage(
              'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.15), // Very subtle dark overlay
        alignment: Alignment.center,
        child: const Text(
          'NEW COLLECTION',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: 5.0, // ZARA-style wide spacing
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
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)));
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
              childAspectRatio: 0.55, // Very tall ratio for model photography
              crossAxisSpacing: 16,
              mainAxisSpacing: 32, // More breathing room between rows
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final priceStr = product['product_price']?.toString() ?? '0.00';
              final imageUrl = product['product_pic1'];
              final productName = (product['product_name'] ?? 'Unknown').toString().toUpperCase();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image (Sharp corners, no shadow)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF5F5F5), // Light grey placeholder
                      child: imageUrl != null && imageUrl.toString().isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            )
                          : const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Product Details (Minimalist typography)
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
              );
            },
          ),
        );
      },
    );
  }
}