
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
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      final url = await _storageRepo.uploadImage(
        bucket: AppConstants.bannerImagesBucket,
        file: file,
        folder: 'banners',
      );
      await _repo.createBanner({'image_url': url, 'is_active': true});
      if (mounted) context.showSuccessSnackBar('Banner added!');
      _load();
    } catch (e) {
      if (mounted) context.showSnackBar('Failed: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  /// Replace an existing banner's image
  Future<void> _replaceBannerImage(BannerModel banner) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('Upload from Device', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pick from gallery', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addBanner();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.link, color: Colors.orange),
                  ),
                  title: const Text('Add Image URL', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Paste an image link', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddUrlDialog();
                  },
                ),
              ],
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Image URL'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'https://example.com/banner.png',
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Banner Text'),
        content: TextField(
          controller: titleCtrl,
          decoration: InputDecoration(
            hintText: 'e.g. SUMMER SALE',
            labelText: 'Banner Text',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  void _confirmDelete(BannerModel banner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      Text('No banners yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Banner image — BoxFit.cover for perfect fit
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: CachedImage(
                                imageUrl: b.imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                placeholderIcon: Icons.image_outlined,
                              ),
                            ),
                            // Action bar below image
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
                                  // Status badge
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
                                        style: TextStyle(fontSize: 12, color: context.isDarkMode ? Colors.white54 : Colors.black54),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ] else
                                    const Spacer(),
                                  // Replace image
                                  _actionBtn(
                                    icon: Icons.image_outlined,
                                    color: Colors.blue,
                                    tooltip: 'Replace Image',
                                    onTap: () => _replaceBannerImage(b),
                                  ),
                                  const SizedBox(width: 6),
                                  // Toggle visibility
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
                                  // Edit text
                                  _actionBtn(
                                    icon: Icons.edit_outlined,
                                    color: context.isDarkMode ? Colors.white : Colors.black87,
                                    tooltip: 'Edit Text',
                                    onTap: () => _editBannerDetails(b),
                                  ),
                                  const SizedBox(width: 6),
                                  // Delete
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)
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
