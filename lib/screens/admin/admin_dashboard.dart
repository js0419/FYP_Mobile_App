import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_products.dart';
import 'admin_orders.dart';
import 'admin_users.dart';
import 'admin_payments.dart';
import '../../services/auth_service.dart';
import '../auth/login.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isAdmin = false;

  Map<String, dynamic> _stats = {
    'users': 0,
    'products': 0,
    'orders': 0,
    'revenue': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        if (!mounted) return;
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
        return;
      }

      final stats = await _adminService.getDashboardStats();

      if (!mounted) return;
      setState(() {
        _isAdmin = true;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFF5F5F5),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, Widget page) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          ).then((_) => _loadDashboard());
        },
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await _authService.logout();

                  if (!mounted) return;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                        (route) => false,
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ADMIN DASHBOARD'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Access denied. This account is not admin.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('ADMIN DASHBOARD'),
        backgroundColor: const Color(0xFFF8F8F8),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard(
              'TOTAL USERS',
              '${_stats['users']}',
              Icons.people_outline,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'TOTAL PRODUCTS',
              '${_stats['products']}',
              Icons.storefront_outlined,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'TOTAL ORDERS',
              '${_stats['orders']}',
              Icons.shopping_bag_outlined,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'TOTAL REVENUE',
              'RM${(_stats['revenue'] ?? 0).toStringAsFixed(2)}',
              Icons.payments_outlined,
            ),
            const SizedBox(height: 22),
            _buildMenuButton(
              'MANAGE PRODUCTS',
              Icons.inventory_2_outlined,
              const AdminProductsPage(),
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              'MANAGE ORDERS',
              Icons.receipt_long_outlined,
              const AdminOrdersPage(),
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              'MANAGE USERS',
              Icons.people_alt_outlined,
              const AdminUsersPage(),
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              'MANAGE PAYMENTS',
              Icons.account_balance_wallet_outlined,
              const AdminPaymentsPage(),
            ),
          ],
        ),
      ),
    );
  }
}