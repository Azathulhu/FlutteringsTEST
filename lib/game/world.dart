import 'dart:math';
import 'character.dart';
import 'platform.dart';

class World {
  double screenWidth;
  double screenHeight;
  double gravity = 0.5;
  double jumpStrength = 12;
  double scrollThreshold = 0.4;

  Character character;
  List<Platform> platforms = [];
  Random random = Random();

  World({
    required this.screenWidth,
    required this.screenHeight,
    required this.character,
  }) {
    _initFirstPlatform();
  }

  void _initFirstPlatform() {
    double y = screenHeight - 150;
    platforms.add(
      Platform(
        x: screenWidth / 2 - 60,
        y: y,
        width: 120,
      ),
    );
    character.x = platforms[0].x + 120 / 2 - character.width / 2;
    character.y = platforms[0].y - character.height;
  }

  void generatePlatforms() {
    while (platforms.length < 12) {
      double highest = platforms.map((p) => p.y).reduce(min);
      double newY = highest - (140 + random.nextInt(60));
      double newX = random.nextDouble() * (screenWidth - 120);
      platforms.add(Platform(x: newX, y: newY, width: 120));
    }
  }

  void update(double tiltX) {
    // Horizontal
    character.x += tiltX * 2.0;
    character.x = character.x.clamp(0.0, screenWidth - character.width);

    // Vertical
    character.velocityY += gravity;
    character.y += character.velocityY;

    // Collision
    for (var p in platforms) {
      bool falling = character.velocityY > 0;
      bool abovePlatform = character.y + character.height <= p.y;
      bool crossingPlatform = character.y + character.height + character.velocityY >= p.y;
      bool horizontallyAligned =
          character.x + character.width >= p.x && character.x <= p.x + p.width;

      if (falling && abovePlatform && crossingPlatform && horizontallyAligned) {
        character.y = p.y - character.height;
        character.velocityY = -jumpStrength;
        break;
      }
    }

    // Scroll world
    if (character.y < screenHeight * scrollThreshold) {
      double offset = screenHeight * scrollThreshold - character.y;
      character.y = screenHeight * scrollThreshold;
      for (var p in platforms) {
        p.y += offset;
      }
    }

    // Remove offscreen
    platforms.removeWhere((p) => p.y > screenHeight);

    // Generate new
    generatePlatforms();
  }
}
