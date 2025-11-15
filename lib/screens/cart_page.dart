// lib/screens/cart_page.dart
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  final String hotelName;
  final List<Map<String, dynamic>> cartItems;

  const CartPage({
    super.key,
    required this.hotelName,
    required this.cartItems,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<Map<String, dynamic>> _cart;

  @override
  void initState() {
    super.initState();
    // make a local mutable copy
    _cart = List<Map<String, dynamic>>.from(widget.cartItems);
  }

  // Always return the current cart when popping
  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_cart);
    return false; // we've handled the pop
  }

  void _removeItem(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  // Confirm order just returns the cart (MenuPage will proceed to place order)
  void _confirmOrder() {
    Navigator.of(context).pop(_cart); // return updated cart to MenuPage
  }

  @override
  Widget build(BuildContext context) {
    final total = _cart.fold<int>(0, (s, it) => s + ((it['price'] ?? 0) as int));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.hotelName} - Cart"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onWillPop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                _clearCart();
              },
            ),
          ],
        ),
        body: _cart.isEmpty
            ? const Center(child: Text("🛒 Your cart is empty"))
            : ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, i) {
                  final item = _cart[i];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(item['name'] ?? 'Unnamed'),
                      subtitle: Text("₹${item['price'] ?? 0}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(i),
                      ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: ₹$total",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _confirmOrder,
                icon: const Icon(Icons.check),
                label: const Text("Done"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
