import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class MyGameScreen extends StatefulWidget {
  final int sublevelId;
  MyGameScreen({required this.sublevelId});

  @override
  State<MyGameScreen> createState() => _MyGameScreenState();
}

class _MyGameScreenState extends State<MyGameScreen> {
  late MyGame _game;

  @override
  void initState() {
    super.initState();
    _game = MyGame(sublevelId: widget.sublevelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          Positioned(
            left: 20,
            bottom: 50,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left, size: 50),
                  onPressed: () => _game.moveLeft(),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right, size: 50),
                  onPressed: () => _game.moveRight(),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 50,
            child: IconButton(
              icon: Icon(Icons.arrow_upward, size: 50),
              onPressed: () => _game.jump(),
            ),
          ),
        ],
      ),
    );
  }
}

class MyGame extends FlameGame with HasCollidables, HasTappables {
  final int sublevelId;

  late SpriteComponent player;
  double playerSpeed = 200;
  double jumpForce = 400;
  bool isJumping = false;

  double scrollSpeed = 50;

  MyGame({required this.sublevelId});

  @override
  Future<void> onLoad() async {
    // TODO: load player sprite based on selected character
    player = SpriteComponent()
      ..size = Vector2(50, 50)
      ..position = Vector2(size.x / 2, size.y - 100);
    add(player);

    // TODO: add initial platform
    add(RectangleComponent()
      ..size = Vector2(100, 20)
      ..position = Vector2(size.x / 2 - 50, size.y - 50)
      ..paint = Paint()..color = Colors.brown);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Scroll the screen upwards
    for (final c in children.whereType<PositionComponent>()) {
      c.position.y -= scrollSpeed * dt;
    }
  }

  void moveLeft() {
    player.position.x -= playerSpeed * 0.016; // simple movement
  }

  void moveRight() {
    player.position.x += playerSpeed * 0.016;
  }

  void jump() {
    if (!isJumping) {
      player.position.y -= jumpForce * 0.016;
      isJumping = true;
    }
  }
}
