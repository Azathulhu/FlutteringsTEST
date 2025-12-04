import 'package:flutter/material.dart';
import 'projectile.dart';

class Weapon {
  final int id;
  final String name;
  final String spritePath;
  final int damage;
  final double fireRate;
  final Projectile projectile;

  Weapon({
    required this.id,
    required this.name,
    required this.spritePath,
    required this.damage,
    required this.fireRate,
    required this.projectile,
  });
}
