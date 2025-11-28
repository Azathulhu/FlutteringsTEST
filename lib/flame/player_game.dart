import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'player_component.dart';

class PlayerGame extends FlameGame with HasKeyboardHandlerComponents {
  final String backgroundImage;
  final Map<String, dynamic> character;

  late PlayerComponent player;

  PlayerGame({required this.backgroundImage, required this.character});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final bg = SpriteComponent()
      ..sprite = await loadSprite('background/$backgroundImage')
      ..size = size
      ..position = Vector2.zero();
    add(bg);

    player = PlayerComponent(
      position: Vector2(size.x / 2, 100),
      size: Vector2(64, 64),
    );
    player.sprite = await loadSprite('character_sprites/${character['sprite_path']}');
    add(player);
  }
}
