import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../flame/player_game.dart';
import '../flame/controls_overlay.dart';
import '../services/input_service.dart';

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
    final inputService = InputService();

    final game = PlayerGame(
      levelBackground: subLevel['background_image'],
      characterData: character,
      inputService: inputService,
    );

    return GameWidget(
      game: game,
      overlayBuilderMap: {
        'ControlsOverlay': (_, game) => ControlsOverlay(inputService: inputService),
      },
    );
  }
}
