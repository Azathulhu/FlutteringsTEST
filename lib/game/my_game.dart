import 'package:flame/game.dart';
import 'package:flame/components.dart';

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    add(
      TextComponent(
        text: "Flutterings!",
        position: Vector2(50, 50),
      ),
    );
  }
}

