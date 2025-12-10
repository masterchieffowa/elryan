import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../customers/customers_screen.dart';
import '../orders/orders_screen.dart';
import '../accessories/accessories_screen.dart';
import '../dealers/dealers_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../../../domain/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _refreshAllData() {
    ref.invalidate(ordersProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(dealersProvider);
    ref.invalidate(accessoriesProvider);
    ref.invalidate(statisticsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    final screens = [
      DashboardTab(onRefresh: _refreshAllData),
      const OrdersScreen(),
      const CustomersScreen(),
      const DealersScreen(),
      const AccessoriesScreen(),
      const ReportsScreen(),
    ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar Navigation
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
                // Refresh data when switching tabs
                _refreshAllData();
              },
              labelType: NavigationRailLabelType.all,
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/icon.png'),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.appName,
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 32),
                ],
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshAllData,
                          tooltip: l10n.isArabic ? 'تحديث' : 'Refresh',
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ).then((_) => _refreshAllData());
                          },
                          tooltip: l10n.settings,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: Text(l10n.dashboard),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.build_outlined),
                  selectedIcon: const Icon(Icons.build),
                  label: Text(l10n.orders),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.people_outlined),
                  selectedIcon: const Icon(Icons.people),
                  label: Text(l10n.customers),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.business_outlined),
                  selectedIcon: const Icon(Icons.business),
                  label: Text(l10n.isArabic ? 'الموزعين' : 'Dealers'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: Text(l10n.accessories),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.assessment_outlined),
                  selectedIcon: const Icon(Icons.assessment),
                  label: Text(l10n.reports),
                ),
              ],
            ),

            const VerticalDivider(thickness: 1, width: 1),

            // Main Content
            Expanded(
              child: screens[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Tab with Real-time Updates
class DashboardTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const DashboardTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Last Updated Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.isArabic ? "آخر تحديث" : "Last updated"}: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label:
                            Text(l10n.isArabic ? 'تحديث الآن' : 'Refresh Now'),
                        onPressed: onRefresh,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics Cards
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2,
                  children: [
                    _StatCard(
                      title: l10n.totalOrders,
                      value: '${stats['total_orders']}',
                      icon: Icons.build,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: l10n.pendingOrders,
                      value: '${stats['pending_orders']}',
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: l10n.completedOrders,
                      value: '${stats['completed_orders']}',
                      icon: Icons.done_all,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: l10n.totalRevenue,
                      value: l10n.currency(stats['total_revenue']),
                      icon: Icons.attach_money,
                      color: Colors.teal,
                    ),
                    _StatCard(
                      title: l10n.outstandingBalance,
                      value: l10n.currency(stats['outstanding_balance']),
                      icon: Icons.account_balance_wallet,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Orders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.orders,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Text(
                          l10n.isArabic ? 'تحديث القائمة' : 'Refresh List'),
                      onPressed: () {
                        ref.invalidate(ordersProvider);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const RecentOrdersList(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.isArabic ? 'إعادة المحاولة' : 'Retry'),
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecentOrdersList extends ConsumerWidget {
  const RecentOrdersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(ordersProvider);

    return ordersAsync.when(
      data: (orders) {
        final recentOrders = orders.take(5).toList();
        if (recentOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(l10n.noData),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newOrder),
                    onPressed: () {
                      // Navigate to orders screen
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentOrders.length,
          itemBuilder: (context, index) {
            final order = recentOrders[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(order.status),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: Colors.white,
                  ),
                ),
                title: Text(order.laptopType),
                subtitle: Text(
                    l10n.isArabic ? order.status.nameAr : order.status.nameEn),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.currency(order.totalCost),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (order.remainingAmount > 0)
                      Text(
                        l10n.currency(order.remainingAmount),
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          children: [
            Text('Error: $error'),
            TextButton(
              onPressed: () => ref.invalidate(ordersProvider),
              child: Text(l10n.isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.teal;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.inProgress:
        return Icons.build;
      case OrderStatus.completed:
        return Icons.done;
      case OrderStatus.delivered:
        return Icons.check_circle;
    }
  }
}
