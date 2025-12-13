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

  int maxHealth;
  int currentHealth;

  bool facingRight = true;

  Character({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.jumpStrength,
    required this.spritePath,
    required this.horizontalSpeedMultiplier,
    required this.maxHealth,
    int? currentHealth,
  }) : currentHealth = currentHealth ?? maxHealth;

  void moveHorizontally(double tiltX, double dt, double screenWidth) {
    x += tiltX * horizontalSpeedMultiplier * dt;
    x = x.clamp(0, screenWidth - width);

    if (tiltX > 0.1) facingRight = true;
    else if (tiltX < -0.1) facingRight = false;
  }

  void jump() {
    vy = -jumpStrength;
  }

  void takeDamage(int damage) {
    currentHealth -= damage;
    if (currentHealth < 0) currentHealth = 0;
  }

  void resetHealth() {
    currentHealth = maxHealth;
  }

  void updatePhysics(double dt, double tiltInput, double gravity, double screenWidth, double screenHeight) {
    moveHorizontally(tiltInput, dt, screenWidth);
    y += vy * dt;
    vy += gravity * dt;

    x = x.clamp(0, screenWidth - width);
    y = y.clamp(0, screenHeight - height);
  }

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
}
