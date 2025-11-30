// lib/game/enemy.dart
import 'dart:math';
import 'package:flutter/material.dart';
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
  Map<String, dynamic> behavior;

  EnemyState state = EnemyState.descending;
  double stateTimer = 0.0;
  double observeTargetX = 0.0;
  double observeTargetY = 0.0;
  final Random _rand = Random();

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
    // pick initial small random velocity so it drifts a bit after spawn
    vx = (_rand.nextDouble() * 2 - 1) * (speed * 0.1);
    vy = (_rand.nextDouble() * 2 - 1) * (speed * 0.05);
    observeTargetX = x;
    observeTargetY = y;
  }

  // Construct from DB map (helper)
  factory Enemy.fromMap({
    required double x,
    required double y,
    required String name,
    required String spritePath,
    required int maxHealth,
    required int damage,
    required double speed,
    required Map<String, dynamic> behavior,
  }) {
    return Enemy(
      x: x,
      y: y,
      name: name,
      spritePath: spritePath,
      maxHealth: maxHealth,
      damage: damage,
      speed: speed,
      behavior: behavior,
    );
  }

  // Clone prototype at spawn coords
  Enemy cloneAt(double spawnX, double spawnY) {
    return Enemy.fromMap(
      x: spawnX,
      y: spawnY,
      name: name,
      spritePath: spritePath,
      maxHealth: maxHealth,
      damage: damage,
      speed: speed,
      behavior: Map<String, dynamic>.from(behavior),
    );
  }

  /// Update called every frame. dt in seconds.
  void update(Character character, double dt) {
    stateTimer += dt;

    // defensive casts and defaults
    final descendSpeed = (behavior['descend_speed'] ?? 60.0).toDouble();
    final observeHeight = (behavior['observe_height'] ?? 180.0).toDouble();
    final observeSpeed = (behavior['observe_speed'] ?? 45.0).toDouble();
    final observeDuration = (behavior['observe_duration'] ?? 1.4).toDouble();
    final observeOffset = (behavior['observe_offset'] ?? 120.0).toDouble();
    final rushSpeed = (behavior['rush_speed'] ?? speed).toDouble();
    final rushDuration = (behavior['rush_duration'] ?? 0.9).toDouble();
    final cooldownDuration = (behavior['cooldown_duration'] ?? 1.0).toDouble();
    final detectDistance = (behavior['detect_distance'] ?? 300.0).toDouble();
    final stopDistance = (behavior['stop_distance'] ?? 24.0).toDouble();

    switch (state) {
      case EnemyState.descending:
        // always fall smoothly until observeHeight
        vy = descendSpeed;
        vx = 0;
        y += vy * dt;
        if (y >= observeHeight) {
          y = observeHeight;
          vy = 0;
          vx = 0;
          state = EnemyState.observing;
          stateTimer = 0;
          _pickObserveTargetNear(character, observeOffset);
        }
        break;

      case EnemyState.observing:
        // smoothly move toward observeTarget (velocity-limited)
        final dx = observeTargetX - x;
        final dy = observeTargetY - y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > 1.0) {
          final mx = dx / dist;
          final my = dy / dist;
          vx = mx * observeSpeed;
          vy = my * observeSpeed;
        } else {
          vx = vx * 0.9; // gentle slow
          vy = vy * 0.9;
        }
        x += vx * dt;
        y += vy * dt;

        // If player close enough, prepare to rush
        final pdx = character.x - x;
        final pdy = character.y - y;
        final pdist = sqrt(pdx * pdx + pdy * pdy);
        if (pdist <= detectDistance) {
          state = EnemyState.rushing;
          stateTimer = 0;
        } else if (stateTimer >= observeDuration) {
          // occasionally pick a new observation point
          _pickObserveTargetNear(character, observeOffset);
          stateTimer = 0;
        }
        break;

      case EnemyState.rushing:
        // direct velocity toward player (single continuous dash)
        final dxr = character.x - x;
        final dyr = character.y - y;
        final dr = sqrt(dxr * dxr + dyr * dyr);
        if (dr > 1.0) {
          vx = (dxr / dr) * rushSpeed;
          vy = (dyr / dr) * rushSpeed;
        }
        x += vx * dt;
        y += vy * dt;

        if (stateTimer >= rushDuration || (dr <= stopDistance)) {
          state = EnemyState.cooldown;
          stateTimer = 0;
          vx = 0;
          vy = 0;
          // after rush, pick a new observe point a bit away
          _pickObserveTargetNear(character, observeOffset / 1.5);
        }
        break;

      case EnemyState.cooldown:
        // hover in place for cooldownDuration
        if (stateTimer >= cooldownDuration) {
          state = EnemyState.observing;
          stateTimer = 0;
          _pickObserveTargetNear(character, observeOffset);
        }
        break;
    }
  }

  void _pickObserveTargetNear(Character targetCharacter, double offset) {
    // choose a point near player's current x, but keep some separation
    final ox = targetCharacter.x + (_randDouble(-offset, offset));
    final oy = max(80.0, targetCharacter.y - (_randDouble(20, offset / 2))); // above or near player
    observeTargetX = ox;
    observeTargetY = oy;
  }

  double _randDouble(double a, double b) => a + _rand.nextDouble() * (b - a);

  Widget buildWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        "assets/enemies/$spritePath",
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }

  void dealDamage(Character character) {
    character.currentHealth -= damage;
    if (character.currentHealth < 0) character.currentHealth = 0;
  }
}

/*import 'dart:math';
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
}*/
