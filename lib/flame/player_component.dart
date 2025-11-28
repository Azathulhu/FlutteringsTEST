import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/input.dart';
import '../services/input_service.dart';

class PlayerComponent extends SpriteComponent with HasGameRef, CollisionCallbacks {
  final Map<String, dynamic> characterData;
  final InputService inputService;

  Vector2 velocity = Vector2.zero();
  double speed = 200; // movement speed
  double jumpForce = -400; // jump velocity
  double gravity = 800; // gravity
  bool onGround = false;

  PlayerComponent({required this.characterData, required this.inputService})
      : super(size: Vector2(64, 64)); // adjust based on sprite size

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('character_sprites/${characterData['sprite_path']}');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Horizontal movement
    if (inputService.moveLeft) {
      velocity.x = -speed;
    } else if (inputService.moveRight) {
      velocity.x = speed;
    } else {
      velocity.x = 0;
    }

    // Apply gravity
    velocity.y += gravity * dt;

    // Jump
    if (inputService.jump && onGround) {
      velocity.y = jumpForce;
      onGround = false;
    }

    // Move player
    position += velocity * dt;

    // Simple floor collision
    if (position.y + size.y >= gameRef.size.y - 50) {
      position.y = gameRef.size.y - 50 - size.y;
      velocity.y = 0;
      onGround = true;
    }
  }
}
