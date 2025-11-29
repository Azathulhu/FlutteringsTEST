import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

import '../game/character.dart';
import '../game/world.dart';
import '../game/platform.dart';
import '../game/enemy.dart';
import '../services/enemy_service.dart';
import 'level_selection_page.dart';

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
  bool paused = false;

  final double spawnYOffset = 150;
  final Random random = Random();

  List<Enemy> enemies = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCharacter();
      await loadEnemies(); // spawn enemies after character loads
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadEnemies() async {
    final enemyService = EnemyService();
    enemies = await enemyService.loadEnemiesForSubLevel(
      widget.subLevel['id'],
      random.nextDouble() * screenWidth,
      -100.0, // spawn above screen
    );
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

    character = Character(
      x: screenWidth / 2 - 40,
      y: screenHeight - spawnYOffset - 80,
      width: 80,
      height: 80,
      jumpStrength: charData['jump_strength']?.toDouble() ?? 20,
      spritePath: charData['sprite_path'],
      horizontalSpeedMultiplier: 2.0,
    );

    world = World(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      character: character,
    );

    _addStartingPlatform();
    startGame();
  }

  void _addStartingPlatform() {
    world.platforms.clear();
    world.platforms.add(Platform(
      x: screenWidth / 2 - 60,
      y: screenHeight - spawnYOffset,
      width: 120,
      height: 20,
    ));
  }

  void startGame() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(updateGame);

    _controller.repeat();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!paused) {
        double tiltX = -event.x;
        if (tiltX > 0.1) {
          character.facingRight = true;
        } else if (tiltX < -0.1) {
          character.facingRight = false;
        }
        world.update(tiltX);
      }
    });
  }

  void updateGame() {
    final deltaTime = 0.016; // 60 FPS

    if (!paused && !gameOver) {
      for (var enemy in enemies) {
        enemy.update(character, deltaTime, screenWidth, screenHeight);

        final hit = (character.x < enemy.x + enemy.width &&
            character.x + character.width > enemy.x &&
            character.y < enemy.y + enemy.height &&
            character.y + character.height > enemy.y);

        if (hit) {
          enemy.dealDamage(character);
          if (character.currentHealth <= 0) {
            gameOver = true;
            paused = true;
            _showGameOverDialog();
          }
        }
      }

      if (character.y > screenHeight) {
        gameOver = true;
        paused = true;
        _showGameOverDialog();
      }

      setState(() {});
    }
  }

  Future<bool> _onWillPop() async {
    paused = true;
    bool? result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Are you sure you want to go back?"),
        actions: [
          TextButton(
            onPressed: () {
              paused = false;
              Navigator.of(context).pop(false);
            },
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
    paused = false;
    gameOver = false;

    character.x = screenWidth / 2 - character.width / 2;
    character.y = screenHeight - spawnYOffset - character.height;
    character.vy = 0;
    character.currentHealth = character.maxHealth;

    _addStartingPlatform();
    loadEnemies();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/background/${widget.level['background_image']}",
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
            ...world.platforms.map((p) => Positioned(
                  bottom: screenHeight - p.y,
                  left: p.x,
                  child: Container(
                    width: p.width,
                    height: p.height,
                    color: Colors.brown,
                  ),
                )),
            ...enemies.map((e) => Positioned(
                  bottom: screenHeight - e.y - e.height,
                  left: e.x,
                  child: e.buildWidget(),
                )),
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
import 'level_selection_page.dart';

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
  bool paused = false;

  final double spawnXOffset = 0; // centered
  final double spawnYOffset = 150; // pixels from bottom

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
      y: screenHeight - spawnYOffset - 80,
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

    // Add starting platform at center
    _addStartingPlatform();

    startGame();
  }

  void _addStartingPlatform() {
    world.platforms.clear();
    world.platforms.add(Platform(
      x: screenWidth / 2 - 60,
      y: screenHeight - spawnYOffset,
      width: 120,
      height: 20,
    ));
  }

  void startGame() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(updateGame);

    _controller.repeat();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!paused) {
        double tiltX = -event.x;

        // Update character facing
        if (tiltX > 0.1) {
          character.facingRight = true;
        } else if (tiltX < -0.1) {
          character.facingRight = false;
        }

        // Update world only if not paused
        world.update(tiltX);
      }
    });
  }

  void updateGame() {
    setState(() {
      if (!paused && !gameOver) {
        // Check if character fell below screen
        if (character.y > screenHeight) {
          gameOver = true;
          paused = true;
          _showGameOverDialog();
        }
      }
    });
  }

  Future<bool> _onWillPop() async {
    paused = true; // pause the game immediately
    bool? result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Are you sure you want to go back?"),
        actions: [
          TextButton(
            onPressed: () {
              paused = false; // resume if player cancels
              Navigator.of(context).pop(false);
            },
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
    paused = false;
    gameOver = false;

    // Reset character to **centered spawn**
    character.x = screenWidth / 2 - character.width / 2;
    character.y = screenHeight - spawnYOffset - character.height;
    character.vy = 0;

    // Reset platform
    _addStartingPlatform();
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
}*/
