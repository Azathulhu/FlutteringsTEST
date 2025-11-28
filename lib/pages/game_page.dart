import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  String characterSprite = '';
  double characterWidth = 80;
  double characterHeight = 80;

  // Character state
  double charX = 0;
  double charY = 0;
  double charVy = 0;

  // Game constants
  double gravity = 0.8;
  double jumpStrength = 20;
  double horizontalSpeedMultiplier = 2.0;

  // Platforms
  List<Platform> platforms = [];
  double platformWidth = 120;
  double platformHeight = 20;

  late AnimationController _controller;
  StreamSubscription? _accelerometerSubscription;
  Random random = Random();

  double screenWidth = 0;
  double screenHeight = 0;

  @override
  void initState() {
    super.initState();
    loadSelectedCharacter();
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadSelectedCharacter() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final meta = await supabase
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (meta != null && meta['selected_character_id'] != null) {
      final characterId = meta['selected_character_id'];
      final charData = await supabase
          .from('characters')
          .select()
          .eq('id', characterId)
          .maybeSingle();

      if (charData != null) {
        setState(() {
          characterSprite = charData['sprite_path'];
          jumpStrength = charData['jump_strength']?.toDouble() ?? 20;
        });

        screenWidth = MediaQuery.of(context).size.width;
        screenHeight = MediaQuery.of(context).size.height;

        // Add FIRST platform under character
        final firstPlatformY = screenHeight - 150;
        platforms.add(
          Platform(
            x: screenWidth / 2 - platformWidth / 2,
            y: firstPlatformY,
            width: platformWidth,
          ),
        );

        // Character starts ABOVE the first platform
        charX = 0;
        charY = firstPlatformY - characterHeight;
        charVy = -jumpStrength; // first bounce

        startGame();
      }
    }
  }

  void startGame() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(updateGame);

    _controller.repeat();

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        charX += -event.x * horizontalSpeedMultiplier;
        charX = charX.clamp(
          -screenWidth / 2 + characterWidth / 2,
          screenWidth / 2 - characterWidth / 2,
        );
      });
    });
  }

  void updateGame() {
    setState(() {
      double prevCharY = charY;

      // Physics
      charVy += gravity;
      charY += charVy;

      // Platform collisions (TOP only)
      for (var platform in platforms) {
        bool aboveBefore = prevCharY + characterHeight <= platform.y;
        bool belowAfter = charY + characterHeight >= platform.y;
        bool horizontalHit = charX + characterWidth / 2 >= platform.x &&
            charX - characterWidth / 2 <= platform.x + platform.width;

        if (aboveBefore && belowAfter && horizontalHit && charVy > 0) {
          charY = platform.y - characterHeight;
          charVy = -jumpStrength; // bounce
          break;
        }
      }

      // Screen scroll
      if (charY < screenHeight / 2) {
        double offset = screenHeight / 2 - charY;
        charY = screenHeight / 2;

        for (var platform in platforms) {
          platform.y += offset;
        }
      }

      // Remove platforms off-screen
      platforms.removeWhere((p) => p.y > screenHeight);

      // Generate new platforms above
      while (platforms.length < 10) {
        double highestY = platforms.map((p) => p.y).reduce(min);
        double newY = highestY - 120 - random.nextInt(100);
        double newX = random.nextDouble() * (screenWidth - platformWidth);

        platforms.add(
          Platform(x: newX, y: newY, width: platformWidth),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/images/background/${widget.level['background_image']}"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Platforms (TOP-based coordinates)
          ...platforms.map((p) {
            return Positioned(
              top: p.y,
              left: p.x,
              child: Container(
                width: p.width,
                height: platformHeight,
                color: Colors.brown,
              ),
            );
          }).toList(),

          // Character (TOP-based coordinates)
          if (characterSprite.isNotEmpty)
            Positioned(
              top: charY,
              left: screenWidth / 2 + charX - characterWidth / 2,
              child: SizedBox(
                width: characterWidth,
                height: characterHeight,
                child: Image.asset(
                  "assets/character sprites/$characterSprite",
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Platform {
  double x;
  double y;
  double width;

  Platform({required this.x, required this.y, required this.width});
}
