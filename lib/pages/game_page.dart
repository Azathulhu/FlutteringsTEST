import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../flame/player_game.dart';

class GamePage extends StatelessWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;
  final Map<String, dynamic> character;

  GamePage({
    required this.level,
    required this.subLevel,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: PlayerGame(
              levelBackground: level['background_image'],
              characterData: character,
            ),
          ),
        ],
      ),
    );
  }
}
