import 'package:flutter/material.dart';

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
      
      // Logo beside the sidebar (hamburger menu is handled automatically by Scaffold)
      title: Row(
        children: const [
          Icon(Icons.shopping_bag, color: Colors.black), 
          SizedBox(width: 8),
          Text(
            'FashionAI', 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      
      // Right top corner icons
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // TODO: Navigate to Wishlist
          },
        ),
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