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

  final Map<String, dynamic> behavior;

  bool isRushing = false;
  bool hasSpawned = false; // to handle spawn from top
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

  void update(Character character, {double deltaTime = 0.016}) {
    if (!hasSpawned) {
      _spawnFromTop(deltaTime);
      return;
    }

    if (behavior['type'] == 'hunter') {
      _hunterBehavior(character, deltaTime);
    }
  }

  /// Slowly spawn from top
  void _spawnFromTop(double deltaTime) {
    final spawnSpeed = (behavior['spawn_speed'] ?? 50).toDouble();
    y += spawnSpeed * deltaTime;
    if (y > 0) hasSpawned = true; // fully entered screen
  }

  /// Hunter AI roaming and attacking
  void _hunterBehavior(Character character, double deltaTime) {
    final roamRadius = (behavior['roam_radius'] ?? 120).toDouble();
    final roamSpeed = (behavior['roam_speed'] ?? 1.5).toDouble();
    final rushSpeed = (behavior['rush_speed'] ?? speed).toDouble();
    final detectDistance = (behavior['detect_distance'] ?? 300).toDouble();

    final dx = character.x - x;
    final dy = character.y - y;
    final distance = sqrt(dx * dx + dy * dy);

    if (!isRushing && distance < detectDistance) {
      // Orbit or roam around the character
      orbitAngle += roamSpeed * deltaTime;
      x = character.x + roamRadius * cos(orbitAngle);
      y = character.y + roamRadius * sin(orbitAngle);

      if (orbitAngle > 2 * pi) {
        isRushing = true;
      }
    } else if (isRushing) {
      // Rush directly to player
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
