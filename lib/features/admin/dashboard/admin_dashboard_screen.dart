import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/product.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _orderRepo = OrderRepository();
  final _productRepo = ProductRepository();
  final _userRepo = UserRepository();

  bool _isLoading = true;
  String? _error;
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalUsers = 0;
  int _totalProducts = 0;
  List<Product> _lowStock = [];
  List<double> _revenueData = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stats = await _orderRepo.getOrderStats();
      final users = await _userRepo.getUserCount();
      final products = await _productRepo.getAllProducts(pageSize: 1000);
      final lowStock = await _productRepo.getLowStockProducts();

      // Simple revenue data for chart
      final orders = stats['orders'] as List;
      final revenueByDay = <double>[];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        double dayRevenue = 0;
        for (final o in orders) {
          final oDate = DateTime.parse(o['created_at'] as String);
          if (oDate.day == date.day && oDate.month == date.month) {
            dayRevenue += (o['total_amount'] as num?)?.toDouble() ?? 0;
          }
        }
        revenueByDay.add(dayRevenue);
      }

      setState(() {
        _totalRevenue = stats['total_revenue'] as double;
        _totalOrders = stats['total_orders'] as int;
        _totalUsers = users;
        _totalProducts = products.length;
        _lowStock = lowStock;
        _revenueData = revenueByDay;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 16),
            Text('Loading dashboard...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('Failed to load dashboard',
                  style: context.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, style: context.textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text('Overview',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const Spacer(),
                TextButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KPI Cards
            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth > 700
                  ? 4
                  : constraints.maxWidth > 400
                      ? 2
                      : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: cols == 4 ? 1.6 : 1.5,
                children: [
                  _kpiCard(
                    label: 'Revenue',
                    value: _totalRevenue.toCurrencyCompact,
                    icon: Icons.attach_money_rounded,
                    color: const Color(0xFF2ED573),
                    bgGradient: [
                      const Color(0xFF2ED573).withValues(alpha: 0.15),
                      const Color(0xFF2ED573).withValues(alpha: 0.05),
                    ],
                  ),
                  _kpiCard(
                    label: 'Orders',
                    value: '$_totalOrders',
                    icon: Icons.receipt_long_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    bgGradient: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  _kpiCard(
                    label: 'Users',
                    value: '$_totalUsers',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF3498DB),
                    bgGradient: [
                      const Color(0xFF3498DB).withValues(alpha: 0.15),
                      const Color(0xFF3498DB).withValues(alpha: 0.05),
                    ],
                  ),
                  _kpiCard(
                    label: 'Products',
                    value: '$_totalProducts',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFFFF9F43),
                    bgGradient: [
                      const Color(0xFFFF9F43).withValues(alpha: 0.15),
                      const Color(0xFFFF9F43).withValues(alpha: 0.05),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 28),

            // Revenue Chart
            Text('Revenue (Last 7 Days)',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 14),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.isDarkMode
                      ? Colors.white12
                      : Colors.grey.shade200,
                ),
                boxShadow: context.isDarkMode
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: _revenueData.every((v) => v == 0)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart_rounded,
                              size: 40,
                              color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('No revenue data yet',
                              style: TextStyle(color: Colors.grey.shade500)),
                          Text('Revenue will appear here once orders are placed',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getMaxRevenue() / 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withValues(alpha: 0.15),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final day = DateTime.now()
                                    .subtract(Duration(days: 6 - value.toInt()));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                        [day.weekday - 1],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _revenueData
                                .asMap()
                                .entries
                                .map((e) =>
                                    FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 28),

            // Low Stock Alerts
            if (_lowStock.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: const Color(0xFFFF6B6B), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Low Stock Alerts (${_lowStock.length})',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...(_lowStock.take(5).map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2,
                              color: Color(0xFFFF6B6B), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p.name,
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${p.stock} left',
                            style: const TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))),
            ],

            // Empty state when everything is fresh
            if (_totalOrders == 0 &&
                _totalProducts == 0 &&
                _lowStock.isEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.rocket_launch_rounded,
                        size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Welcome to your Admin Dashboard!',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Start by adding categories and products to your store. '
                      'Once customers place orders, you\'ll see real-time analytics here.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              GoRouter.of(context).go('/admin/categories'),
                          icon: const Icon(Icons.category, size: 18),
                          label: const Text('Add Categories'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              GoRouter.of(context).go('/admin/products'),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add Products'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getMaxRevenue() {
    if (_revenueData.isEmpty) return 1;
    final max = _revenueData.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max : 1;
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDarkMode
              ? [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.04),
                ]
              : bgGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.isDarkMode
                  ? Colors.white60
                  : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
