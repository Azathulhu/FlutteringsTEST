import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SubLevelGamePage extends StatefulWidget {
  final Map<String, dynamic> level; // main level data
  final Map<String, dynamic> subLevel; // sub-level data

  const SubLevelGamePage({required this.level, required this.subLevel, Key? key}) : super(key: key);

  @override
  State<SubLevelGamePage> createState() => _SubLevelGamePageState();
}

class _SubLevelGamePageState extends State<SubLevelGamePage> {
  late final FlameGame game;

  @override
  void initState() {
    super.initState();
    game = FlameGameWithBackground(
      backgroundPath: widget.level['background_path'] as String?, // safely cast
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: game),
    );
  }
}

// Flame Game that only renders a background image for now
class FlameGameWithBackground extends FlameGame {
  final String? backgroundPath;
  late SpriteComponent background;

  FlameGameWithBackground({this.backgroundPath});

  @override
  Future<void> onLoad() async {
    if (backgroundPath != null && backgroundPath!.isNotEmpty) {
      // Load sprite from asset (path relative to assets/)
      background = SpriteComponent()
        ..sprite = await loadSprite('background/$backgroundPath')
        ..size = size; // fill screen
      add(background);
    } else {
      // Fallback: empty background
      background = SpriteComponent()
        ..size = size
        ..sprite = await loadSprite('background/forestbg.jpg'); // optional default
      add(background);
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    background.size = canvasSize; // make background fill screen
  }
}
