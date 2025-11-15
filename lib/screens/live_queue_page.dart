import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveQueuePage extends StatelessWidget {
  final String hotelName;
  const LiveQueuePage({super.key, required this.hotelName});

  String normalizeName(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  @override
  Widget build(BuildContext context) {
    final normalizedHotel = normalizeName(hotelName);
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Live Queue"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('queues')
            .doc(normalizedHotel)
            .collection('orders')
            // 🔹 removed orderBy (no index needed)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("❌ Error: ${snapshot.error}"),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("🕓 No active orders yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final token = data['token'] ?? '-';
              final user = data['user'] ?? 'Guest';
              final status = data['status'] ?? 'waiting';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text("$token"),
                  ),
                  title: Text("User: $user"),
                  subtitle: Text("Status: $status"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
