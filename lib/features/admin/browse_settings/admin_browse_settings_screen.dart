import 'package:flutter/material.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/models/browse_settings.dart';
import '../../../data/repositories/browse_settings_repository.dart';

class AdminBrowseSettingsScreen extends StatefulWidget {
  const AdminBrowseSettingsScreen({super.key});

  @override
  State<AdminBrowseSettingsScreen> createState() => _AdminBrowseSettingsScreenState();
}

class _AdminBrowseSettingsScreenState extends State<AdminBrowseSettingsScreen> {
  final _repository = BrowseSettingsRepository();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _tableExists = true;

  // Form Fields controllers & values
  final _liveNowLabelController = TextEditingController();
  String _liveNowSort = 'popular';
  bool _liveNowEnabled = true;

  final _dealsLabelController = TextEditingController();
  final _dealsPriceController = TextEditingController();
  bool _dealsEnabled = true;

  final _saleComingLabelController = TextEditingController();
  String _saleComingSort = 'new';
  bool _saleComingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _liveNowLabelController.dispose();
    _dealsLabelController.dispose();
    _dealsPriceController.dispose();
    _saleComingLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    // Check if table exists
    _tableExists = await _repository.checkTableExists();
    
    final settings = await _repository.getSettings();

    _liveNowLabelController.text = settings.liveNowLabel;
    _liveNowSort = settings.liveNowSort;
    _liveNowEnabled = settings.liveNowEnabled;

    _dealsLabelController.text = settings.dealsLabel;
    _dealsPriceController.text = settings.dealsPrice.toStringAsFixed(0);
    _dealsEnabled = settings.dealsEnabled;

    _saleComingLabelController.text = settings.saleComingLabel;
    _saleComingSort = settings.saleComingSort;
    _saleComingEnabled = settings.saleComingEnabled;

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = BrowseSettings(
      id: 'popular_store_settings',
      liveNowLabel: _liveNowLabelController.text.trim(),
      liveNowSort: _liveNowSort,
      liveNowEnabled: _liveNowEnabled,
      dealsLabel: _dealsLabelController.text.trim(),
      dealsPrice: double.tryParse(_dealsPriceController.text.trim()) ?? 99.0,
      dealsEnabled: _dealsEnabled,
      saleComingLabel: _saleComingLabelController.text.trim(),
      saleComingSort: _saleComingSort,
      saleComingEnabled: _saleComingEnabled,
    );

    try {
      await _repository.updateSettings(updated);
      if (mounted) {
        context.showSuccessSnackBar('Browse settings updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Save Warning'),
              ],
            ),
            content: Text(
              'Failed to save to database. It was saved locally for this session.\n\n'
              'Details: $e'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Browse Page Controls',
                                  style: context.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Control categories, pricing, and labels for home navigation tiles',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.isDarkMode ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveSettings,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: const Text('Save Settings'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Warning card if table doesn't exist
                      if (!_tableExists)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: Colors.amber.shade900.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade700, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Database Table Missing',
                                      style: TextStyle(
                                        color: Colors.amber.shade700,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'The "browse_settings" table does not exist in Supabase yet. '
                                      'Settings will run on local defaults. Run the migration SQL in your Supabase editor to enable global synchronization.',
                                      style: context.textTheme.bodySmall?.copyWith(height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Live Now Section Settings Card
                      _buildSettingsCard(
                        title: 'Live Now Block',
                        icon: Icons.flash_on_rounded,
                        color: Colors.amber,
                        enabled: _liveNowEnabled,
                        onToggle: (val) => setState(() => _liveNowEnabled = val),
                        children: [
                          TextFormField(
                            controller: _liveNowLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Block Label Text',
                              hintText: 'e.g., Live now',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Label cannot be empty' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _liveNowSort,
                            decoration: const InputDecoration(
                              labelText: 'Sort Criteria',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'popular', child: Text('Popular (Review Count)')),
                              DropdownMenuItem(value: 'rating', child: Text('Rating (High to Low)')),
                              DropdownMenuItem(value: 'created_at', child: Text('Newest First')),
                            ],
                            onChanged: (val) => setState(() => _liveNowSort = val ?? 'popular'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Deals Section Settings Card
                      _buildSettingsCard(
                        title: 'Deals Block',
                        icon: Icons.percent_rounded,
                        color: Colors.red,
                        enabled: _dealsEnabled,
                        onToggle: (val) => setState(() => _dealsEnabled = val),
                        children: [
                          TextFormField(
                            controller: _dealsLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Block Label Text',
                              hintText: 'e.g., Deals at 99',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Label cannot be empty' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dealsPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Maximum Price Limit (₹)',
                              hintText: 'e.g., 99',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Price limit is required';
                              if (double.tryParse(v.trim()) == null) return 'Must be a valid number';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sale Coming Section Settings Card
                      _buildSettingsCard(
                        title: 'Sale Coming Block',
                        icon: Icons.calendar_month_rounded,
                        color: Colors.purple,
                        enabled: _saleComingEnabled,
                        onToggle: (val) => setState(() => _saleComingEnabled = val),
                        children: [
                          TextFormField(
                            controller: _saleComingLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Block Label Text',
                              hintText: 'e.g., Sale coming!',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Label cannot be empty' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _saleComingSort,
                            decoration: const InputDecoration(
                              labelText: 'Sort Criteria',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'new', child: Text('New arrivals (Created At)')),
                              DropdownMenuItem(value: 'created_at', child: Text('Newest First')),
                              DropdownMenuItem(value: 'popular', child: Text('Popular (Review Count)')),
                            ],
                            onChanged: (val) => setState(() => _saleComingSort = val ?? 'new'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color.shade800, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            ...children,
          ],
        ],
      ),
    );
  }
}
