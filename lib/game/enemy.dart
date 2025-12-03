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

  bool isRetracting = false;
  double retractRemaining = 0.0;
  double retractSpeed = 150.0;
  double retractDirX = 0.0;
  double retractDirY = 0.0;

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
    vx = (_rand.nextDouble() * 2 - 1) * (speed * 0.1);
    vy = (_rand.nextDouble() * 2 - 1) * (speed * 0.05);
    observeTargetX = x;
    observeTargetY = y;
  }

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

  void startRetract(double dx, double dy, double distance) {
    isRetracting = true;
    retractRemaining = distance;
    final dist = sqrt(dx * dx + dy * dy);
    retractDirX = dist > 0 ? dx / dist : 0;
    retractDirY = dist > 0 ? dy / dist : 0;
    state = EnemyState.cooldown;
    stateTimer = 0;
  }

  void update(Character character, double dt) {
    if (isRetracting) {
      final move = min(retractSpeed * dt, retractRemaining);
      x += retractDirX * move;
      y += retractDirY * move;
      retractRemaining -= move;
      if (retractRemaining <= 0) {
        isRetracting = false;
        vx = 0;
        vy = 0;
      }
      return;
    }

    stateTimer += dt;

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
        vy = descendSpeed;
        x += vx * dt;
        y += vy * dt;
        if (y >= observeHeight) {
          y = observeHeight;
          vy = 0;
          state = EnemyState.observing;
          stateTimer = 0;
          _pickObserveTargetNear(character, observeOffset);
        }
        break;

      case EnemyState.observing:
        final dx = observeTargetX - x;
        final dy = observeTargetY - y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > 1.0) {
          vx = (dx / dist) * observeSpeed;
          vy = (dy / dist) * observeSpeed;
        } else {
          vx *= 0.9;
          vy *= 0.9;
        }
        x += vx * dt;
        y += vy * dt;

        final pdx = character.x - x;
        final pdy = character.y - y;
        final pdist = sqrt(pdx * pdx + pdy * pdy);
        if (pdist <= detectDistance) {
          state = EnemyState.rushing;
          stateTimer = 0;
        } else if (stateTimer >= observeDuration) {
          _pickObserveTargetNear(character, observeOffset);
          stateTimer = 0;
        }
        break;

      case EnemyState.rushing:
        final dxr = character.x - x;
        final dyr = character.y - y;
        final dr = sqrt(dxr * dxr + dyr * dyr);
        if (dr > 1.0) {
          vx = (dxr / dr) * rushSpeed;
          vy = (dyr / dr) * rushSpeed;
        }
        x += vx * dt;
        y += vy * dt;

        if ((x < character.x + character.width &&
            x + width > character.x &&
            y < character.y + character.height &&
            y + height > character.y)) {
          character.currentHealth -= damage;
          if (character.currentHealth < 0) character.currentHealth = 0;
          startRetract(x - character.x, y - character.y, 50.0);
        }

        if (stateTimer >= rushDuration || dr <= stopDistance) {
          state = EnemyState.cooldown;
          stateTimer = 0;
          vx = 0;
          vy = 0;
          _pickObserveTargetNear(character, 60.0);
        }
        break;

      case EnemyState.cooldown:
        if (stateTimer >= cooldownDuration) {
          state = EnemyState.observing;
          stateTimer = 0;
          _pickObserveTargetNear(character, observeOffset);
        }
        break;
    }
  }

  void _pickObserveTargetNear(Character targetCharacter, double offset) {
    observeTargetX =
        targetCharacter.x + (_rand.nextDouble() * 2 - 1) * offset;
    observeTargetY = max(80.0, targetCharacter.y - (_rand.nextDouble() * offset / 2));
  }

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
