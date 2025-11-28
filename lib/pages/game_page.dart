import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/widgets/game_widget.dart';
import '../services/character_service.dart';
import '../game/my_platformer_game.dart'; 

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool loading = true;
  Map<String, dynamic>? charConfig;
  late final MyPlatformerGame game;

  final CharacterService _characterService = CharacterService();

  @override
  void initState() {
    super.initState();
    _loadAndStart();
  }

  Future<void> _loadAndStart() async {
    // get selected_character_id from users_meta or pass from earlier flow
    // For simplicity, we'll fetch from users_meta table.
    final supabase = CharacterService().supabase;
    final user = supabase.auth.currentUser;
    if (user == null) {
      // fallback: pick default character (first default)
      final defaults = await supabase.from('characters').select().eq('is_default', true).limit(1);
      if (defaults.isNotEmpty) {
        final id = defaults.first['id'] as int;
        charConfig = await _characterService.loadCharacterConfig(id);
      }
    } else {
      final meta = await supabase
          .from('users_meta')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (meta != null && meta['selected_character_id'] != null) {
        final selectedId = meta['selected_character_id'] as int;
        charConfig = await _characterService.loadCharacterConfig(selectedId);
      } else {
        final defaults = await supabase.from('characters').select().eq('is_default', true).limit(1);
        if (defaults.isNotEmpty) {
          final id = defaults.first['id'] as int;
          charConfig = await _characterService.loadCharacterConfig(id);
        }
      }
    }

    if (charConfig == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    game = MyPlatformerGame(
      backgroundImageAsset: 'assets/images/background/${widget.level['background_image']}',
      characterConfig: charConfig!,
    );

    // Preload images (background + sprite)
    await Flame.images.load(widget.level['background_image']);
    await Flame.images.load(charConfig!['sprite_path']);

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: GameWidget(
        game: game,
      ),
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
