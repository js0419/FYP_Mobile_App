import 'package:supabase_flutter/supabase_flutter.dart';

class ProductImageService {
  static const String bucketName = 'product_images';

  static String _normalizePath(dynamic imagePath) {
    final raw = (imagePath ?? '').toString().trim();

    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    return raw
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');
  }

  static String getPublicUrl(dynamic imagePath) {
    final normalizedPath = _normalizePath(imagePath);

    if (normalizedPath.isEmpty) return '';
    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return normalizedPath;
    }

    return Supabase.instance.client.storage
        .from(bucketName)
        .getPublicUrl(normalizedPath);
  }

  static List<String> getGalleryUrls(Map<String, dynamic> product) {
    final rawPaths = [
      product['product_pic1'],
      product['product_pic2'],
      product['product_pic3'],
      product['product_pic4'],
    ];

    final urls = rawPaths
        .map(getPublicUrl)
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();

    return urls;
  }

  static String getPrimaryImageUrl(Map<String, dynamic> product) {
    final gallery = getGalleryUrls(product);
    return gallery.isNotEmpty ? gallery.first : '';
  }
}