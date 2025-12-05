import 'package:flutter/material.dart';

class Character {
  double x;
  double y;
  final double width;
  final double height;
  double vy = 0;

  final double jumpStrength;
  final double horizontalSpeedMultiplier;
  final String spritePath;

  // Health properties
  int maxHealth;
  int currentHealth;

  // Track facing direction: true = right, false = left
  bool facingRight = true;

  Character({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.jumpStrength,
    required this.spritePath,
    this.horizontalSpeedMultiplier = 2.0,
    this.maxHealth = 100,
    int? currentHealth, // optional, defaults to maxHealth
  }) : currentHealth = currentHealth ?? maxHealth;

  /// Apply horizontal movement from tilt input
  void moveHorizontally(double tiltX, double screenWidth) {
    x += tiltX * horizontalSpeedMultiplier;
    x = x.clamp(0, screenWidth - width);

    // Update facing direction based on tilt
    if (tiltX > 0.1) {
      facingRight = true;
    } else if (tiltX < -0.1) {
      facingRight = false;
    }
  }

  void jump() {
    vy = -jumpStrength;
  }

  /// Reduce health when taking damage
  void takeDamage(int damage) {
    currentHealth -= damage;
    if (currentHealth < 0) currentHealth = 0;
  }

  /// Reset health to full
  void resetHealth() {
    currentHealth = maxHealth;
  }

  //physics
  void updatePhysics(double dt, double tiltInput) {
    // Horizontal movement
    x += tiltInput * horizontalSpeedMultiplier * dt * 200; // adjust 200 for speed
  
    // Vertical movement
    y += vy * dt;
  
    // Gravity
    vy += 1000 * dt; // tweak as needed
  
    // Clamp inside screen
    x = x.clamp(0, 1920 - width); // assuming 1920 screen width
    y = y.clamp(0, 1080 - height); // assuming 1080 screen height
  }


  /// Widget to render the character with pixel-perfect scaling
  Widget buildWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(facingRight ? 1.0 : -1.0, 1.0),
        child: Image.asset(
          "assets/character sprites/$spritePath",
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }

  /*Widget buildWithHealthBar() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Health bar
        Positioned(
          top: -10,
          child: Container(
            width: width,
            height: 8,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(2),
              color: Colors.red.withOpacity(0.3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: currentHealth / maxHealth,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        buildWidget(),
      ],
    );
  }*/
}

/*import 'package:flutter/material.dart';

class Character {
  double x;
  double y;
  final double width;
  final double height;
  double vy = 0;

  final double jumpStrength;
  final double horizontalSpeedMultiplier;
  final String spritePath;

  Character({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.jumpStrength,
    required this.spritePath,
    this.horizontalSpeedMultiplier = 2.0,
  });

  /// Apply horizontal movement from tilt input
  void moveHorizontally(double tiltX, double screenWidth) {
    x += tiltX * horizontalSpeedMultiplier;
    x = x.clamp(0, screenWidth - width);
  }

  /// Bounce on a platform
  void jump() {
    vy = -jumpStrength;
  }

  /// Widget to render the character
  Widget buildWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        "assets/character sprites/$spritePath",
        fit: BoxFit.contain,
      ),
    );
  }
}*/
