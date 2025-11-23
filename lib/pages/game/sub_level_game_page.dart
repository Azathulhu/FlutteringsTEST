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
      backgroundPath: widget.level['background_path'],
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

  FlameGameWithBackground({this.backgroundPath});

  late SpriteComponent background;

  @override
  Future<void> onLoad() async {
    if (backgroundPath != null) {
      // Load sprite from asset
      background = SpriteComponent()
        ..sprite = await loadSprite('backgrounds/$backgroundPath')
        ..size = size; // full screen
      add(background);
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    background.size = canvasSize; // make background fill screen
  }
}
