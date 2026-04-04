import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_drawer.dart';
import 'product_details.dart';
import '../../services/product_image_service.dart';

class ProductsPage extends StatefulWidget {
  final String? gender;

  const ProductsPage({super.key, this.gender});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const List<String> _genderOptions = ['ALL', 'MEN', 'WOMEN', 'UNISEX'];

  static const List<String> _productTypeOptions = [
    'ALL',
    'shirt',
    'tshirt',
    'blouse',
    'pants',
    'jeans',
    'jacket',
    'hoodie',
    'dress',
    'skirt',
    'bag',
    'shoes',
    'accessory',
  ];

  static const List<String> _sortOptions = [
    'DEFAULT',
    'PRICE_LOW_HIGH',
    'PRICE_HIGH_LOW',
    'NAME_A_Z',
    'NAME_Z_A',
  ];

  late Future<List<Map<String, dynamic>>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedGender = 'ALL';
  String _selectedType = 'ALL';
  String _selectedSort = 'DEFAULT';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _selectedGender = (widget.gender ?? 'ALL').toUpperCase();
    _fetchProducts();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchProducts() {
    _productsFuture = () async {
      try {
        final data = await Supabase.instance.client
            .from('products')
            .select('*')
            .eq('product_status', 'active');

        return List<Map<String, dynamic>>.from(data);
      } catch (e, st) {
        debugPrint('Products fetch error: $e');
        debugPrintStack(stackTrace: st);
        rethrow;
      }
    }();
  }

