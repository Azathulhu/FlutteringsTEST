import 'package:flutter/material.dart';
import 'character_selection_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CharacterSelectionPage()),
            );
          },
          child: Text("Select Character"),
        ),
      ),
    );
  }
}
