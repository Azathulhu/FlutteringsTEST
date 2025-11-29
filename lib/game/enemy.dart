import 'package:flutter/material.dart';
import 'character.dart';
import 'dart:math';

class Enemy {
  double x;
  double y;
  final double width;
  final double height;
  double vx = 0;
  double vy = 0;

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
  double orbitCounter = 0;

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
  void update(Character character, {double deltaTime = 0.016}) {
    if (behavior['type'] == 'hunter') {
      _hunterBehavior(character, deltaTime: deltaTime);
    }
  }

  void _hunterBehavior(Character character, {double deltaTime = 0.016}) {
    final detectDistance = (behavior['detect_distance'] ?? 300).toDouble();
    final orbitSpeed = (behavior['orbit_speed'] ?? 0.05).toDouble();
    final orbitRadius = (behavior['orbit_radius'] ?? 120).toDouble();
    final rushSpeed = (behavior['rush_speed'] ?? speed).toDouble();

    final dx = character.x - x;
    final dy = character.y - y;
    final distance = sqrt(dx * dx + dy * dy);

    if (!isRushing && distance < detectDistance) {
      // Orbit around character
      orbitAngle += orbitSpeed;
      orbitCounter += orbitSpeed;

      x = character.x + orbitRadius * cos(orbitAngle);
      y = character.y + orbitRadius * sin(orbitAngle);

      // After one full rotation, start rush
      if (orbitCounter >= 2 * pi) {
        isRushing = true;
      }
    } else if (isRushing) {
      // Rush directly toward character
      final angle = atan2(dy, dx);
      vx = rushSpeed * cos(angle);
      vy = rushSpeed * sin(angle);

      x += vx * deltaTime;
      y += vy * deltaTime;
    }
  }

  /// Widget for rendering
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
