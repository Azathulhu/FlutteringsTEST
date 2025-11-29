import 'package:flutter/material.dart';
import 'character.dart';
import 'engine.dart';

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Character? character;

  @override
  void initState() {
    super.initState();
    loadCharacter();
  }

  Future<void> loadCharacter() async {
    character = await Character.loadFromSupabase();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
          if (character != null)
            EngineWidget(
              character: character!,
              screenWidth: width,
              screenHeight: height,
            ),
        ],
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
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

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  String characterSprite = "";
  double screenWidth = 0;
  double screenHeight = 0;

  // CHARACTER PROPERTIES
  double charWidth = 70;
  double charHeight = 70;

  // WORLD POSITION (REAL physics)
  double charX = 0;
  double charY = 0;
  double velocityY = 0;

  double gravity = 0.5;
  double jumpStrength = 12;
  double tiltSpeed = 2.0;

  List<Platform> platforms = [];
  double platformWidth = 120;
  double platformHeight = 20;
  Random random = Random();

  late AnimationController controller;
  StreamSubscription? tiltListener;

  @override
  void initState() {
    super.initState();
    loadCharacter();
  }

  @override
  void dispose() {
    controller.dispose();
    tiltListener?.cancel();
    super.dispose();
  }

  Future<void> loadCharacter() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final meta = await supabase
        .from("users_meta")
        .select()
        .eq("user_id", user.id)
        .maybeSingle();

    if (meta != null && meta['selected_character_id'] != null) {
      final charData = await supabase
          .from("characters")
          .select()
          .eq("id", meta["selected_character_id"])
          .maybeSingle();

      if (charData != null) {
        characterSprite = charData["sprite_path"];
        jumpStrength = (charData["jump_strength"] ?? 12).toDouble();
      }

      startEngine();
    }
  }

  void startEngine() {
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(update);

    controller.repeat();

    tiltListener = accelerometerEvents.listen((event) {
      charX += -event.x * tiltSpeed;
    });
  }

  void generatePlatforms() {
    if (platforms.isEmpty) {
      // FIRST PLATFORM
      double y = screenHeight - 150;
      platforms.add(Platform(
        x: screenWidth / 2 - platformWidth / 2,
        y: y,
        width: platformWidth,
      ));

      // CHARACTER START ABOVE FIRST PLATFORM
      charX = platforms[0].x + platformWidth / 2 - charWidth / 2;
      charY = platforms[0].y - charHeight;
      velocityY = -jumpStrength;
    }

    while (platforms.length < 12) {
      double highest = platforms.map((p) => p.y).reduce(min);
      double newY = highest - (140 + random.nextInt(60));
      double newX = random.nextDouble() * (screenWidth - platformWidth);

      platforms.add(Platform(
        x: newX,
        y: newY,
        width: platformWidth,
      ));
    }
  }

  void update() {
    setState(() {
      // --- PHYSICS ---
      velocityY += gravity;
      charY += velocityY;

      // --- HORIZONTAL BOUNDS ---
      charX = charX.clamp(
        0.0,
        screenWidth - charWidth,
      );

      // --- COLLISION DETECTION ---
      for (var p in platforms) {
        bool falling = velocityY > 0;
        bool abovePlatform = charY + charHeight <= p.y;
        bool crossingPlatform = charY + charHeight + velocityY >= p.y;

        bool horizontallyAligned =
            charX + charWidth >= p.x && charX <= p.x + p.width;

        if (falling && abovePlatform && crossingPlatform && horizontallyAligned) {
          charY = p.y - charHeight;
          velocityY = -jumpStrength;
          break;
        }
      }

      // --- SCROLL WORLD WHEN GOING UP ---
      if (charY < screenHeight * 0.4) {
        double offset = (screenHeight * 0.4 - charY);
        charY = screenHeight * 0.4;

        for (var p in platforms) {
          p.y += offset;
        }
      }

      // REMOVE OFFSCREEN PLATFORMS
      platforms.removeWhere((p) => p.y > screenHeight);

      // GENERATE NEW
      generatePlatforms();
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    generatePlatforms();

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/images/background/${widget.level['background_image']}"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // PLATFORMS
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
          }),

          // CHARACTER
          if (characterSprite.isNotEmpty)
            Positioned(
              top: charY,
              left: charX,
              child: SizedBox(
                width: charWidth,
                height: charHeight,
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
}*/
