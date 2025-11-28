import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player_component.dart';
import 'platform_component.dart';

class MyPlatformerGame extends FlameGame with HasKeyboardHandlerComponents {
  final Map<String, dynamic> characterData;
  late PlayerComponent player;

  MyPlatformerGame({required this.characterData});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add background (placeholder, configurable via Supabase)
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.greenAccent,
    ));

    // Add a simple platform
    add(PlatformComponent(
      position: Vector2(0, size.y - 50),
      size: Vector2(size.x, 50),
    ));

    // Add player
    player = PlayerComponent(characterData: characterData);
    add(player);

    // Set camera to follow player
    camera.followComponent(player,
        worldBounds: Rect.fromLTWH(0, 0, size.x * 2, size.y));
  }
}
