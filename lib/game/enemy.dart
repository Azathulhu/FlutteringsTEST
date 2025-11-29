import 'package:flutter/material.dart';
import 'dart:math';
import 'character.dart';

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

  final Map<String, dynamic> behavior;

  bool hasSpawnedIntoScreen = false;
  bool isRushing = false;

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
  }) : currentHealth = currentHealth ?? maxHealth {
    // Random roaming direction before detection
    final rand = Random();
    vx = (rand.nextDouble() * 2 - 1) * 40; // horizontal roam speed
    vy = (rand.nextDouble() * 2 - 1) * 20; // vertical roam speed
  }

  /// Update per frame
  void update(Character character, double deltaTime, double screenWidth, double screenHeight) {
    // === 1. FALLING FROM TOP SPAWN ===
    if (!hasSpawnedIntoScreen) {
      y += 80 * deltaTime; // falling speed

      if (y > 0) {
        hasSpawnedIntoScreen = true;
      }
      return;
    }

    if (behavior['type'] == 'hunter') {
      _hunterBehavior(character, deltaTime, screenWidth, screenHeight);
    }
  }

  /// Eye-of-Cthulhu style logic
  void _hunterBehavior(Character character, double dt, double sw, double sh) {
    final detectDistance = (behavior['detect_distance'] ?? 350).toDouble();
    final roamSpeed = (behavior['roam_speed'] ?? 50).toDouble();
    final rushSpeed = (behavior['rush_speed'] ?? speed).toDouble();

    final dx = character.x - x;
    final dy = character.y - y;
    final dist = sqrt(dx * dx + dy * dy);

    // === 2. Enter rush mode when close ===
    if (dist < detectDistance && !isRushing) {
      isRushing = true;
    }

    if (!isRushing) {
      // === 3. FREE ROAMING MODE ===
      x += vx * dt;
      y += vy * dt;

      // Keep enemy in upper half of the map
      if (y < 0) vy = roamSpeed;
      if (y > sh * 0.45) vy = -roamSpeed;

      // Bounce horizontally
      if (x < 0) vx = roamSpeed;
      if (x + width > sw) vx = -roamSpeed;

      // Small random jitter to look alive
      vx += (Random().nextDouble() - 0.5) * 10 * dt;
      vy += (Random().nextDouble() - 0.5) * 10 * dt;
    } else {
      // === 4. RUSH MODE (attack charging) ===
      final angle = atan2(dy, dx);
      vx = rushSpeed * cos(angle);
      vy = rushSpeed * sin(angle);

      x += vx * dt;
      y += vy * dt;
    }
  }

  Widget buildWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        "assets/enemies/$spritePath",
        fit: BoxFit.contain,
      ),
    );
  }

  void dealDamage(Character character) {
    character.currentHealth -= damage;
    if (character.currentHealth < 0) character.currentHealth = 0;
  }
}
