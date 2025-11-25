import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class SubLevelGamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  const SubLevelGamePage({
    required this.level,
    required this.subLevel,
    super.key,
  });

  @override
  State<SubLevelGamePage> createState() => _SubLevelGamePageState();
}

class _SubLevelGamePageState extends State<SubLevelGamePage> {
  late final FlameGame game;
  late String? backgroundUrl;

  @override
  void initState() {
    super.initState();

    // read from Supabase
    final raw = widget.level['background_path'] as String?;

    // validate url
    if (raw != null && raw.trim().isNotEmpty && raw.startsWith("http")) {
      backgroundUrl = raw.trim();
    } else {
      // fallback image from the internet
      backgroundUrl =
          "https://picsum.photos/800/1600"; // you can use any default
    }

    game = FlameGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background from Internet
          Positioned.fill(
            child: Image.network(
              backgroundUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.black); // fallback
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          // Flame game above background
          Positioned.fill(
            child: GameWidget(game: game),
          )
        ],
      ),
    );
  }
}
