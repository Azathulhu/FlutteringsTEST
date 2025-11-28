import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../services/input_service.dart';
import 'player_game.dart';

class PlayerComponent extends SpriteComponent with HasGameRef<PlayerGame> {
  final Map<String, dynamic> characterData;
  final InputService inputService;

  Vector2 velocity = Vector2.zero();
  double speed = 200;
  double jumpForce = -400;
  double gravity = 800;
  bool onGround = false;

  PlayerComponent({
    required this.characterData,
    required this.inputService,
  }) : super(size: Vector2(64, 64));

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('character_sprites/${characterData['sprite_path']}');
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

    position += velocity * dt;

    // Ground collision
    final groundY = gameRef.size.y - 50;
    if (position.y + size.y >= groundY) {
      position.y = groundY - size.y;
      velocity.y = 0;
      onGround = true;
    }
  }
}
