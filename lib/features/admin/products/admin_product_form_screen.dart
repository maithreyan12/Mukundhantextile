import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';

class AdminProductFormScreen extends StatefulWidget {
  final String? productId;

  const AdminProductFormScreen({super.key, this.productId});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productRepo = ProductRepository();
  final _categoryRepo = CategoryRepository();
  final _storageRepo = StorageRepository();
  final _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  List<Category> _categories = [];
  String? _selectedCategoryId;
  List<String> _imageUrls = [];
  final List<XFile> _newImages = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isActive = true;

  bool get isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _categories = await _categoryRepo.getAllCategories();

    if (isEditing) {
      final product = await _productRepo.getProduct(widget.productId!);
      _nameCtrl.text = product.name;
      _descCtrl.text = product.description;
      _priceCtrl.text = product.price.toString();
      _discountCtrl.text = product.discountPrice?.toString() ?? '';
      _stockCtrl.text = product.stock.toString();
      _selectedCategoryId = product.categoryId;
      _imageUrls = List.from(product.images);
      _isActive = product.isActive;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        _newImages.addAll(files);
      });
    }
  }

  void _showAddUrlDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Image URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.png',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = ctrl.text.trim();
              if (url.isNotEmpty) {
                setState(() => _imageUrls.add(url));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // Upload new images
      if (_newImages.isNotEmpty) {
        final urls = await _storageRepo.uploadImages(
          bucket: AppConstants.productImagesBucket,
          files: _newImages,
          folder: 'products',
        );
        _imageUrls.addAll(urls);
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'discount_price': _discountCtrl.text.trim().isNotEmpty
            ? double.parse(_discountCtrl.text.trim())
            : null,
        'category_id': _selectedCategoryId,
        'stock': int.parse(_stockCtrl.text.trim()),
        'images': _imageUrls,
        'is_active': _isActive,
      };

      if (isEditing) {
        await _productRepo.updateProduct(widget.productId!, data);
      } else {
        await _productRepo.createProduct(data);
      }

      if (mounted) {
        context.showSuccessSnackBar(
            isEditing ? 'Product updated!' : 'Product created!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images
                    Text('Product Images',
                        style: context.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._imageUrls.map((url) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: Image.network(url,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() =>
                                            _imageUrls.remove(url)),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF6B6B),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              size: 14,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          ..._newImages.map((file) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: kIsWeb
                                      ? Image.network(file.path,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover)
                                      : Image.file(File(file.path),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover),
                                ),
                              )),
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF2979FF)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: Color(0xFF2979FF)),
                                  Text('Add',
                                      style: TextStyle(
                                          color: Color(0xFF2979FF),
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showAddUrlDialog,
                            child: Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF2979FF)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.link,
                                      color: Color(0xFF2979FF)),
                                  Text('Add URL',
                                      style: TextStyle(
                                          color: Color(0xFF2979FF),
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _nameCtrl,
                      label: 'Product Name',
                      hint: 'Enter product name',
                      validator: (v) => Validators.required(v, 'Name'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descCtrl,
                      label: 'Description',
                      hint: 'Enter product description',
                      maxLines: 4,
                      validator: (v) => Validators.required(v, 'Description'),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    Text('Category', style: context.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      items: _categories
                          .map((c) => DropdownMenuItem<String>(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategoryId = v),
                      decoration: const InputDecoration(
                        hintText: 'Select category',
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _priceCtrl,
                            label: 'Price (₹)',
                            hint: '0.00',
                            keyboardType: TextInputType.number,
                            validator: Validators.price,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _discountCtrl,
                            label: 'Discount Price (₹)',
                            hint: 'Optional',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _stockCtrl,
                      label: 'Stock',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      validator: Validators.stock,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      title: const Text('Active'),
                      activeThumbColor: const Color(0xFF2979FF),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    PremiumButton(
                      onPressed: _isSaving ? null : _save,
                      backgroundColor: context.isDarkMode ? Colors.white : Colors.black,
                      child: _isSaving
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: context.isDarkMode ? Colors.black : Colors.white))
                        : Text(isEditing ? 'UPDATE PRODUCT' : 'CREATE PRODUCT', style: TextStyle(color: context.isDarkMode ? Colors.black : Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
