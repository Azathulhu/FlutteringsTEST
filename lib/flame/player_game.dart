import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../services/input_service.dart';
import 'player_component.dart';

class PlayerGame extends FlameGame {
  final String levelBackground;
  final Map<String, dynamic> characterData;
  final InputService inputService;

  PlayerGame({
    required this.levelBackground,
    required this.characterData,
    required this.inputService,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background
    final bg = SpriteComponent()
      ..sprite = await loadSprite('background/$levelBackground')
      ..size = size;
    add(bg);

    // Player
    final player = PlayerComponent(
      characterData: characterData,
      inputService: inputService,
    )..position = Vector2(size.x / 2, size.y / 2);
    add(player);

    // Add overlay
    overlays.add('ControlsOverlay');
  }
}
