
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/repositories/banner_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../shared/widgets/cached_image.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final _repo = BannerRepository();
  final _storageRepo = StorageRepository();
  final _picker = ImagePicker();
  List<BannerModel> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final banners = await _repo.getAllBanners();
    setState(() {
      _banners = banners;
      _isLoading = false;
    });
  }

  Future<void> _addBanner() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      final url = await _storageRepo.uploadImage(
        bucket: AppConstants.bannerImagesBucket,
        file: file,
        folder: 'banners',
      );
      await _repo.createBanner({'image_url': url, 'is_active': true});
      _load();
    } catch (e) {
      if (mounted) context.showSnackBar('Failed: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addBanner();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Add Image URL'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddUrlDialog();
                },
              ),
            ],
          ),
        );
      },
    );
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
            hintText: 'https://example.com/banner.png',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = ctrl.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await _repo.createBanner({'image_url': url, 'is_active': true});
                  _load();
                } catch (e) {
                  if (mounted) context.showSnackBar('Failed: $e', isError: true);
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editBannerDetails(BannerModel banner) {
    final titleCtrl = TextEditingController(text: banner.title ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Banner Text'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. LIMITED\\nDROP',
            labelText: 'Banner Text (use \\n for newline)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleCtrl.text.trim();
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _repo.updateBanner(banner.id, {
                  'title': newTitle.isEmpty ? null : newTitle,
                });
                _load();
              } catch (e) {
                if (mounted) context.showSnackBar('Failed: $e', isError: true);
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _showAddOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _banners.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final b = _banners[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedImage(
                          imageUrl: b.imageUrl,
                          width: double.infinity,
                          height: 160,
                          placeholderIcon: Icons.image_outlined,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            _actionBtn(
                              icon: b.isActive
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: b.isActive
                                  ? const Color(0xFF2ED573)
                                  : Colors.grey,
                              onTap: () async {
                                await _repo.updateBanner(
                                    b.id, {'is_active': !b.isActive});
                                _load();
                              },
                            ),
                            _actionBtn(
                              icon: Icons.edit_outlined,
                              color: context.isDarkMode ? Colors.white : Colors.black,
                              onTap: () => _editBannerDetails(b),
                            ),
                            const SizedBox(width: 6),
                            _actionBtn(
                              icon: Icons.delete_outline,
                              color: const Color(0xFFFF6B6B),
                              onTap: () async {
                                await _repo.deleteBanner(b.id);
                                _load();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
