import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/constants.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/premium_button.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _repo = CategoryRepository();
  final _storageRepo = StorageRepository();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final cats = await _repo.getAllCategories();
    setState(() {
      _categories = cats;
      _isLoading = false;
    });
  }

  void _showForm({Category? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    XFile? selectedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: context.isDarkMode ? const Color(0xFF141414) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.isDarkMode ? Colors.white12 : Colors.black12),
            ),
            title: Text(category == null ? 'Add Category' : 'Edit Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (file != null) {
                      setState(() => selectedImage = file);
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.isDarkMode ? Colors.white24 : Colors.grey.shade300),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(selectedImage!.path, fit: BoxFit.cover),
                          )
                        : category?.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedImage(imageUrl: category!.imageUrl, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: nameCtrl,
                  label: 'Category Name',
                  hint: 'Enter name',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              SizedBox(
                width: 120,
                child: PremiumButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ctx.showSnackBar('Name is required', isError: true);
                            return;
                          }
                          setState(() => isSaving = true);

                          try {
                            String? imageUrl = category?.imageUrl;
                            if (selectedImage != null) {
                              imageUrl = await _storageRepo.uploadImage(
                                bucket: AppConstants.categoryImagesBucket,
                                file: selectedImage!,
                              );
                            }

                            if (category == null) {
                              await _repo.createCategory({
                                'name': name,
                                'image_url': imageUrl,
                              });
                            } else {
                              await _repo.updateCategory(category.id, {
                                'name': name,
                                'image_url': imageUrl,
                              });
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _load();
                          } catch (e) {
                            if (ctx.mounted) {
                              ctx.showSnackBar('Error saving category: $e', isError: true);
                            }
                          } finally {
                            if (ctx.mounted) {
                              setState(() => isSaving = false);
                            }
                          }
                        },
                  backgroundColor: const Color(0xFFEAEAEA),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: cat.imageUrl,
                        width: 44,
                        height: 44,
                        placeholderIcon: Icons.category_outlined,
                      ),
                    ),
                    title: Text(cat.name,
                        style: context.textTheme.titleSmall),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showForm(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFFFF6B6B)),
                          onPressed: () async {
                            await _repo.deleteCategory(cat.id);
                            _load();
                          },
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade50,
                  );
                },
              ),
            ),
    );
  }
}
