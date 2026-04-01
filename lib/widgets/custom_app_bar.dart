import 'package:flutter/material.dart';
import '../screens/shop/home.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      
      // Make the Title/Logo clickable
      title: GestureDetector(
        onTap: () {
          // Navigate to Home Page and clear previous page history
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        },
        child: Row(
          children: const [
            Icon(Icons.shopping_bag, color: Colors.black), 
            SizedBox(width: 8),
            Text(
              'K&P', 
              style: TextStyle(
                color: Colors.black, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      
      // Right top corner icons
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () {
            // TODO: Navigate to Cart
          },
        ),
        // Profile Picture with Dropdown
        PopupMenuButton<String>(
          offset: const Offset(0, 45),
          icon: const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=User&background=random'),
          ),
          onSelected: (String value) {
            switch (value) {
              case 'profile':
                print('Navigate to Profile');
                break;
              case 'login':
                print('Navigate to Login');
                break;
              case 'logout':
                print('Perform Logout');
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'profile', child: Text('Profile')),
            const PopupMenuItem<String>(value: 'login', child: Text('Login')),
            const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}