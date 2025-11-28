import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'player_component.dart';
import '../services/input_service.dart';

class PlayerGame extends BaseGame with HasWidgetsOverlay {
  final String levelBackground;
  final Map<String, dynamic> characterData;

  late PlayerComponent player;
  late InputService inputService;

  PlayerGame({required this.levelBackground, required this.characterData}) {
    inputService = InputService();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background
    final bg = SpriteComponent()
      ..sprite = await loadSprite('background/$levelBackground')
      ..size = size;
    add(bg);

    // Player
    player = PlayerComponent(characterData: characterData, inputService: inputService)
      ..x = size.x / 2
      ..y = 100;
    add(player);

    // Add controls overlay
    overlays.add('ControlsOverlay');
  }
}