  List<Map<String, dynamic>> _applySearchAndFilter(
    List<Map<String, dynamic>> products,
  ) {
    var filtered = List<Map<String, dynamic>>.from(products);

    if (_selectedGender != 'ALL') {
      filtered = filtered.where((product) {
        final gender = (product['product_gender'] ?? '')
            .toString()
            .toUpperCase();
        return gender == _selectedGender;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final searchText = [
          product['product_name'],
          product['product_description'],
          product['product_type'],
          product['product_gender'],
          product['color'],
          product['material'],
          product['fit_type'],
        ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

        return searchText.contains(_searchQuery);
      }).toList();
    }

    if (_selectedType != 'ALL') {
      filtered = filtered.where((product) {
        final type = (product['product_type'] ?? '').toString().toLowerCase();
        return type == _selectedType.toLowerCase();
      }).toList();
    }

    switch (_selectedSort) {
      case 'PRICE_LOW_HIGH':
        filtered.sort((a, b) {
          final aPrice = ((a['product_price'] ?? 0) as num).toDouble();
          final bPrice = ((b['product_price'] ?? 0) as num).toDouble();
          return aPrice.compareTo(bPrice);
        });
        break;

      case 'PRICE_HIGH_LOW':
        filtered.sort((a, b) {
          final aPrice = ((a['product_price'] ?? 0) as num).toDouble();
          final bPrice = ((b['product_price'] ?? 0) as num).toDouble();
          return bPrice.compareTo(aPrice);
        });
        break;

      case 'NAME_A_Z':
        filtered.sort((a, b) {
          final aName = (a['product_name'] ?? '').toString().toLowerCase();
          final bName = (b['product_name'] ?? '').toString().toLowerCase();
          return aName.compareTo(bName);
        });
        break;

      case 'NAME_Z_A':
        filtered.sort((a, b) {
          final aName = (a['product_name'] ?? '').toString().toLowerCase();
          final bName = (b['product_name'] ?? '').toString().toLowerCase();
          return bName.compareTo(aName);
        });
        break;

      case 'DEFAULT':
      default:
        break;
    }

    return filtered;
  }

  String _getPageTitle() {
    switch (_selectedGender) {
      case 'MEN':
        return 'MEN COLLECTION';
      case 'WOMEN':
        return 'WOMEN COLLECTION';
      case 'UNISEX':
        return 'UNISEX COLLECTION';
      default:
        return 'ALL COLLECTION';
    }
  }

  String _getSortLabel(String value) {
    switch (value) {
      case 'PRICE_LOW_HIGH':
        return 'Price: Low to High';
      case 'PRICE_HIGH_LOW':
        return 'Price: High to Low';
      case 'NAME_A_Z':
        return 'Name: A to Z';
      case 'NAME_Z_A':
        return 'Name: Z to A';
      case 'DEFAULT':
      default:
        return 'Default';
    }
  }

  String _getGenderLabel(String value) {
    switch (value) {
      case 'MEN':
        return 'Men';
      case 'WOMEN':
        return 'Women';
      case 'UNISEX':
        return 'Unisex';
      default:
        return 'All Gender';
    }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pageTitle = _getPageTitle();
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      drawer: _buildDrawer(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 12 : 16,
              isSmallScreen ? 16 : 24,
              isSmallScreen ? 12 : 16,
              isSmallScreen ? 8 : 12,
            ),
            child: Column(
              children: [
                Text(
                  pageTitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildSearchBar(isSmallScreen),
                SizedBox(height: isSmallScreen ? 12 : 20),
                // Filters - Collapsible on small screens
                if (isSmallScreen)
                  _buildMobileFilterToggle()
                else
                  _buildDesktopFilters(isSmallScreen),
                // Mobile filters expanded view
                if (isSmallScreen && _showFilters)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildMobileFiltersExpanded(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final products = snapshot.data ?? [];
                final filteredProducts = _applySearchAndFilter(products);

                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'NO PRODUCTS FOUND FOR $pageTitle',
                      style: const TextStyle(
                        letterSpacing: 2.0,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      'NO PRODUCTS MATCH YOUR SEARCH OR FILTER',
                      style: TextStyle(
                        letterSpacing: 1.5,
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return _buildProductGrid(
                  filteredProducts,
                  isSmallScreen,
                  screenWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterToggle() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _showFilters = !_showFilters;
          });
        },
        icon: Icon(
          _showFilters ? Icons.expand_less : Icons.expand_more,
          color: Colors.black,
        ),
        label: Text(
          _showFilters ? 'HIDE FILTERS' : 'SHOW FILTERS',
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.0,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFiltersExpanded() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildGenderDropdown(),
          const SizedBox(height: 12),
          _buildTypeDropdown(),
          const SizedBox(height: 12),
          _buildSortDropdown(),
          const SizedBox(height: 12),
          _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildDesktopFilters(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 70 : 78,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SizedBox(width: 150, child: _buildGenderDropdown()),
          const SizedBox(width: 12),
          SizedBox(width: 150, child: _buildTypeDropdown()),
          SizedBox(width: 170, child: _buildSortDropdown()),
          const SizedBox(width: 12),
          _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    List<Map<String, dynamic>> filteredProducts,
    bool isSmallScreen,
    double screenWidth,
  ) {
    final crossAxisCount = isSmallScreen ? 1 : 2;
    final childAspectRatio = isSmallScreen ? 0.7 : 0.52;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final crossAxisSpacing = isSmallScreen ? 12.0 : 16.0;
    final mainAxisSpacing = isSmallScreen ? 20.0 : 28.0;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isSmallScreen ? 8 : 8,
        horizontalPadding,
        24,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final priceStr = product['product_price']?.toString() ?? '0.00';
        final imageUrl = ProductImageService.getPrimaryImageUrl(product);
        final productName =
            (product['product_name'] ?? 'Unknown').toString().toUpperCase();
        final productType =
            (product['product_type'] ?? '').toString().toUpperCase();

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
                  child: _buildProductImage(imageUrl),
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              if (productType.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    productType,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: isSmallScreen ? 9 : 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              Text(
                productName,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: isSmallScreen ? 11 : 12,
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                'RM $priceStr',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w300,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return TextField(
      controller: _searchController,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        hintText: isSmallScreen
            ? 'Search products...'
            : 'Search product, gender, type, color, material...',
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
        prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.close, color: Colors.black54, size: 20),
              ),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: _genderOptions.map((gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(
            _getGenderLabel(gender),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value ?? 'ALL';
        });
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: _productTypeOptions.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type == 'ALL' ? 'All Types' : type.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedType = value ?? 'ALL';
        });
      },
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSort,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Sort',
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: _sortOptions.map((sort) {
        return DropdownMenuItem<String>(
          value: sort,
          child: Text(
            _getSortLabel(sort),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSort = value ?? 'DEFAULT';
        });
      },
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: 110,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _searchController.clear();
            _selectedGender = (widget.gender ?? 'ALL').toUpperCase();
            _selectedType = 'ALL';
            _selectedSort = 'DEFAULT';
            _showFilters = false;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'RESET',
          style: TextStyle(fontSize: 12, letterSpacing: 1.0),
        ),
      ),
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