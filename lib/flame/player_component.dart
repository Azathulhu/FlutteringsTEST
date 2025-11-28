import 'package:flame/components.dart';
import '../services/input_service.dart';

class PlayerComponent extends SpriteComponent {
  final Map<String, dynamic> characterData;
  final InputService inputService;

  Vector2 velocity = Vector2.zero();
  double speed = 200;
  double jumpForce = -400;
  double gravity = 800;
  bool onGround = false;

  PlayerComponent({required this.characterData, required this.inputService})
      : super(size: Vector2(64, 64));

  @override
  Future<void> onLoad() async {
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

    // Gravity
    velocity.y += gravity * dt;

    // Jump
    if (inputService.jump && onGround) {
      velocity.y = jumpForce;
      onGround = false;
    }

    // Move player
    x += velocity.x * dt;
    y += velocity.y * dt;

    // Simple floor collision
    if (y + height >= gameRef.size.y - 50) {
      y = gameRef.size.y - 50 - height;
      velocity.y = 0;
      onGround = true;
    }
  }
}
