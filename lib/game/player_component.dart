import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PlayerComponent extends SpriteAnimationComponent with HasGameRef, KeyboardHandler {
  double speed;
  double jumpStrength;
  int maxHealth;

  Vector2 velocity = Vector2.zero();
  bool onGround = false;

  // simple animation control
  late SpriteAnimation idleAnim;
  late SpriteAnimation runAnim;
  bool facingRight = true;

  PlayerComponent({
    required Vector2 position,
    required Vector2 size,
    required this.speed,
    required this.jumpStrength,
    required this.maxHealth,
    required String spritePath,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final imageName = spritePath.split('/').last;
    final image = gameRef.images.fromCache(imageName);

    // If sprite is a single image (not spritesheet), create basic single-frame animation
    idleAnim = SpriteAnimation.spriteList([Sprite(image)], stepTime: 1.0);

    // If sprite sheet, user can store a spritesheet and we can create run animation.
    // For now we'll fallback to idleAnim for runAnim (simple).
    runAnim = idleAnim;

    animation = idleAnim;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // apply gravity
    final gravity = 900.0;
    velocity.y += gravity * dt;

    // integrate movement
    position += velocity * dt;

    // simple horizontal drag
    velocity.x *= 0.98;

    // ground & platform collision: we iterate through components that are PlatformComponent
    // naive collision: if bottom intersects platform top -> place on top
    final platforms = gameRef.children.whereType<PlatformComponent>();
    onGround = false;
    for (final p in platforms) {
      final playerBottom = position.y + size.y / 2;
      final playerTop = position.y - size.y / 2;
      final playerLeft = position.x - size.x / 2;
      final playerRight = position.x + size.x / 2;

      final platformTop = p.position.y;
      final platformBottom = p.position.y + p.size.y;
      final platformLeft = p.position.x;
      final platformRight = p.position.x + p.size.x;

      final intersectsHorizontally = playerRight > platformLeft && playerLeft < platformRight;
      final isFallingIntoPlatform = velocity.y >= 0 && playerBottom >= platformTop && playerTop < platformTop;

      if (intersectsHorizontally && playerBottom >= platformTop && playerTop < platformTop && playerBottom - velocity.y * dt <= platformTop) {
        // landed
        position.y = platformTop - size.y / 2;
        velocity.y = 0;
        onGround = true;
      }
    }

    // prevent falling below bottom of world (safety)
    final worldBottom = gameRef.size.y - 10;
    if (position.y + size.y / 2 > worldBottom) {
      position.y = worldBottom - size.y / 2;
      velocity.y = 0;
      onGround = true;
    }

    // update animation based on horizontal speed
    if (velocity.x.abs() > 10) {
      animation = runAnim;
    } else {
      animation = idleAnim;
    }
  }

  void moveLeft() {
    velocity.x = -speed;
    facingRight = false;
  }

  void moveRight() {
    velocity.x = speed;
    facingRight = true;
  }

  void stopMoving() {
    velocity.x = 0;
  }

  void jump() {
    if (onGround) {
      velocity.y = -jumpStrength;
      onGround = false;
    }
  }

  // Keyboard handling (desktop)
  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) moveLeft();
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) moveRight();
      if (event.logicalKey == LogicalKeyboardKey.space) jump();
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.arrowRight) {
        stopMoving();
      }
    }
    return true;
  }
}
