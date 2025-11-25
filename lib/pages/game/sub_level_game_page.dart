import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class SubLevelGamePage extends StatefulWidget {
  final Map<String, dynamic> level; // main level data from Supabase
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
    game = FlameGame(); // empty for now
  }

  @override
  Widget build(BuildContext context) {
    // Use background_path from Supabase, fallback to forest.jpeg
    final bgPath = widget.level['background_path'] as String? ?? 'forest.jpeg';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/$bgPath',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: GameWidget(
              game: game,
              backgroundBuilder: (_) => Container(), // transparent
            ),
          ),
        ],
      ),
    );
  }
}
