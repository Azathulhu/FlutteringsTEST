import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/my_platformer_game.dart';
import '../services/character_service.dart';

class GamePage extends StatefulWidget {
  final int characterId;
  const GamePage({super.key, required this.characterId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late MyPlatformerGame game;
  Map<String, dynamic>? characterData;

  @override
  void initState() {
    super.initState();
    loadCharacter();
  }

  Future<void> loadCharacter() async {
    final data = await CharacterService().loadCharacterById(widget.characterId);
    setState(() {
      characterData = data;
      game = MyPlatformerGame(characterData: data);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (characterData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: GameWidget(game: game),
    );
  }
}


/*import 'package:flutter/material.dart';

class GamePage extends StatelessWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/background/${level['background_image']}"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text(
            "Sub-Level: ${subLevel['name']}",
            style: TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}*/
