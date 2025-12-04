import 'package:flutter/material.dart';

class Projectile {
  double x;
  double y;
  final double speed;
  final int damage;
  final String spritePath;
  double vx = 0;
  double vy = 0;
  bool active = true;

  Projectile({
    required this.x,
    required this.y,
    required this.speed,
    required this.damage,
    required this.spritePath,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
  }

  Widget buildWidget() {
    return Positioned(
      left: x,
      top: y,
      child: Image.asset(
        spritePath,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
      ),
    );
  }
}
