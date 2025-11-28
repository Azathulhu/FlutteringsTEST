import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

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

// Simple Flame game with a movable square
class SimpleMovingSquareGame extends FlameGame
    with KeyboardEvents, HasGameRef<SimpleMovingSquareGame> {
  late SquareComponent square;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Add a square in the middle
    square = SquareComponent()
      ..position = Vector2(size.x / 2 - 25, size.y / 2 - 25)
      ..size = Vector2(50, 50)
      ..paint = Paint()..color = Colors.blue;
    add(square);
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final step = 10.0;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      square.position.y -= step;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      square.position.y += step;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      square.position.x -= step;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      square.position.x += step;
    }
    return KeyEventResult.handled;
  }
}

// Simple square component
class SquareComponent extends PositionComponent {
  late Paint paint;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
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
