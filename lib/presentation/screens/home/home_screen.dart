import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../main.dart';
import '../../providers/providers.dart';
import '../customers/customers_screen.dart';
import '../orders/orders_screen.dart';
import '../accessories/accessories_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    final screens = [
      const DashboardTab(),
      const OrdersScreen(),
      const CustomersScreen(),
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
              },
              labelType: NavigationRailLabelType.all,
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.laptop_mac),
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
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      tooltip: l10n.settings,
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

// ===================================================================
// Dashboard Tab Widget
class DashboardTab extends ConsumerWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        automaticallyImplyLeading: false,
      ),
      body: statsAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  l10n.orders,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const RecentOrdersList(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
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
  const RecentOrdersList({Key? key}) : super(key: key);

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
              child: Text(l10n.noData),
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
                subtitle: Text(l10n.isArabic
                    ? order.status.nameAr
                    : order.status.nameEn),
                trailing: Text(l10n.currency(order.remainingAmount)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
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