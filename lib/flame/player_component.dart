import 'package:flame/components.dart';
import 'package:flame/game.dart';

class PlayerComponent extends SpriteComponent {
  double speed = 200;
  double jumpSpeed = -400;
  double gravity = 800;
  bool onGround = false;
  Vector2 velocity = Vector2.zero();

  PlayerComponent({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply gravity
    velocity.y += gravity * dt;
    position += velocity * dt;

    // Ground collision
    if (position.y + size.y >= 500) { // temporary ground y position
      position.y = 500 - size.y;
      velocity.y = 0;
      onGround = true;
    }
  }

  void moveLeft(double dt) {
    position.x -= speed * dt;
  }

  void moveRight(double dt) {
    position.x += speed * dt;
  }

  void jump() {
    if (onGround) {
      velocity.y = jumpSpeed;
      onGround = false;
    }
  }
}
