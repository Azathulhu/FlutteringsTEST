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
    // Apply horizontal movement
    character.moveHorizontally(tiltX, dt, screenWidth);
  
    // Save previous Y to detect top collisions
    double prevY = character.y;
  
    // Apply gravity
    character.vy += gravity;
    character.y += character.vy;
  
    // Platform collision (top only)
    for (var platform in platforms) {
      bool wasAbove = prevY + character.height <= platform.y;
      bool isBelow = character.y + character.height >= platform.y;
      bool horizontallyOverlapping =
          character.x + character.width >= platform.x &&
          character.x <= platform.x + platform.width;
  
      if (wasAbove && isBelow && horizontallyOverlapping && character.vy > 0) {
        character.y = platform.y - character.height; // place on top
        character.jump(); // bounce
        break; // only bounce on one platform per frame
      }
    }
  
    // Scroll screen up
    if (character.y < screenHeight / 2) {
      double offset = screenHeight / 2 - character.y;
      character.y = screenHeight / 2;
      for (var platform in platforms) {
        platform.y += offset;
      }
    }
  
    // Remove platforms below screen
    platforms.removeWhere((p) => p.y > screenHeight);
  
    // Generate new platforms above
    while (platforms.length < 10) {
      double lastY = platforms.isEmpty
          ? screenHeight - 50
          : platforms.map((p) => p.y).reduce(min);
      double newY = lastY - random.nextInt(150) - 80;
      double newX = random.nextDouble() * (screenWidth - 120); // default width
      platforms.add(Platform(x: newX, y: newY, width: 120, height: 20));
    }
  }

  /// Update world per frame
  /// [tiltX] is horizontal input from accelerometer
  /*void update(double tiltX) {
    // Apply horizontal movement
    character.moveHorizontally(tiltX, screenWidth);

    // Save previous Y to detect top collisions
    double prevY = character.y;

    // Apply gravity
    character.vy += gravity;
    character.y += character.vy;

    // Platform collision (top only)
    for (var platform in platforms) {
      bool wasAbove = prevY + character.height <= platform.y;
      bool isBelow = character.y + character.height >= platform.y;
      bool horizontallyOverlapping =
          character.x + character.width >= platform.x &&
          character.x <= platform.x + platform.width;

      if (wasAbove && isBelow && horizontallyOverlapping && character.vy > 0) {
        character.y = platform.y - character.height; // place on top
        character.jump(); // bounce
        break; // only bounce on one platform per frame
      }
    }

    // Scroll screen up
    if (character.y < screenHeight / 2) {
      double offset = screenHeight / 2 - character.y;
      character.y = screenHeight / 2;
      for (var platform in platforms) {
        platform.y += offset;
      }
    }

    // Remove platforms below screen
    platforms.removeWhere((p) => p.y > screenHeight);

    // Generate new platforms above
    while (platforms.length < 10) {
      double lastY = platforms.isEmpty
          ? screenHeight - 50
          : platforms.map((p) => p.y).reduce(min);
      double newY = lastY - random.nextInt(150) - 80;
      double newX = random.nextDouble() * (screenWidth - 120); // default width
      platforms.add(Platform(x: newX, y: newY, width: 120, height: 20));
    }
  }*/
}
