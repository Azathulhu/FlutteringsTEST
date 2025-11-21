import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class ITGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }
}

void main() {
  final game = ITGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainMenu(game: game),
    ),
  );
}
//sample palang na menu ng game. NOT FINAL
class MainMenu extends StatelessWidget {
  final ITGame game;
  const MainMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FLUTTERINGS!',
              style: TextStyle(color: Colors.white, fontSize: 40),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GameWidget(game: game),
                  ),
                );
              },
              child: const Text('Start Game'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {},
              child: const Text('Options'),
            ),

            ElevatedButton(
              onPressed: () {},
              child: const Text('Options'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {},
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }
}
