import 'package:flutter/material.dart';
import 'character.dart';
import 'dart:math';

class Enemy {
  double x;
  double y;
  final double width;
  final double height;
  double vy = 0;
  double vx = 0;

  final String name;
  final String spritePath;
  int maxHealth;
  int currentHealth;
  int damage;
  double speed;

  // JSON behavior
  final Map<String, dynamic> behavior;

  bool isRushing = false;
  double orbitAngle = 0;
  bool hasEnteredScreen = false;

  Enemy({
    required this.x,
    required this.y,
    this.width = 60,
    this.height = 60,
    required this.name,
    required this.spritePath,
    required this.maxHealth,
    int? currentHealth,
    required this.damage,
    required this.speed,
    required this.behavior,
  }) : currentHealth = currentHealth ?? maxHealth;

  void update(Character character, double deltaTime, double screenWidth, double screenHeight) {
    // Step 1: slowly drop from spawn above screen
    if (!hasEnteredScreen) {
      vy = behavior['spawn_fall_speed']?.toDouble() ?? 50; // pixels/sec
      y += vy * deltaTime;

      if (y + height >= 0) {
        hasEnteredScreen = true;
        vy = 0;
      }
      return;
    }

    // Step 2: Apply Hunter AI after entering screen
    if (behavior['type'] == 'hunter') {
      _hunterBehavior(character, deltaTime);
    }
  }

  void _hunterBehavior(Character character, double deltaTime) {
    final detectDistance = behavior['detect_distance']?.toDouble() ?? 300;
    final dx = character.x - x;
    final dy = character.y - y;
    final distance = sqrt(dx * dx + dy * dy);

    if (!isRushing && distance < detectDistance) {
      // Roam independently in a small orbit around original spawn
      orbitAngle += (behavior['orbit_speed']?.toDouble() ?? 1.0) * deltaTime;
      final radius = behavior['orbit_radius']?.toDouble() ?? 120;
      x += radius * cos(orbitAngle) * deltaTime;
      y += radius * sin(orbitAngle) * deltaTime;

      if (orbitAngle > 2 * pi) isRushing = true;
    } else if (isRushing) {
      // Rush toward character
      final rushSpeed = behavior['rush_speed']?.toDouble() ?? speed;
      final angle = atan2(dy, dx);
      vx = rushSpeed * cos(angle);
      vy = rushSpeed * sin(angle);

      x += vx * deltaTime;
      y += vy * deltaTime;
    }
  }

  Widget buildWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        "assets/enemies/$spritePath",
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
  }

  void dealDamage(Character character) {
    character.currentHealth -= damage;
    if (character.currentHealth < 0) character.currentHealth = 0;
  }
}
