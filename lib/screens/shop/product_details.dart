import 'package:flutter/material.dart';

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['product_pic1'];
    final productName = (product['product_name'] ?? 'Unknown').toString().toUpperCase();
    final priceStr = product['product_price']?.toString() ?? '0.00';
    final description = product['product_description'] ?? 'No description available for this item.';
    final material = product['material'] ?? 'Unknown Material';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Add to wishlist logic
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Share logic
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // Let the image slide up behind the app bar
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Hero
            Container(
              width: double.infinity,
              height: 600, // Very tall for ZARA vibe
              color: const Color(0xFFF5F5F5),
              child: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    )
                  : const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            ),
            
            // Product Details Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RM $priceStr',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Description
                  const Text(
                    'MATERIALS & CARE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Material: $material',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6, // Taller line height for easy reading
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Floating Bottom Add to Cart Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Pure black button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0), // Sharp edges
                ),
                elevation: 0,
              ),
              onPressed: () {
                // TODO: Insert into cart table logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ADDED TO CART', style: TextStyle(letterSpacing: 1.0)),
                    backgroundColor: Colors.black,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'ADD TO CART',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}