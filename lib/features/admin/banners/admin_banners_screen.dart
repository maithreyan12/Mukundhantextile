
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/repositories/banner_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/utils/image_picker_cropper.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final _repo = BannerRepository();
  final _storageRepo = StorageRepository();
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
    final file = await ImagePickerCropper.pickAndCrop(
      context,
      preset: CropAspectRatioPreset.ratio16x9,
      title: 'Crop Banner (16:9)',
    );
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
          : _banners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No banners yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first banner', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _banners.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final b = _banners[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.isDarkMode ? Colors.white12 : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Banner image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: CachedImage(
                                imageUrl: b.imageUrl,
                                width: double.infinity,
                                height: 180,
                                placeholderIcon: Icons.image_outlined,
                              ),
                            ),
                            // Action bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.isDarkMode 
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.grey.shade50,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                              ),
                              child: Row(
                                children: [
                                  // Status indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: b.isActive
                                          ? const Color(0xFF2ED573).withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      b.isActive ? 'Active' : 'Hidden',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: b.isActive ? const Color(0xFF2ED573) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (b.title != null && b.title!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        b.title!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.isDarkMode ? Colors.white54 : Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ] else
                                    const Spacer(),
                                  // Action buttons
                                  _actionBtn(
                                    icon: Icons.crop_rounded,
                                    color: Colors.blue,
                                    tooltip: 'Replace & Crop',
                                    onTap: () => _replaceBannerImage(b),
                                  ),
                                  const SizedBox(width: 6),
                                  _actionBtn(
                                    icon: b.isActive ? Icons.visibility : Icons.visibility_off,
                                    color: b.isActive ? const Color(0xFF2ED573) : Colors.grey,
                                    tooltip: b.isActive ? 'Hide' : 'Show',
                                    onTap: () async {
                                      await _repo.updateBanner(b.id, {'is_active': !b.isActive});
                                      _load();
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  _actionBtn(
                                    icon: Icons.edit_outlined,
                                    color: context.isDarkMode ? Colors.white : Colors.black,
                                    tooltip: 'Edit Text',
                                    onTap: () => _editBannerDetails(b),
                                  ),
                                  const SizedBox(width: 6),
                                  _actionBtn(
                                    icon: Icons.delete_outline,
                                    color: const Color(0xFFFF6B6B),
                                    tooltip: 'Delete',
                                    onTap: () => _confirmDelete(b),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  /// Replace an existing banner's image with a new cropped one
  Future<void> _replaceBannerImage(BannerModel banner) async {
    final file = await ImagePickerCropper.pickAndCrop(
      context,
      preset: CropAspectRatioPreset.ratio16x9,
      title: 'Crop Banner (16:9)',
    );
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      final url = await _storageRepo.uploadImage(
        bucket: AppConstants.bannerImagesBucket,
        file: file,
        folder: 'banners',
      );
      await _repo.updateBanner(banner.id, {'image_url': url});
      if (mounted) context.showSuccessSnackBar('Banner image updated!');
      _load();
    } catch (e) {
      if (mounted) context.showSnackBar('Failed: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  /// Confirm before deleting a banner
  void _confirmDelete(BannerModel banner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _repo.deleteBanner(banner.id);
              _load();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.isDarkMode ? Colors.white12 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }
}
