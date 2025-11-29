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
}
