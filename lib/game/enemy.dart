import 'package:flutter/material.dart';
import 'dart:math';
import 'character.dart';

enum EnemyState { descending, observing, rushing, cooldown }

class Enemy {
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  final double width;
  final double height;

  final String name;
  final String spritePath;
  int maxHealth;
  int currentHealth;
  int damage;
  double speed;

  final Map<String, dynamic> behavior;

  EnemyState state = EnemyState.descending;
  double stateTimer = 0; // tracks how long in current state
  final Random random = Random();

  double targetX = 0;
  double targetY = 0;

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

  void update(Character character, double dt) {
    stateTimer += dt;

    switch (state) {
      case EnemyState.descending:
        _descending(dt);
        break;
      case EnemyState.observing:
        _observing(character, dt);
        break;
      case EnemyState.rushing:
        _rushing(character, dt);
        break;
      case EnemyState.cooldown:
        _cooldown(dt);
        break;
    }

    // Apply velocities
    x += vx * dt;
    y += vy * dt;
  }

  void _descending(double dt) {
    vy = behavior['descend_speed']?.toDouble() ?? 50.0;
    vx = 0;

    // When reaching a certain Y, switch to observing
    if (y >= behavior['observe_height']?.toDouble() ?? 200) {
      state = EnemyState.observing;
      stateTimer = 0;
      vx = 0;
      vy = 0;
      _setRandomObservationTarget();
    }
  }

  void _observing(Character character, double dt) {
    // Smoothly move toward target point near character
    final obsSpeed = behavior['observe_speed']?.toDouble() ?? 40.0;
    final dx = targetX - x;
    final dy = targetY - y;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist > 1) {
      vx = obsSpeed * dx / dist;
      vy = obsSpeed * dy / dist;
    } else {
      vx = 0;
      vy = 0;
    }

    // After observation duration, switch to rushing
    if (stateTimer >= (behavior['observe_duration']?.toDouble() ?? 2.0)) {
      state = EnemyState.rushing;
      stateTimer = 0;
    }
  }

  void _rushing(Character character, double dt) {
    final rushSpeed = behavior['rush_speed']?.toDouble() ?? speed.toDouble();
    final dx = character.x - x;
    final dy = character.y - y;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist > 0) {
      vx = rushSpeed * dx / dist;
      vy = rushSpeed * dy / dist;
    }

    // After rush duration, switch to cooldown
    if (stateTimer >= (behavior['rush_duration']?.toDouble() ?? 1.0)) {
      state = EnemyState.cooldown;
      stateTimer = 0;
      vx = 0;
      vy = 0;
      _setRandomObservationTarget();
    }
  }

  void _cooldown(double dt) {
    // Just hover slowly during cooldown
    vx = 0;
    vy = 0;

    if (stateTimer >= (behavior['cooldown_duration']?.toDouble() ?? 1.0)) {
      state = EnemyState.observing;
      stateTimer = 0;
      _setRandomObservationTarget();
    }
  }

  void _setRandomObservationTarget() {
    // Pick a point slightly offset from current x
    final offset = behavior['observe_offset']?.toDouble() ?? 100.0;
    targetX = x + (random.nextDouble() * 2 - 1) * offset;
    targetY = y + (random.nextDouble() * 0.5 - 0.25) * offset; // small vertical variation
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
