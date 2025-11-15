import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "guest_user";
    const adminEmail = "admin@gmail.com"; // ✅ Your admin email

    return Scaffold(
      appBar: AppBar(
        title: const Text("🏠 Home Page"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Welcome, $userEmail 👋",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/hotels'),
              child: const Text("🍔 View Hotels"),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/colleges'),
              child: const Text("🎓 College Queues"),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/orders'),
              child: const Text("📦 My Orders"),
            ),
            const SizedBox(height: 12),

            // ✅ Admin Panel button (only visible to admin)
            if (userEmail == adminEmail)
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin'),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("🛠 Admin Panel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
