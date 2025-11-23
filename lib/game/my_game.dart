import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame with HasCollidables, HasTappables {
  final int sublevelId;

  late SpriteComponent player;
  double playerSpeed = 200;
  double jumpForce = 300;
  bool isJumping = false;

  double scrollSpeed = 50;
  double platformGap = 150;

  final List<RectangleComponent> platforms = [];

  MyGame({required this.sublevelId});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Player placeholder (will replace with character sprite)
    player = SpriteComponent()
      ..size = Vector2(50, 50)
      ..position = Vector2(size.x / 2, size.y - 100);
    add(player);

    // Starting platform
    final startPlatform = RectangleComponent()
      ..size = Vector2(100, 20)
      ..position = Vector2(size.x / 2 - 50, size.y - 50)
      ..paint = Paint()..color = Colors.brown;
    add(startPlatform);
    platforms.add(startPlatform);

    // Generate initial platforms
    for (int i = 1; i <= 5; i++) {
      spawnPlatform(size.y - 50 - i * platformGap);
    }
  }

  void spawnPlatform(double y) {
    final x = (size.x - 100) * (0.1 + 0.8 * random.nextDouble());
    final platform = RectangleComponent()
      ..size = Vector2(100, 20)
      ..position = Vector2(x, y)
      ..paint = Paint()..color = Colors.brown;
    add(platform);
    platforms.add(platform);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move everything upward
    for (final c in children.whereType<PositionComponent>()) {
      c.position.y -= scrollSpeed * dt;
    }

    // Check if topmost platform is visible to spawn new
    if (platforms.isNotEmpty) {
      final topY = platforms.map((p) => p.position.y).reduce((a, b) => a < b ? a : b);
      if (topY > 0) {
        spawnPlatform(topY - platformGap);
      }
    }

    // Simple gravity
    if (!isOnPlatform()) {
      player.position.y += 200 * dt; // fall speed
      isJumping = true;
    } else {
      isJumping = false;
    }
  }

  bool isOnPlatform() {
    for (final p in platforms) {
      final px = p.position.x;
      final py = p.position.y;
      if (player.position.y + player.size.y >= py &&
          player.position.y + player.size.y <= py + 20 &&
          player.position.x + player.size.x >= px &&
          player.position.x <= px + 100) {
        // Snap player to platform
        player.position.y = py - player.size.y;
        return true;
      }
    }
    return false;
  }

  void moveLeft() {
    player.position.x -= playerSpeed * 0.016;
    if (player.position.x < 0) player.position.x = 0;
  }

  void moveRight() {
    player.position.x += playerSpeed * 0.016;
    if (player.position.x + player.size.x > size.x) {
      player.position.x = size.x - player.size.x;
    }
  }

  void jump() {
    if (!isJumping) {
      player.position.y -= jumpForce * 0.016;
      isJumping = true;
    }
  }
}
