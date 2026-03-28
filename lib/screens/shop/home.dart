import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_footer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. Reusable Header
      appBar: const CustomAppBar(),
      
      // 2. Sidebar Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text('Categories', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.checkroom),
              title: const Text('Men'),
              onTap: () { /* Filter Men */ },
            ),
            ListTile(
              leading: const Icon(Icons.checkroom),
              title: const Text('Women'),
              onTap: () { /* Filter Women */ },
            ),
          ],
        ),
      ),

      // 3. Scrollable Body + Footer
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- MAIN PAGE CONTENT GOES HERE ---
            Container(
              height: 400,
              alignment: Alignment.center,
              child: const Text(
                'Banner & Product Grid Content',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
            // -----------------------------------

            // 4. Reusable Footer at the bottom
            const CustomFooter(),
          ],
        ),
      ),
    );
  }
}