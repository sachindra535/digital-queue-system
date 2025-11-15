import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/screens/cart_page.dart';

class MenuPage extends StatefulWidget {
  final String hotelName;

  const MenuPage({super.key, required this.hotelName});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final List<Map<String, dynamic>> _cart = [];
  int? _lastToken;

  // Normalize hotel names for consistent Firestore key matching
  String normalizeName(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      _cart.add(item);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("🛒 Added ${item['name']}")));
  }

  // ✅ Place order logic (adds to Firestore queue)
  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;

    final user = _auth.currentUser?.email ?? "guest_user";
    final normalizedHotel = normalizeName(widget.hotelName);

    try {
      // Get next token number
      final ordersSnapshot = await firestore
          .collection('queues')
          .doc(normalizedHotel)
          .collection('orders')
          .get();

      final tokenNumber = ordersSnapshot.docs.length + 1;

      // ✅ Add new order with hotel name + email info
      await firestore
          .collection('queues')
          .doc(normalizedHotel)
          .collection('orders')
          .add({
        'token': tokenNumber,
        'user': user,
        'hotel': widget.hotelName,
        'items': List<Map<String, dynamic>>.from(_cart),
        'total': _cart.fold<int>(
            0, (sum, item) => sum + ((item['price'] ?? 0) as int)),
        'status': 'waiting',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear local cart + show confirmation
      setState(() {
        _cart.clear();
        _lastToken = tokenNumber;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("🎟️ Order Confirmed"),
          content: Text("Your token number is: #$tokenNumber"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/orders');
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to place order: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedHotel = normalizeName(widget.hotelName);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.hotelName} Menu"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(
                    hotelName: widget.hotelName,
                    cartItems: List.from(_cart),
                  ),
                ),
              );

              // ✅ Always refresh cart total after returning
              if (updated != null && updated is List<Map<String, dynamic>>) {
                setState(() {
                  _cart
                    ..clear()
                    ..addAll(updated);
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('menuItems').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final hotel = normalizeName(doc['hotel'] ?? '');
            return hotel == normalizedHotel;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("😕 No items available."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  title: Text(data['name'] ?? "Unnamed Item"),
                  subtitle: Text("₹${data['price'] ?? 0}"),
                  trailing: ElevatedButton(
                    onPressed: () => _addToCart({
                      'name': data['name'],
                      'price': data['price'],
                    }),
                    child: const Text("Add"),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _cart.isEmpty
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "🛒 Total: ₹${_cart.fold<int>(
                      0,
                      (sum, item) => sum + ((item['price'] ?? 0) as int),
                    )}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _placeOrder,
                    child: const Text("Confirm Order"),
                  ),
                ],
              ),
            ),
    );
  }
}
