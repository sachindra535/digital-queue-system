import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final player = AudioPlayer();
  final Set<String> _deliveredOrders = {}; // ✅ To avoid repeating beeps

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _playBeepAndPopup() async {
    await player.play(AssetSource('sounds/beep.mp3'));
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("🎉 Order Delivered"),
          content: const Text("Your order has been marked as delivered!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = user?.email ?? "guest_user";

    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Your Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🩶 Removed `.orderBy()` to fix Firestore index error
        stream: firestore.collectionGroup('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['user'] == userEmail;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("😕 No active orders found."));
          }

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'waiting';
            final id = doc.id;

            // ✅ When admin marks as delivered
            if (status == 'delivered' && !_deliveredOrders.contains(id)) {
              _deliveredOrders.add(id);
              _playBeepAndPopup();
            }
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final token = data['token'] ?? '-';
              final status = data['status'] ?? 'waiting';
              final hotel = data['hotel'] ?? 'Unknown';
              final total = data['total'] ?? 0;

              Color statusColor;
              switch (status) {
                case 'delivered':
                  statusColor = Colors.green;
                  break;
                case 'in-progress':
                  statusColor = Colors.orange;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Text(
                      "#$token",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(hotel,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${status.toUpperCase()}",
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600)),
                      Text("Total: ₹$total"),
                      const SizedBox(height: 4),
                      Text(
                        "Items: ${(data['items'] as List)
                            .map((e) => e['name'])
                            .join(', ')}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
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
