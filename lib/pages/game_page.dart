import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final supabase = Supabase.instance.client;

  // Character properties
  String characterSprite = '';
  double characterX = 0.0; // Horizontal position (0 = center)
  double characterY = 0.0; // Vertical position (we’ll set fixed platform)
  double characterWidth = 80;
  double characterHeight = 80;

  // Platform properties
  double platformY = 500;
  double platformHeight = 20;

  StreamSubscription? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    loadSelectedCharacter();
    characterY = platformY - characterHeight; // Stand on platform
    startTiltListener();
  }

  @override
  void dispose() {
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
        });
      }
    }
  }

  void startTiltListener() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      // event.x is the tilt: negative = tilt left, positive = tilt right
      setState(() {
        // Adjust sensitivity (you can tweak multiplier)
        characterX += event.x * -2;

        // Clamp character within screen bounds
        final screenWidth = MediaQuery.of(context).size.width;
        characterX = characterX.clamp(
            -screenWidth / 2 + characterWidth / 2,
            screenWidth / 2 - characterWidth / 2);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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

          // Platform
          Positioned(
            bottom: screenHeight - platformY,
            left: 0,
            child: Container(
              width: screenWidth,
              height: platformHeight,
              color: Colors.brown,
            ),
          ),

          // Character
          if (characterSprite.isNotEmpty)
            Positioned(
              bottom: screenHeight - characterY - characterHeight,
              left: screenWidth / 2 + characterX - characterWidth / 2,
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
