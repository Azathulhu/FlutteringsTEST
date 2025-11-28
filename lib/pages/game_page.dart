import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';

class GamePage extends StatelessWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/images/background/${level['background_image']}"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Flame game
          GameWidget(
            game: SimpleMovingSquareGame(),
          ),
        ],
      ),
    );
  }
}

// Minimal Flame game with a movable square
class SimpleMovingSquareGame extends FlameGame
    with HasKeyboardHandlerComponents {
  late SquareComponent square;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Add a square
    square = SquareComponent(
      position: Vector2(size.x / 2 - 25, size.y / 2 - 25),
      size: Vector2(50, 50),
    );
    add(square);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<KeyEvent> keysPressed) {
    final step = 10.0;
    // Use event.logicalKey to move
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      square.position.y -= step;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      square.position.y += step;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      square.position.x -= step;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      square.position.x += step;
    }
    return true;
  }
}

// Simple square component
class SquareComponent extends PositionComponent {
  final Paint paint = Paint()..color = Colors.blue;

  SquareComponent({Vector2? position, Vector2? size}) {
    this.position = position ?? Vector2.zero();
    this.size = size ?? Vector2.all(50);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), paint);
  }
}


/*import 'package:flutter/material.dart';

class GamePage extends StatelessWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/background/${level['background_image']}"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text(
            "Sub-Level: ${subLevel['name']}",
            style: TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}*/
