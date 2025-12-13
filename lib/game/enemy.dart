import 'dart:math';
import 'package:flutter/material.dart';
import 'character.dart';
import 'projectile.dart';

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

  double shootCooldown = 0.0;
  List<Projectile> activeProjectiles = [];


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
    if (dist > 0) {
      retractDirX = dx / dist;
      retractDirY = dy / dist;
    } else {
      retractDirX = 0;
      retractDirY = 0;
    }
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
  
    final type = behavior['type'] ?? 'hunter';
    final descendSpeed = (behavior['descend_speed'] ?? 60.0).toDouble();
    final observeHeight = (behavior['observe_height'] ?? 180.0).toDouble();
    final observeDuration = (behavior['observe_duration'] ?? 1.4).toDouble();
    final cooldownDuration = (behavior['cooldown_duration'] ?? 1.0).toDouble();
    final detectDistance = (behavior['detect_distance'] ?? 300.0).toDouble();
    final stopDistance = (behavior['stop_distance'] ?? 24.0).toDouble();
  
    switch (state) {
      case EnemyState.descending:
        vy = descendSpeed;
        y += vy * dt;
        if (y >= observeHeight) {
          y = observeHeight;
          vy = 0;
          vx = 0;
          state = EnemyState.observing;
          stateTimer = 0;
          _pickObserveTargetNear(character, behavior['observe_offset']?.toDouble() ?? 100);
        }
        break;
  
      case EnemyState.observing:
        final dx = observeTargetX - x;
        final dy = observeTargetY - y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > 1.0) {
          vx = dx / dist * (behavior['observe_speed']?.toDouble() ?? 50);
          vy = dy / dist * (behavior['observe_speed']?.toDouble() ?? 50);
        } else {
          vx *= 0.9;
          vy *= 0.9;
        }
        x += vx * dt;
        y += vy * dt;
  
        if (type == 'hunter') {
          final pdx = character.x - x;
          final pdy = character.y - y;
          final pdist = sqrt(pdx * pdx + pdy * pdy);
          if (pdist <= detectDistance) {
            state = EnemyState.rushing;
            stateTimer = 0;
          } else if (stateTimer >= observeDuration) {
            _pickObserveTargetNear(character, behavior['observe_offset']?.toDouble() ?? 100);
            stateTimer = 0;
          }
        } else if (type == 'drone') {
          shootCooldown += dt;
          if (behavior['shoot_interval'] != null && shootCooldown >= behavior['shoot_interval']) {
            shootCooldown = 0;
        
            final projData = behavior['projectile'];
            if (projData != null) {
              Projectile proj = Projectile(
                x: x + width / 2,
                y: y + height / 2,
                speed: projData['speed']?.toDouble() ?? 300,
                damage: projData['damage']?.toInt() ?? 10,
                spritePath: projData['sprite_path'] ?? '',
              );
        
              final dx = (character.x + character.width / 2) - (x + width / 2);
              final dy = (character.y + character.height / 2) - (y + height / 2);
              final dist = sqrt(dx * dx + dy * dy);
              if (dist > 0) {
                proj.vx = dx / dist * proj.speed;
                proj.vy = dy / dist * proj.speed;
              }
        
              activeProjectiles.add(proj);
            }
          }
          final kiteDistance = (behavior['kite_distance'] ?? 260).toDouble();
          final retreatDistance = (behavior['retreat_distance'] ?? 160).toDouble();
          final kiteSpeed = (behavior['kite_speed'] ?? 70).toDouble();
          final retreatSpeed = (behavior['retreat_speed'] ?? 120).toDouble();
        
          final dx = character.x - x;
          final dy = character.y - y;
          final dist = sqrt(dx * dx + dy * dy);
        
          if (dist < retreatDistance) {
            final rx = x - dx;
            final ry = y - dy;
            final rdist = sqrt(rx*rx + ry*ry);
            vx = (rx / rdist) * retreatSpeed * 0.8;
            vy = (ry / rdist) * retreatSpeed * 0.8;
          }
          else if (dist < kiteDistance) {
            final perpX = -dy;
            final perpY = dx;
            final perpLen = sqrt(perpX*perpX + perpY*perpY);
        
            vx = (perpX / perpLen) * kiteSpeed;
            vy = (perpY / perpLen) * kiteSpeed;
          }
          else {
            vx = (dx / dist) * kiteSpeed * 0.5;
            vy = (dy / dist) * kiteSpeed * 0.5;
          }
        
          x += vx * dt;
          y += vy * dt;
        }
        break;
  
      case EnemyState.rushing:
        if (type == 'hunter') {
          final dxr = character.x - x;
          final dyr = character.y - y;
          final dr = sqrt(dxr * dxr + dyr * dyr);
          if (dr > 1.0) {
            vx = (dxr / dr) * (behavior['rush_speed']?.toDouble() ?? speed);
            vy = (dyr / dr) * (behavior['rush_speed']?.toDouble() ?? speed);
          }
          x += vx * dt;
          y += vy * dt;
  
          if ((x < character.x + character.width &&
              x + width > character.x &&
              y < character.y + character.height &&
              y + height > character.y)) {
            character.takeDamage(damage);
  
            final dx = x - character.x;
            final dy = y - character.y;
            startRetract(dx, dy, 50);
          }
  
          if (stateTimer >= (behavior['rush_duration']?.toDouble() ?? 0.9) || dr <= stopDistance) {
            state = EnemyState.cooldown;
            stateTimer = 0;
            _pickObserveTargetNear(character, behavior['observe_offset']?.toDouble() ?? 100);
          }
        } else {
          state = EnemyState.observing;
          stateTimer = 0;
        }
        break;
  
      case EnemyState.cooldown:
        if (stateTimer >= cooldownDuration) {
          state = EnemyState.observing;
          stateTimer = 0;
          _pickObserveTargetNear(character, behavior['observe_offset']?.toDouble() ?? 100);
        }
        break;
    }
  
    for (int i = activeProjectiles.length - 1; i >= 0; i--) {
      final p = activeProjectiles[i];
      p.update(dt);
  
      if (p.x >= character.x &&
          p.x <= character.x + character.width &&
          p.y >= character.y &&
          p.y <= character.y + character.height) {
        character.takeDamage(p.damage);
        activeProjectiles.removeAt(i);
        continue;
      }
  
      if (p.x < 0 || p.x > 1920 || p.y < 0 || p.y > 1080) {
        activeProjectiles.removeAt(i);
      }
    }
  }
  
  void _pickObserveTargetNear(Character targetCharacter, double offset) {
    final ox = targetCharacter.x + (_randDouble(-offset, offset));
    final oy = max(80.0, targetCharacter.y - (_randDouble(20, offset / 2)));
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
