import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'player_component.dart';
import 'platform_component.dart';

class MyPlatformerGame extends FlameGame with HasTappables, HasDraggables {
  final String backgroundImageAsset;
  final Map<String, dynamic> characterConfig;

  late PlayerComponent player;
  late SpriteComponent background;

  MyPlatformerGame({
    required this.backgroundImageAsset,
    required this.characterConfig,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // load background sprite (we assume preloaded, but load if needed)
    final bgImageName = backgroundImageAsset.split('/').last;
    final bg = await images.load(bgImageName);
    background = SpriteComponent()
      ..sprite = Sprite(bg)
      ..size = size
      ..position = Vector2.zero()
      ..anchor = Anchor.topLeft;
    add(background);

    // Add a simple ground platform across bottom
    final ground = PlatformComponent(
      position: Vector2(0, size.y - 72),
      size: Vector2(size.x, 72),
    );
    add(ground);

    // Add a few floating platforms for testing
    add(PlatformComponent(position: Vector2(50, size.y - 200), size: Vector2(150, 24)));
    add(PlatformComponent(position: Vector2(300, size.y - 300), size: Vector2(180, 24)));

    // Add player near top-left
    player = PlayerComponent(
      position: Vector2(100, size.y - 400),
      size: Vector2(48, 64),
      speed: characterConfig['speed'] as double,
      jumpStrength: characterConfig['jump_strength'] as double,
      maxHealth: characterConfig['max_health'] as int,
      spritePath: characterConfig['sprite_path'] as String,
    );

    add(player);
    camera.followComponent(player, worldBounds: Rect.fromLTWH(0, 0, size.x, size.y));
  }
}
