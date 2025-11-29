import 'dart:math';
import 'package:flutter/material.dart';
import 'character.dart';

class Enemy {
  double x;
  double y;
  final double width;
  final double height;

  final String name;
  final String spritePath;
  int maxHealth;
  int currentHealth;
  int damage;
  double speed;

  Map<String, dynamic> behavior;

  // AI state
  bool isRushing = false;
  bool isDescending = true;
  double targetX = 0;
  double targetY = 0;
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
  }) : currentHealth = currentHealth ?? maxHealth {
    targetX = x;
    targetY = y;
  }

  void update(Character character, double dt) {
    final rand = Random();

    // Descend slowly from top
    if (isDescending) {
      final descendSpeed = (behavior['descend_speed']?.toDouble() ?? 50);
      y += descendSpeed * dt;
      if (y >= (behavior['observe_height']?.toDouble() ?? 200)) {
        isDescending = false;
        targetX = x;
        targetY = y;
      }
      return; // skip other behaviors while descending
    }

    // If not rushing, observe/hover around target point
    if (!isRushing) {
      orbitAngle += (behavior['observe_speed']?.toDouble() ?? 1.0) * dt;
      final radius = (behavior['observe_radius']?.toDouble() ?? 50);
      x = targetX + radius * cos(orbitAngle);
      y = targetY + radius * sin(orbitAngle);

      // Check distance to character, start rushing if close
      final dx = character.x - x;
      final dy = character.y - y;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < (behavior['detect_distance']?.toDouble() ?? 300)) {
        isRushing = true;
      }
    } else {
      // Rush toward character
      final dx = character.x - x;
      final dy = character.y - y;
      final angle = atan2(dy, dx);
      final rushSpeed = behavior['rush_speed']?.toDouble() ?? speed;

      x += cos(angle) * rushSpeed * dt;
      y += sin(angle) * rushSpeed * dt;

      // After passing character or getting close, stop rush
      if ((dx * dx + dy * dy) < pow(behavior['stop_distance']?.toDouble() ?? 20, 2)) {
        isRushing = false;
        targetX = x + (rand.nextDouble() - 0.5) * 50; // small random offset
        targetY = y + (rand.nextDouble() - 0.5) * 50;
      }
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
