import 'dart:math';
import 'character.dart';
import 'platform.dart';

class World {
  final double screenWidth;
  final double screenHeight;
  final Character character;
  final double gravity = 0.8;

  List<Platform> platforms = [];
  Random random = Random();

  World({
    required this.screenWidth,
    required this.screenHeight,
    required this.character,
  });

  void update(double tiltX, double dt) {
    character.moveHorizontally(tiltX, dt, screenWidth);
  
    double prevY = character.y;
  
    character.vy += gravity;
    character.y += character.vy;
  
    for (var platform in platforms) {
      bool wasAbove = prevY + character.height <= platform.y;
      bool isBelow = character.y + character.height >= platform.y;
      bool horizontallyOverlapping =
          character.x + character.width >= platform.x &&
          character.x <= platform.x + platform.width;
  
      if (wasAbove && isBelow && horizontallyOverlapping && character.vy > 0) {
        character.y = platform.y - character.height; 
        character.jump(); 
        break; 
      }
    }
  
    if (character.y < screenHeight / 2) {
      double offset = screenHeight / 2 - character.y;
      character.y = screenHeight / 2;
      for (var platform in platforms) {
        platform.y += offset;
      }
    }
  
    platforms.removeWhere((p) => p.y > screenHeight);
    while (platforms.length < 10) {
      double lastY = platforms.isEmpty
          ? screenHeight - 50
          : platforms.map((p) => p.y).reduce(min);
      double newY = lastY - random.nextInt(150) - 80;
      double newX = random.nextDouble() * (screenWidth - 120); 
      platforms.add(Platform(x: newX, y: newY, width: 120, height: 20));
    }
  }
}
