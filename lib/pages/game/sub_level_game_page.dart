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
  late final String backgroundAsset;

  @override
  void initState() {
    super.initState();

    // Get background path safely from Supabase
    final bgFromSupabase = (widget.level['background_path'] as String?)?.trim();
    backgroundAsset = (bgFromSupabase != null && bgFromSupabase.isNotEmpty)
        ? bgFromSupabase
        : 'forest.jpeg'; // fallback

    game = FlameGame(); // Flame only handles the game, not the background
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background/$backgroundAsset'),
            fit: BoxFit.cover,
          ),
        ),
        child: GameWidget(game: game),
      ),
    );
  }
}
