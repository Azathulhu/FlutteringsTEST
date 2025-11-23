import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'my_game.dart';

class GameScreen extends StatefulWidget {
  final int sublevelId;
  GameScreen({required this.sublevelId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late MyGame _game;

  @override
  void initState() {
    super.initState();
    _game = MyGame(sublevelId: widget.sublevelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          Positioned(
            left: 20,
            bottom: 50,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left, size: 50),
                  onPressed: () => _game.moveLeft(),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.arrow_right, size: 50),
                  onPressed: () => _game.moveRight(),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 50,
            child: IconButton(
              icon: Icon(Icons.arrow_upward, size: 50),
              onPressed: () => _game.jump(),
            ),
          ),
        ],
      ),
    );
  }
}
