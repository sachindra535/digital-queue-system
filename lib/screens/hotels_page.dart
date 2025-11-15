import 'package:flutter/material.dart';
import 'package:myapp/screens/menu_page.dart';

class HotelsPage extends StatelessWidget {
  const HotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hotels = ["McDonald's", "KFC", "Popeyes"];

    return Scaffold(
      appBar: AppBar(title: const Text("Hotels")),
      body: ListView.builder(
        itemCount: hotels.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(hotels[index]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuPage(hotelName: hotels[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
