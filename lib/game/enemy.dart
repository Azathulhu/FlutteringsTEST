import 'package:flutter/material.dart';
import 'character.dart';

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

  /// Update per frame
  void update(Character character) {
    if (behavior['type'] == 'hunter') {
      _hunterBehavior(character);
    }
  }

  void _hunterBehavior(Character character) {
    final detectDistance = behavior['detect_distance']?.toDouble() ?? 300;
    final dx = character.x - x;
    final dy = character.y - y;
    final distance = (dx * dx + dy * dy).sqrt();

    if (!isRushing && distance < detectDistance) {
      // Start orbit
      orbitAngle += behavior['orbit_speed']?.toDouble() ?? 0.02;
      final radius = behavior['orbit_radius']?.toDouble() ?? 120;
      x = character.x + radius * cos(orbitAngle);
      y = character.y + radius * sin(orbitAngle);

      // After a few rotations, rush
      if (orbitAngle > 2 * 3.1415) {
        isRushing = true;
      }
    } else if (isRushing) {
      // Rush toward character
      final rushSpeed = behavior['rush_speed']?.toDouble() ?? speed;
      final angle = atan2(dy, dx);
      vx = rushSpeed * cos(angle);
      vy = rushSpeed * sin(angle);
      x += vx * 0.016; // assuming 60fps
      y += vy * 0.016;
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

  /// Apply damage to character
  void dealDamage(Character character) {
    character.currentHealth -= damage;
    if (character.currentHealth < 0) character.currentHealth = 0;
  }
}
