import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import '../game/character.dart';
import '../game/world.dart';
import '../game/platform.dart';
import 'level_selection_page.dart'; // make sure this path is correct

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late Character character;
  late World world;

  double screenWidth = 0;
  double screenHeight = 0;

  late AnimationController _controller;
  StreamSubscription? _accelerometerSubscription;

  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCharacter();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadCharacter() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final meta = await supabase
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (meta == null || meta['selected_character_id'] == null) return;

    final charData = await supabase
        .from('characters')
        .select()
        .eq('id', meta['selected_character_id'])
        .maybeSingle();

    if (charData == null) return;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // Initialize character
    character = Character(
      x: screenWidth / 2 - 40,
      y: screenHeight - 150 - 80,
      width: 80,
      height: 80,
      jumpStrength: charData['jump_strength']?.toDouble() ?? 20,
      spritePath: charData['sprite_path'],
      horizontalSpeedMultiplier: 2.0,
    );

    // Initialize world
    world = World(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      character: character,
    );

    // Add starting platform
    world.platforms.add(Platform(
      x: screenWidth / 2 - 60,
      y: screenHeight - 150,
      width: 120,
      height: 20,
    ));

    startGame();
  }

  void startGame() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(updateGame);

    _controller.repeat();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      double tiltX = -event.x;

      // Update character facing direction
      if (tiltX > 0.1) {
        character.facingRight = true;
      } else if (tiltX < -0.1) {
        character.facingRight = false;
      }

      // Update world
      world.update(tiltX);
    });
  }

  void updateGame() {
    setState(() {
      // Check if character fell below screen
      if (!gameOver && character.y > screenHeight) {
        gameOver = true;
        _showGameOverDialog();
      }
    });
  }

  Future<bool> _onWillPop() async {
    bool? result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Are you sure you want to go back?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Yes"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showGameOverDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Game Over"),
        content: Text("Do you want to try again?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LevelSelectionPage()),
              );
            },
            child: Text("Back"),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    character.y = screenHeight - 150 - 80;
    character.vy = 0;
    gameOver = false;

    world.platforms.clear();
    world.platforms.add(Platform(
      x: screenWidth / 2 - 60,
      y: screenHeight - 150,
      width: 120,
      height: 20,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                "assets/images/background/${widget.level['background_image']}",
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),

            // Platforms
            ...world.platforms.map((p) => Positioned(
                  bottom: screenHeight - p.y,
                  left: p.x,
                  child: Container(
                    width: p.width,
                    height: p.height,
                    color: Colors.brown,
                  ),
                )),

            // Character
            Positioned(
              bottom: screenHeight - character.y - character.height,
              left: character.x,
              child: character.buildWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import '../game/character.dart';
import '../game/world.dart';
import '../game/platform.dart';

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late Character character;
  late World world;

  double screenWidth = 0;
  double screenHeight = 0;

  late AnimationController _controller;
  StreamSubscription? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCharacter();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadCharacter() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final meta = await supabase
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (meta == null || meta['selected_character_id'] == null) return;

    final charData = await supabase
        .from('characters')
        .select()
        .eq('id', meta['selected_character_id'])
        .maybeSingle();

    if (charData == null) return;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // Initialize character
    character = Character(
      x: screenWidth / 2 - 40,
      y: screenHeight - 150 - 80,
      width: 80,
      height: 80,
      jumpStrength: charData['jump_strength']?.toDouble() ?? 20,
      spritePath: charData['sprite_path'],
      horizontalSpeedMultiplier: 2.0,
    );

    // Initialize world
    world = World(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      character: character,
    );

    // Add starting platform
    world.platforms.add(Platform(
      x: screenWidth / 2 - 60,
      y: screenHeight - 150,
      width: 120,
      height: 20,
    ));

    startGame();
  }

  void startGame() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(updateGame);

    _controller.repeat();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      double tiltX = -event.x;
      world.update(tiltX);
    });
  }

  void updateGame() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pixel-perfect Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/background/${widget.level['background_image']}",
              fit: BoxFit.fill, // stretches to fill the screen
              filterQuality: FilterQuality.none, // nearest-neighbor scaling
            ),
          ),

          // Platforms
          ...world.platforms.map((p) => Positioned(
                bottom: screenHeight - p.y,
                left: p.x,
                child: Container(
                  width: p.width,
                  height: p.height,
                  color: Colors.brown,
                ),
              )),

          // Character
          Positioned(
            bottom: screenHeight - character.y - character.height,
            left: character.x,
            child: character.buildWidget(),
          ),
        ],
      ),
    );
  }
}*/
