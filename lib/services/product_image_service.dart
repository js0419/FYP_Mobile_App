import 'package:supabase_flutter/supabase_flutter.dart';

class ProductImageService {
  static const String bucketName = 'product_images';

  static String getPublicUrl(dynamic imagePath) {
    final path = (imagePath ?? '').toString().trim();

    if (path.isEmpty) return '';

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    return Supabase.instance.client.storage
        .from(bucketName)
        .getPublicUrl(path);
  }

  static List<String> getGalleryUrls(Map<String, dynamic> product) {
    final rawPaths = [
      product['product_pic1'],
      product['product_pic2'],
      product['product_pic3'],
      product['product_pic4'],
    ];

    return rawPaths
        .map(getPublicUrl)
        .where((url) => url.isNotEmpty)
        .toList();
  }
}