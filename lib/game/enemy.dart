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

  bool isActive = false; // true when fully spawned
  double targetY = 100; // Y to stop falling
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

  void update(Character character, double deltaTime, double screenWidth, double screenHeight) {
    if (!isActive) {
      // FALLING PHASE
      y += speed * deltaTime; // fall speed
      if (y >= targetY) {
        y = targetY;
        isActive = true;
      }
      return;
    }

    // ACTIVE PHASE (Hunter roaming)
    if (behavior['type'] == 'hunter') {
      _hunterBehavior(character, deltaTime);
    }
  }

  void _hunterBehavior(Character character, double deltaTime) {
    final dx = character.x - x;
    final dy = character.y - y;
    final distance = sqrt(dx * dx + dy * dy);
    final detectDistance = behavior['detect_distance']?.toDouble() ?? 300;

    if (distance < detectDistance) {
      // orbit
      orbitAngle += (behavior['orbit_speed']?.toDouble() ?? 0.03) * deltaTime * 60;
      final radius = behavior['orbit_radius']?.toDouble() ?? 120;
      x = character.x + radius * cos(orbitAngle);
      y = character.y + radius * sin(orbitAngle);
    } else {
      // roam randomly
      x += (randomDirection() * speed * deltaTime);
      y += (randomDirection() * speed * deltaTime);
    }
  }

  double randomDirection() {
    return Random().nextBool() ? 1 : -1;
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
