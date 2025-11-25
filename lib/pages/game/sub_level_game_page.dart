import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class SubLevelGamePage extends StatelessWidget {
  const SubLevelGamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Minimal Flame game, just empty for now
    final game = FlameGame();

    return Scaffold(
      body: Stack(
        children: [
          // Flutter renders the forest background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/forest.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          // Flame game renders on top
          Positioned.fill(
            child: GameWidget(
              game: game,
              backgroundBuilder: (_) => Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
