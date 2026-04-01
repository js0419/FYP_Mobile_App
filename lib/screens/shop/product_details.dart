// product_details.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/product_image_service.dart';
import '../auth/login.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
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

  List<_SizeOption> _sizeOptions = [];
  _SizeOption? _selectedSize;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _galleryUrls = ProductImageService.getGalleryUrls(widget.product);
    _loadSizes();
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load sizes: $e'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  void _selectImage(int index) {
    setState(() {
      _selectedImageIndex = index;
    });
  }

  void _selectSize(_SizeOption option) {
    setState(() {
      _selectedSize = option;
      if (_selectedQuantity > option.stock) {
        _selectedQuantity = option.stock;
      }
      if (_selectedQuantity < 1) {
        _selectedQuantity = 1;
      }
    });
  }

  void _increaseQuantity() {
    final selectedSize = _selectedSize;
    if (selectedSize == null) return;
    if (_selectedQuantity >= selectedSize.stock) return;

    setState(() {
      _selectedQuantity += 1;
    });
  }

  void _decreaseQuantity() {
    if (_selectedQuantity <= 1) return;

    setState(() {
      _selectedQuantity -= 1;
    });
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Colors.black54,
                ),
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
                  'Please log in to your account to add items to cart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'GO TO LOGIN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'CONTINUE BROWSING',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    final selectedSize = _selectedSize;
    final productId = widget.product['product_id'];

    // Check if user is logged in
    if (user == null) {
      _showLoginPrompt();
      return;
    }

    if (selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a size first.'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid product.'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final existingRows = await Supabase.instance.client
          .from('cart')
          .select('cart_id, quantity')
          .eq('user_id', user.id)
          .eq('quantity_id', selectedSize.quantityId)
          .limit(1);

      if (existingRows.isNotEmpty) {
        final existing = Map<String, dynamic>.from(existingRows.first);
        final currentQty = existing['quantity'] is int
            ? existing['quantity'] as int
            : int.parse(existing['quantity'].toString());

        final updatedQty = currentQty + _selectedQuantity;
        final safeQty =
            updatedQty > selectedSize.stock ? selectedSize.stock : updatedQty;

        await Supabase.instance.client
            .from('cart')
            .update({'quantity': safeQty})
            .eq('cart_id', existing['cart_id']);
      } else {
        await Supabase.instance.client.from('cart').insert({
          'user_id': user.id,
          'product_id': productId,
          'quantity_id': selectedSize.quantityId,
          'quantity': _selectedQuantity,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${_selectedQuantity} item(s) - ${selectedSize.displayName}',
          ),
          backgroundColor: Colors.black,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.black,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName =
        (widget.product['product_name'] ?? 'Unknown').toString().toUpperCase();
    final priceStr = widget.product['product_price']?.toString() ?? '0.00';
    final description = (widget.product['product_description'] ??
            'No description available for this item.')
        .toString();
    final material = (widget.product['material'] ?? 'Unknown Material').toString();
    final color = (widget.product['color'] ?? 'Not stated').toString();
    final fitType = (widget.product['fit_type'] ?? 'regular').toString();

    final selectedImageUrl =
        _galleryUrls.isNotEmpty ? _galleryUrls[_selectedImageIndex] : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'PRODUCT DETAILS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainImage(selectedImageUrl),
            _buildThumbnailStrip(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RM $priceStr',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Color: $color',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fit: ${fitType.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SELECT SIZE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeSection(),
                  const SizedBox(height: 24),
                  const Text(
                    'SELECT QUANTITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuantitySelector(),
                  if (_selectedSize != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedSize!.stock} item(s) available',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
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
                      height: 1.6,
                      color: Colors.black87,
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
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedSize == null)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Please select a size before adding to cart.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selected: ${_selectedSize!.displayName}  x  $_selectedQuantity',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  onPressed: (_isAddingToCart || _sizeOptions.isEmpty)
                      ? null
                      : _addToCart,
                  child: _isAddingToCart
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ADD TO CART',
                          style: TextStyle(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w500,
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

  Widget _buildMainImage(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 520,
      color: const Color(0xFFF5F5F5),
      child: imageUrl.isEmpty
          ? const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.grey,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 80,
                    color: Colors.grey,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildThumbnailStrip() {
    if (_galleryUrls.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _galleryUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedImageIndex;

          return GestureDetector(
            onTap: () => _selectImage(index),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.black12,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Image.network(
                _galleryUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.grey);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSizeSection() {
    if (_isLoadingSizes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: CircularProgressIndicator(
          color: Colors.black,
          strokeWidth: 2,
        ),
      );
    }

    if (_sizeOptions.isEmpty) {
      return const Text(
        'OUT OF STOCK',
        style: TextStyle(
          fontSize: 13,
          color: Colors.black54,
          letterSpacing: 1.0,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _sizeOptions.map((option) {
        final isSelected = _selectedSize?.quantityId == option.quantityId;

        return GestureDetector(
          onTap: () => _selectSize(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.black26,
              ),
            ),
            child: Text(
              option.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    final hasSelectedSize = _selectedSize != null;

    return Row(
      children: [
        _buildQtyButton(
          icon: Icons.remove,
          onTap: hasSelectedSize ? _decreaseQuantity : null,
        ),
        Container(
          width: 70,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
          ),
          child: Text(
            '$_selectedQuantity',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildQtyButton(
          icon: Icons.add,
          onTap: hasSelectedSize ? _increaseQuantity : null,
        ),
      ],
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          color: isEnabled ? Colors.white : const Color(0xFFF4F4F4),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}

class _SizeOption {
  final int quantityId;
  final String size;
  final int stock;

  const _SizeOption({
    required this.quantityId,
    required this.size,
    required this.stock,
  });

  String get displayName {
    if (size.toLowerCase() == 'free_size') {
      return 'FREE SIZE';
    }
    return size.toUpperCase();
  }
}