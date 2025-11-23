import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame {
  late Player player;
  final Random rng = Random();
  double scrollSpeed = 100; // pixels per second

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(Vector2(360, 640));

    // Add player
    player = Player()
      ..position = Vector2(size.x / 2 - 16, size.y - 80);
    add(player);

    // Add starting platform
    add(
      PlatformComponent(
        size: Vector2(120, 20),
        position: Vector2(size.x / 2 - 60, size.y - 40),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Screen scrolls upward
    camera.translate(0, -scrollSpeed * dt);

    // Spawn new platforms
    if (children.whereType<PlatformComponent>().length < 6) {
      spawnPlatform();
    }
  }

  void spawnPlatform() {
    final x = rng.nextDouble() * (size.x - 100);
    final y = camera.position.y - 200; // above view

    add(
      PlatformComponent(
        size: Vector2(100, 20),
        position: Vector2(x, y),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Player component
// -----------------------------------------------------------------------------

class Player extends SpriteComponent with HasGameRef<MyGame>, KeyboardHandler {
  double speed = 150;
  double gravity = 400;
  double velocityY = 0;

  Player()
      : super(
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite("character_idle.png");
  }

  @override
  void update(double dt) {
    super.update(dt);

    // gravity
    velocityY += gravity * dt;
    position.y += velocityY * dt;

    // left / right boundaries
    if (position.x < 0) position.x = 0;
    if (position.x + width > gameRef.size.x) {
      position.x = gameRef.size.x - width;
    }
  }

  void moveLeft() {
    position.x -= speed * gameRef.dt;
  }

  void moveRight() {
    position.x += speed * gameRef.dt;
  }

  void jump() {
    velocityY = -250;
  }
}

// -----------------------------------------------------------------------------
// Platforms
// -----------------------------------------------------------------------------

class PlatformComponent extends RectangleComponent {
  PlatformComponent({
    required Vector2 size,
    required Vector2 position,
  }) : super(
          size: size,
          position: position,
          paint: Paint()..color = Colors.brown,
        );
}
