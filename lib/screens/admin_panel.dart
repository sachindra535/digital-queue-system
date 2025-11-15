import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  // Normalize hotel names to match Firestore docs
  String normalizeName(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  // Update order status in Firestore
  Future<void> updateStatus(String hotelId, String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('queues')
        .doc(hotelId)
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != "admin@gmail.com") {
      // 🚫 Access restriction
      return const Scaffold(
        body: Center(
          child: Text(
            "🚫 Access Denied — Admins Only",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛠 Admin Panel"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text("📭 No active orders found."));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final hotel = data['hotel'] ?? 'Unknown';
              final token = data['token'] ?? '-';
              final user = data['user'] ?? 'Guest';
              final total = data['total'] ?? 0;
              final status = data['status'] ?? 'waiting';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: status == 'delivered'
                        ? Colors.green
                        : status == 'in-progress'
                            ? Colors.orange
                            : Colors.grey,
                    child: Text(
                      "$token",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text("Hotel: $hotel"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User: $user"),
                      Text("Total: ₹$total"),
                      const SizedBox(height: 4),
                      Text(
                        "Items: ${(data['items'] as List).map((e) => e['name']).join(', ')}",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'waiting', child: Text("Waiting")),
                      DropdownMenuItem(value: 'in-progress', child: Text("In Progress")),
                      DropdownMenuItem(value: 'delivered', child: Text("Delivered")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        updateStatus(
                          normalizeName(hotel),
                          doc.id,
                          value,
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
