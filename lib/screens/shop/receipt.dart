import 'package:flutter/material.dart';
import 'home.dart'; // Adjust path to your HomeScreen

class ReceiptScreen extends StatelessWidget {
  final String orderId;

  const ReceiptScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text('PAYMENT SUCCESSFUL!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              const Text('Your order has been confirmed and is being processed.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(8)),
                child: Text('Order ID:\n$orderId', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('CONTINUE SHOPPING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}