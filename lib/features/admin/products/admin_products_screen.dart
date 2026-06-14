import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../shared/widgets/cached_image.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _repo = ProductRepository();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final products = await _repo.getAllProducts(pageSize: 100);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () =>
                context.push('/admin/products/new').then((_) => _load()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return ListTile(
                    onTap: () => context
                        .push('/admin/products/${p.id}')
                        .then((_) => _load()),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: p.primaryImage.isNotEmpty ? p.primaryImage : null,
                        width: 50,
                        height: 50,
                        placeholderIcon: Icons.inventory_2_outlined,
                      ),
                    ),
                    title: Text(p.name, style: context.textTheme.titleSmall),
                    subtitle: Text(
                      '${p.effectivePrice.toCurrency} · Stock: ${p.stock}',
                      style: context.textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.isActive
                                ? const Color(0xFF2ED573)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'toggle') {
                              await _repo.toggleActive(p.id, !p.isActive);
                              _load();
                            } else if (v == 'delete') {
                              await _repo.deleteProduct(p.id);
                              _load();
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(p.isActive ? 'Deactivate' : 'Activate'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete',
                                  style: TextStyle(color: Color(0xFFFF6B6B))),
                            ),
                          ],
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
