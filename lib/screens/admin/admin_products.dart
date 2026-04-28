import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/admin_service.dart';
import '../../services/product_image_service.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _adminService = AdminService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _adminService.getProducts();
      final categories = await _adminService.getCategories();

      if (!mounted) return;
      setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _products;

    return _products.where((product) {
      final text = [
        product['product_name'],
        product['product_type'],
        product['product_gender'],
        product['product_status'],
        (product['categories'] as Map<String, dynamic>?)?['category_name'],
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }

  Future<void> _toggleProductStatus(Map<String, dynamic> product) async {
    try {
      final currentStatus = product['product_status']?.toString() ?? 'active';
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';

      await _adminService.updateProduct(
        productId: product['product_id'],
        categoryId: product['category_id'],
        name: product['product_name'],
        description: product['product_description'] ?? '',
        gender: product['product_gender'],
        type: product['product_type'],
        fitType: product['fit_type'] ?? 'regular',
        color: product['color'] ?? '',
        material: product['material'] ?? '',
        price: (product['product_price'] ?? 0).toDouble(),
        status: newStatus,
        pic1: product['product_pic1'],
        pic2: product['product_pic2'],
        pic3: product['product_pic3'],
        pic4: product['product_pic4'],
        stocks: {
          for (final q in (product['quantities'] as List<dynamic>? ?? []))
            q['size'].toString(): (q['product_stock'] ?? 0) as int,
        },
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update product: $e')));
    }
  }

  Future<void> _deleteOldImagesIfChanged(
    Map<String, dynamic> oldProduct,
    Map<String, dynamic> newData,
  ) async {
    final oldImages = [
      oldProduct['product_pic1'],
      oldProduct['product_pic2'],
      oldProduct['product_pic3'],
      oldProduct['product_pic4'],
    ];

    final newImages = [
      newData['product_pic1'],
      newData['product_pic2'],
      newData['product_pic3'],
      newData['product_pic4'],
    ];

    for (int i = 0; i < oldImages.length; i++) {
      final oldName = (oldImages[i] ?? '').toString().trim();
      final newName = (newImages[i] ?? '').toString().trim();

      if (oldName.isNotEmpty && oldName != newName) {
        await _adminService.deleteProductImage(oldName);
      }
    }
  }

  Future<void> _openProductDialog({Map<String, dynamic>? product}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProductDialog(categories: _categories, product: product),
    );

    if (result == null) return;

    try {
      if (product == null) {
        await _adminService.addProduct(
          categoryId: result['category_id'],
          name: result['product_name'],
          description: result['product_description'],
          gender: result['product_gender'],
          type: result['product_type'],
          fitType: result['fit_type'],
          color: result['color'],
          material: result['material'],
          price: result['product_price'],
          status: result['product_status'],
          pic1: result['product_pic1'],
          pic2: result['product_pic2'],
          pic3: result['product_pic3'],
          pic4: result['product_pic4'],
          stocks: Map<String, int>.from(result['stocks']),
        );
      } else {
        await _adminService.updateProduct(
          productId: product['product_id'],
          categoryId: result['category_id'],
          name: result['product_name'],
          description: result['product_description'],
          gender: result['product_gender'],
          type: result['product_type'],
          fitType: result['fit_type'],
          color: result['color'],
          material: result['material'],
          price: result['product_price'],
          status: result['product_status'],
          pic1: result['product_pic1'],
          pic2: result['product_pic2'],
          pic3: result['product_pic3'],
          pic4: result['product_pic4'],
          stocks: Map<String, int>.from(result['stocks']),
        );

        await _deleteOldImagesIfChanged(product, result);
      }

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  String _buildStockText(List<dynamic>? quantities) {
    if (quantities == null || quantities.isEmpty) return 'No stock';
    return quantities
        .map((q) => '${q['size']}:${q['product_stock']}')
        .join(' | ');
  }

  Color _statusColor(String status) {
    return status == 'active' ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('MANAGE PRODUCTS'),
        backgroundColor: const Color(0xFFF8F8F8),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => _openProductDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final category =
                            (product['categories'] as Map<String, dynamic>?) ??
                            {};
                        final quantities =
                            product['quantities'] as List<dynamic>?;
                        final status =
                            product['product_status']?.toString() ?? 'inactive';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['product_name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Category: ${category['category_name'] ?? '-'}',
                              ),
                              Text('Type: ${product['product_type'] ?? '-'}'),
                              Text(
                                'Gender: ${product['product_gender'] ?? '-'}',
                              ),
                              Text('Price: RM${product['product_price'] ?? 0}'),
                              Text('Stock: ${_buildStockText(quantities)}'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    status,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _openProductDialog(product: product),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('EDIT'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: status == 'active'
                                            ? Colors.red
                                            : Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          _toggleProductStatus(product),
                                      child: Text(
                                        status == 'active'
                                            ? 'SET INACTIVE'
                                            : 'SET ACTIVE',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? product;

  const _ProductDialog({required this.categories, this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _adminService = AdminService();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _colorController;
  late TextEditingController _materialController;
  late TextEditingController _priceController;
  late TextEditingController _pic1Controller;
  late TextEditingController _pic2Controller;
  late TextEditingController _pic3Controller;
  late TextEditingController _pic4Controller;

  final Map<String, TextEditingController> _stockControllers = {
    'xs': TextEditingController(),
    's': TextEditingController(),
    'm': TextEditingController(),
    'l': TextEditingController(),
    'xl': TextEditingController(),
    'xxl': TextEditingController(),
    'free_size': TextEditingController(),
  };

  String? _categoryId;
  String _gender = 'unisex';
  String _type = 'shirt';
  String _fitType = 'regular';
  String _status = 'active';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _nameController = TextEditingController(
      text: product?['product_name']?.toString() ?? '',
    );
    _descController = TextEditingController(
      text: product?['product_description']?.toString() ?? '',
    );
    _colorController = TextEditingController(
      text: product?['color']?.toString() ?? '',
    );
    _materialController = TextEditingController(
      text: product?['material']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: product?['product_price']?.toString() ?? '',
    );
    _pic1Controller = TextEditingController(
      text: product?['product_pic1']?.toString() ?? '',
    );
    _pic2Controller = TextEditingController(
      text: product?['product_pic2']?.toString() ?? '',
    );
    _pic3Controller = TextEditingController(
      text: product?['product_pic3']?.toString() ?? '',
    );
    _pic4Controller = TextEditingController(
      text: product?['product_pic4']?.toString() ?? '',
    );

    _categoryId = product?['category_id']?.toString();
    _gender = product?['product_gender']?.toString() ?? 'unisex';
    _type = product?['product_type']?.toString() ?? 'shirt';
    _fitType = product?['fit_type']?.toString() ?? 'regular';
    _status = product?['product_status']?.toString() ?? 'active';

    final quantities = product?['quantities'] as List<dynamic>? ?? [];
    for (final q in quantities) {
      final size = q['size']?.toString();
      if (size != null && _stockControllers.containsKey(size)) {
        _stockControllers[size]!.text = (q['product_stock'] ?? 0).toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _priceController.dispose();
    _pic1Controller.dispose();
    _pic2Controller.dispose();
    _pic3Controller.dispose();
    _pic4Controller.dispose();
    for (final c in _stockControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);

    try {
      final uploadedFileName = await _adminService.uploadProductImage(
        imageBytes: file.bytes!,
        originalFileName: file.name,
      );

      controller.text = uploadedFileName;

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _stockField(String size) {
    return TextField(
      controller: _stockControllers[size],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: size.toUpperCase(),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _imageUploadField(String label, TextEditingController controller) {
    final imageUrl = controller.text.trim().isEmpty
        ? ''
        : ProductImageService.getPublicUrl(controller.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _isUploading
                  ? null
                  : () => _pickAndUploadImage(controller),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (imageUrl.isNotEmpty)
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF5F5F5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Text('Preview not available')),
              ),
            ),
          ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (_categoryId == null || name.isEmpty || price == null) return;

    final stocks = <String, int>{};
    for (final entry in _stockControllers.entries) {
      stocks[entry.key] = int.tryParse(entry.value.text.trim()) ?? 0;
    }

    Navigator.pop(context, {
      'category_id': _categoryId,
      'product_name': name,
      'product_description': _descController.text.trim(),
      'product_gender': _gender,
      'product_type': _type,
      'fit_type': _fitType,
      'color': _colorController.text.trim(),
      'material': _materialController.text.trim(),
      'product_price': price,
      'product_status': _status,
      'product_pic1': _pic1Controller.text.trim(),
      'product_pic2': _pic2Controller.text.trim(),
      'product_pic3': _pic3Controller.text.trim(),
      'product_pic4': _pic4Controller.text.trim(),
      'stocks': stocks,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'ADD PRODUCT' : 'EDIT PRODUCT'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['category_id'].toString(),
                        child: Text(c['category_name'].toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'men', child: Text('Men')),
                  DropdownMenuItem(value: 'women', child: Text('Women')),
                  DropdownMenuItem(value: 'unisex', child: Text('Unisex')),
                ],
                onChanged: (value) =>
                    setState(() => _gender = value ?? 'unisex'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'shirt', child: Text('shirt')),
                  DropdownMenuItem(value: 'tshirt', child: Text('tshirt')),
                  DropdownMenuItem(value: 'blouse', child: Text('blouse')),
                  DropdownMenuItem(value: 'pants', child: Text('pants')),
                  DropdownMenuItem(value: 'jeans', child: Text('jeans')),
                  DropdownMenuItem(value: 'jacket', child: Text('jacket')),
                  DropdownMenuItem(value: 'hoodie', child: Text('hoodie')),
                  DropdownMenuItem(value: 'dress', child: Text('dress')),
                  DropdownMenuItem(value: 'skirt', child: Text('skirt')),
                  DropdownMenuItem(value: 'bag', child: Text('bag')),
                  DropdownMenuItem(value: 'shoes', child: Text('shoes')),
                  DropdownMenuItem(
                    value: 'accessory',
                    child: Text('accessory'),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value ?? 'shirt'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _fitType,
                decoration: const InputDecoration(
                  labelText: 'Fit Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'slim', child: Text('slim')),
                  DropdownMenuItem(value: 'regular', child: Text('regular')),
                  DropdownMenuItem(value: 'relaxed', child: Text('relaxed')),
                  DropdownMenuItem(
                    value: 'oversized',
                    child: Text('oversized'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _fitType = value ?? 'regular'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _materialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('active')),
                  DropdownMenuItem(value: 'inactive', child: Text('inactive')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'active'),
              ),
              const SizedBox(height: 16),
              _imageUploadField('Image 1', _pic1Controller),
              const SizedBox(height: 12),
              _imageUploadField('Image 2', _pic2Controller),
              const SizedBox(height: 12),
              _imageUploadField('Image 3', _pic3Controller),
              const SizedBox(height: 12),
              _imageUploadField('Image 4', _pic4Controller),
              const SizedBox(height: 16),
              _stockField('xs'),
              const SizedBox(height: 12),
              _stockField('s'),
              const SizedBox(height: 12),
              _stockField('m'),
              const SizedBox(height: 12),
              _stockField('l'),
              const SizedBox(height: 12),
              _stockField('xl'),
              const SizedBox(height: 12),
              _stockField('xxl'),
              const SizedBox(height: 12),
              _stockField('free_size'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submit,
          child: _isUploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
