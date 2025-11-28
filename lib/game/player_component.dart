import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import '../services/character_service.dart';
import 'my_platformer_game.dart';

class PlayerComponent extends SpriteAnimationComponent
    with HasGameRef<MyPlatformerGame>, KeyboardHandler {
  final Map<String, dynamic> characterData;

  // Configurable stats
  double speed;
  double jumpStrength;
  double gravity;
  double health;

  bool onGround = false;
  Vector2 velocity = Vector2.zero();

  PlayerComponent({required this.characterData})
      : speed = characterData['speed'] ?? 200,
        jumpStrength = characterData['jump'] ?? 300,
        gravity = characterData['gravity'] ?? 800,
        health = characterData['health'] ?? 100,
        super(size: Vector2(64, 64));

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(characterData['sprite_path']);
    position = Vector2(100, 100);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply gravity
    velocity.y += gravity * dt;

    // Move player
    position += velocity * dt;

    // Simple floor collision
    final platforms = gameRef.children.whereType<PlatformComponent>();
    for (var platform in platforms) {
      if (position.y + size.y >= platform.position.y &&
          position.x + size.x > platform.position.x &&
          position.x < platform.position.x + platform.size.x) {
        position.y = platform.position.y - size.y;
        velocity.y = 0;
        onGround = true;
      }
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      velocity.x = -speed;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      velocity.x = speed;
    } else {
      velocity.x = 0;
    }

    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) && onGround) {
      velocity.y = -jumpStrength;
      onGround = false;
    }

    return true;
  }
}
