//REWRITE.
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
          "https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8Zm9yZXN0fGVufDB8fDB8fHww";

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
