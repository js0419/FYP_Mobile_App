import 'package:flutter/material.dart';
import '../screens/shop/home.dart';
import '../screens/shop/product.dart';
import '../screens/shop/cart.dart';
import '../screens/profile/profile.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context); // Close the drawer first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _openNamedRoute(BuildContext context, String routeName, String pageName) {
    Navigator.pop(context); // Close the drawer first
    try {
      Navigator.pushNamed(context, routeName);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$pageName route not found.'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'MENU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.black),
            title: const Text('HOME'),
            onTap: () => _navigateTo(context, const HomeScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined, color: Colors.black),
            title: const Text('PRODUCT PAGE'),
            onTap: () => _navigateTo(context, const ProductsPage()),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.black),
            title: const Text('ABOUT US PAGE'),
            onTap: () => _openNamedRoute(context, '/about', 'About Us'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.black),
            title: const Text('FAQ PAGE'),
            onTap: () => _openNamedRoute(context, '/faq', 'FAQ'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            title: const Text('CART PAGE'),
            onTap: () => _navigateTo(context, const CartScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.black),
            title: const Text('PROFILE PAGE'),
            onTap: () => _navigateTo(context, const ProfileScreen()),
          ),
        ],
      ),
    );
  }
}