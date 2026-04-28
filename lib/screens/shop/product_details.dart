import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/product_image_service.dart';
import '../../services/shop_service.dart';
import '../auth/login.dart';

class _SizeOption {
  final int quantityId;
  final String size;
  final int stock;

  _SizeOption({
    required this.quantityId,
    required this.size,
    required this.stock,
  });
}

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final _shopService = ShopService();

  static const Map<String, int> _sizeSortOrder = {
    'xs': 0,
    's': 1,
    'm': 2,
    'l': 3,
    'xl': 4,
    'xxl': 5,
    'free_size': 6,
  };

  late final List<String> _galleryUrls;
  int _selectedImageIndex = 0;
  bool _isLoadingSizes = true;
  bool _isAddingToCart = false;
  bool _isWishlistLoading = false;
  bool _isInWishlist = false;

  List<_SizeOption> _sizeOptions = [];
  _SizeOption? _selectedSize;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _galleryUrls = ProductImageService.getGalleryUrls(widget.product);
    _loadSizes();
    _loadWishlistStatus();
  }

  Future<void> _loadSizes() async {
    try {
      final productId = widget.product['product_id'];
      if (productId == null) {
        setState(() {
          _sizeOptions = [];
          _isLoadingSizes = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('quantities')
          .select('quantity_id, size, product_stock')
          .eq('product_id', productId)
          .gt('product_stock', 0);

      final options = List<Map<String, dynamic>>.from(response)
          .map(
            (row) => _SizeOption(
          quantityId: row['quantity_id'] is int
              ? row['quantity_id'] as int
              : int.parse(row['quantity_id'].toString()),
          size: (row['size'] ?? '').toString(),
          stock: row['product_stock'] is int
              ? row['product_stock'] as int
              : int.parse(row['product_stock'].toString()),
        ),
      )
          .toList();

      options.sort((a, b) {
        final left = _sizeSortOrder[a.size.toLowerCase()] ?? 999;
        final right = _sizeSortOrder[b.size.toLowerCase()] ?? 999;
        return left.compareTo(right);
      });

      if (!mounted) return;
      setState(() {
        _sizeOptions = options;
        _isLoadingSizes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sizeOptions = [];
        _isLoadingSizes = false;
      });
    }
  }

  Future<void> _loadWishlistStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final exists = await _shopService.isInWishlist(
        widget.product['product_id'].toString(),
      );

      if (!mounted) return;
      setState(() {
        _isInWishlist = exists;
      });
    } catch (e) {
      // keep silent so page does not break
    }
  }

  void _selectImage(int index) => setState(() => _selectedImageIndex = index);

  void _selectSize(_SizeOption option) {
    setState(() {
      _selectedSize = option;
      if (_selectedQuantity > option.stock) _selectedQuantity = option.stock;
      if (_selectedQuantity < 1) _selectedQuantity = 1;
    });
  }

  void _increaseQuantity() {
    if (_selectedSize != null && _selectedQuantity < _selectedSize!.stock) {
      setState(() => _selectedQuantity += 1);
    }
  }

  void _decreaseQuantity() {
    if (_selectedQuantity > 1) {
      setState(() => _selectedQuantity -= 1);
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.black54),
              const SizedBox(height: 16),
              const Text(
                'LOGIN REQUIRED',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please log in to your account to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isWishlistLoading = true);

    try {
      final productId = widget.product['product_id'].toString();

      if (_isInWishlist) {
        await _shopService.removeFromWishlistByProductId(productId);
      } else {
        await _shopService.addToWishlist(productId);
      }

      if (!mounted) return;

      setState(() {
        _isInWishlist = !_isInWishlist;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isInWishlist ? 'Added to wishlist' : 'Removed from wishlist',
          ),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wishlist failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isWishlistLoading = false);
      }
    }
  }

  Future<void> _addToCart() async {
    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a size first'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      await _shopService.addToCart(
        widget.product['product_id'].toString(),
        _selectedSize!.quantityId,
        _selectedQuantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName =
    (widget.product['product_name'] ?? 'Unknown').toString().toUpperCase();
    final priceStr = widget.product['product_price']?.toString() ?? '0.00';
    final description =
        widget.product['product_description'] ?? 'No description available.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PRODUCT DETAILS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 400,
              color: const Color(0xFFF5F5F5),
              child: _galleryUrls.isNotEmpty
                  ? Image.network(
                _galleryUrls[_selectedImageIndex],
                fit: BoxFit.cover,
              )
                  : const Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.black26,
              ),
            ),
            if (_galleryUrls.length > 1)
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _galleryUrls.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedImageIndex;
                    return GestureDetector(
                      onTap: () => _selectImage(index),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(_galleryUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM $priceStr',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SELECT SIZE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (_selectedSize != null)
                        Text(
                          '${_selectedSize!.stock} available',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingSizes)
                    const CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    )
                  else if (_sizeOptions.isEmpty)
                    const Text(
                      'Out of Stock',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sizeOptions.map((option) {
                        final isSelected = _selectedSize == option;
                        return ChoiceChip(
                          label: Text(
                            option.size.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.black,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(
                              color: isSelected ? Colors.black : Colors.black26,
                            ),
                          ),
                          onSelected: (_) => _selectSize(option),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),
                  const Text(
                    'QUANTITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: _decreaseQuantity,
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$_selectedQuantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: _increaseQuantity,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isWishlistLoading ? null : _toggleWishlist,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isWishlistLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(
                    _isInWishlist
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _isInWishlist ? Colors.red : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: (_isAddingToCart || _sizeOptions.isEmpty)
                        ? null
                        : _addToCart,
                    child: _isAddingToCart
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}