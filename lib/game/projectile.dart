import 'package:flutter/material.dart';

class Projectile {
  double x;
  double y;
  double vx;
  double vy;
  double speed;
  int damage;
  final String spritePath;

  Projectile({
    required this.x,
    required this.y,
    required this.speed,
    required this.damage,
    required this.spritePath,
    this.vx = 0,
    this.vy = 0,
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
        width: 16,
        height: 16,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}
