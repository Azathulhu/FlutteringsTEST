import 'package:flutter/material.dart';
import 'dart:math';

class Enemy {
  double x;
  double y;
  double width;
  double height;
  int health;
  String spritePath;
  Map<String, dynamic> behavior;

  // State variables
  bool isRushing = false;
  double orbitAngle = 0.0;
  double observeTimer = 0.0;

  Enemy({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.health,
    required this.spritePath,
    required this.behavior,
  });

  void update(double dt, double targetX, double targetY) {
    if (health <= 0) return;

    // Check movement mode
    final movement = behavior['movement'] ?? {};
    final mode = isRushing ? 'rush' : (movement['mode'] ?? 'orbit');
    
    if (!isRushing) {
      // Orbit mode
      orbitAngle += (movement['orbit_speed'] ?? 2.0) * dt;
      final radius = movement['orbit_radius'] ?? 100;
      x = targetX + cos(orbitAngle) * radius;
      y = targetY + sin(orbitAngle) * radius;

      observeTimer += dt;
      if (observeTimer >= (movement['observe_duration'] ?? 2.5)) {
        isRushing = true;
      }
    } else {
      // Rush mode
      final rushSpeed = movement['rush_speed']?.toDouble() ?? 300.0;
      final dx = targetX - x;
      final dy = targetY - y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > 1) {
        x += dx / dist * rushSpeed * dt;
        y += dy / dist * rushSpeed * dt;
      }
    }
  }

  Widget buildWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        spritePath,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}
