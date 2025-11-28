import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'player_component.dart';
import '../services/input_service.dart';

class PlayerGame extends FlameGame with HasTappables, HasDraggables, HasCollisionDetection {
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
    add(SpriteComponent()
      ..sprite = await loadSprite('background/$levelBackground')
      ..size = size);

    // Player
    player = PlayerComponent(characterData: characterData, inputService: inputService)
      ..position = Vector2(size.x / 2, 100);
    add(player);

    // Add UI buttons
    overlays.add('ControlsOverlay');

    overlays.addEntry(
      'ControlsOverlay',
      (context, game) => ControlsOverlay(inputService: inputService),
    );

  }

  @override
  void update(double dt) {
    super.update(dt);
  }
}
