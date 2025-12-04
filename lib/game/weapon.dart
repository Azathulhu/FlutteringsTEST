import 'dart:math';
import 'package:flutter/material.dart';
import '../game/enemy.dart';

class Weapon {
  double x;
  double y;
  final String name;
  final String spritePath;
  final String projectileSpritePath;
  final double fireRate; // shots per second
  final int damage;
  final double speed; // projectile speed
  final double range;
  final Map<String, dynamic> behavior;

  double _cooldown = 0.0;

  Weapon({
    required this.x,
    required this.y,
    required this.name,
    required this.spritePath,
    required this.projectileSpritePath,
    required this.fireRate,
    required this.damage,
    required this.speed,
    required this.range,
    required this.behavior,
  });

  void update(double dt, List<Enemy> enemies, List<Projectile> projectiles) {
    _cooldown -= dt;
    if (_cooldown <= 0) {
      final target = _findNearestEnemy(enemies);
      if (target != null) {
        shootAt(target, projectiles);
        _cooldown = 1 / fireRate;
      }
    }
  }

  Enemy? _findNearestEnemy(List<Enemy> enemies) {
    Enemy? nearest;
    double nearestDist = double.infinity;

    for (var e in enemies) {
      double dx = e.x - x;
      double dy = e.y - y;
      double dist = sqrt(dx * dx + dy * dy);
      if (dist < nearestDist && dist <= range) {
        nearestDist = dist;
        nearest = e;
      }
    }
    return nearest;
  }

  void shootAt(Enemy target, List<Projectile> projectiles) {
    final dx = target.x + target.width / 2 - x;
    final dy = target.y + target.height / 2 - y;
    final angle = atan2(dy, dx);

    projectiles.add(Projectile(
      x: x,
      y: y,
      angle: angle,
      speed: speed,
      damage: damage,
      spritePath: projectileSpritePath,
    ));
  }

  Widget buildWidget(double angle) {
    return Transform.rotate(
      angle: angle,
      child: Image.asset(
        spritePath,
        width: 48,
        height: 48,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class Projectile {
  double x;
  double y;
  final double angle;
  final double speed;
  final int damage;
  final String spritePath;

  bool active = true;

  Projectile({
    required this.x,
    required this.y,
    required this.angle,
    required this.speed,
    required this.damage,
    required this.spritePath,
  });

  void update(double dt) {
    x += cos(angle) * speed * dt;
    y += sin(angle) * speed * dt;
  }

  Widget buildWidget() {
    return Transform.rotate(
      angle: angle,
      child: Image.asset(
        spritePath,
        width: 24,
        height: 24,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}
