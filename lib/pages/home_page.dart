import 'package:flutter/material.dart';
import '../game/my_game.dart';
import 'package:flame/game.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: MyGame()),
    );
  }
}

