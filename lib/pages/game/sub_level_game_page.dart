import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SubLevelGamePage extends StatefulWidget {
  final Map<String, dynamic> level; // main level data
  final Map<String, dynamic> subLevel; // sub-level data

  const SubLevelGamePage({
    required this.level,
    required this.subLevel,
    Key? key,
  }) : super(key: key);

  @override
  State<SubLevelGamePage> createState() => _SubLevelGamePageState();
}

class _SubLevelGamePageState extends State<SubLevelGamePage> {
  late final FlameGame game;

  @override
  void initState() {
    super.initState();
    game = FlameGameWithBackground(
      backgroundPath: widget.level['background_path'] as String?, // Supabase value
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: game),
    );
  }
}

// Flame Game that only renders the background image for now
class FlameGameWithBackground extends FlameGame {
  final String? backgroundPath;
  late SpriteComponent background;

  FlameGameWithBackground({this.backgroundPath});

  @override
  Future<void> onLoad() async {
    if (backgroundPath != null && backgroundPath!.isNotEmpty) {
      // Load sprite from assets/background folder
      background = SpriteComponent()
        ..sprite = await loadSprite('images/background/$backgroundPath')
        ..size = size; // fill screen
      add(background);
    } else {
      // Fallback: default background
      background = SpriteComponent()
        ..sprite = await loadSprite('images/background/images (17).jpg')
        ..size = size;
      add(background);
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    background.size = canvasSize; // make background always fill screen
  }
}
