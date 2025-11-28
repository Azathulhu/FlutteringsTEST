import 'package:flutter/material.dart';
import '../flame/player_game.dart';
import 'package:flame/game.dart';

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;
  final Map<String, dynamic> character;

  GamePage({
    required this.level,
    required this.subLevel,
    required this.character,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late PlayerGame game;

  @override
  void initState() {
    super.initState();
    game = PlayerGame(
      backgroundImage: widget.subLevel['background_image'],
      character: widget.character,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: game),
          Positioned(
            left: 20,
            bottom: 50,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    game.player.moveLeft(1 / 60); // basic step per frame
                  },
                  child: Icon(Icons.arrow_left),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    game.player.moveRight(1 / 60);
                  },
                  child: Icon(Icons.arrow_right),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 50,
            child: ElevatedButton(
              onPressed: () {
                game.player.jump();
              },
              child: Icon(Icons.arrow_upward),
            ),
          ),
        ],
      ),
    );
  }
}
