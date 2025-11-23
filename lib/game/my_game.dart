import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame {
  final int sublevelId;
  final double scrollSpeed = 80;

  MyGame({required this.sublevelId});

  late final Random _rng;

  @override
  Future<void> onLoad() async {
    _rng = Random();

    // Correct experimental viewport
    camera.viewport = FixedResolutionViewport(Vector2(360, 640));

    // Add world elements
    add(_Background());
    add(_ObstacleSpawner());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Correct camera movement API
    camera.viewfinder.moveBy(Vector2(0, -scrollSpeed * dt));
  }
}

class _Background extends RectangleComponent {
  _Background()
      : super(
          size: Vector2(360, 2000),
          paint: Paint()..color = Colors.lightBlueAccent,
        );

  @override
  Future<void> onLoad() async {
    position = Vector2(0, -1400);
  }
}

class _ObstacleSpawner extends Component with HasGameRef<MyGame> {
  double timer = 0;

  @override
  void update(double dt) {
    super.update(dt);

    timer += dt;

    if (timer > 1.2) {
      timer = 0;
      spawnObstacle();
    }
  }

  void spawnObstacle() {
    final camY = gameRef.camera.viewfinder.position.y; // fixed

    final spawnY = camY - 200;

    final x = 20 + gameRef._rng.nextDouble() * 280;

    gameRef.add(
      _Obstacle(position: Vector2(x, spawnY)),
    );
  }
}

class _Obstacle extends RectangleComponent with HasGameRef<MyGame> {
  double moveSpeed = 100;

  _Obstacle({required Vector2 position})
      : super(
          position: position,
          size: Vector2(50, 50),
          paint: Paint()..color = Colors.brown,
        );

  @override
  void update(double dt) {
    super.update(dt);

    position.y += moveSpeed * dt;

    final camY = gameRef.camera.viewfinder.position.y; // fixed

    if (position.y > camY + 800) {
      removeFromParent();
    }
  }
}
