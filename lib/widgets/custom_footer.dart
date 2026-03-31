import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Us
          const Text(
            'About Us',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We are an AI-powered fashion destination bringing you personalized style recommendations. Find your perfect fit with our cutting-edge technology.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 24),

          // Store Location (Map Placeholder)
          const Text(
            'Store Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Google Maps Integration Here', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contact & Socials
          const Text(
            'Contact Us',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.email_outlined, size: 20),
              SizedBox(width: 8),
              Text('support@fashionai.com'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.phone_outlined, size: 20),
              SizedBox(width: 8),
              Text('+1 234 567 8900'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Social Media Links
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.blue),
                onPressed: () { /* TODO: Open FB Link */ },
              ),
              IconButton(
                // Placeholder for IG since it doesn't have a default Material icon
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.purple), 
                onPressed: () { /* TODO: Open IG Link */ },
              ),
            ],
          ),
        ],
      ),
    );
  }
}