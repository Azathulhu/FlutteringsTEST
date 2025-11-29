import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Character {
  double x;
  double y;
  double width;
  double height;
  double velocityY;
  String spritePath;

  Character({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.velocityY,
    required this.spritePath,
  });

  /// Load character from Supabase
  static Future<Character?> loadFromSupabase() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final meta = await client
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (meta == null || meta['selected_character_id'] == null) return null;

    final charData = await client
        .from('characters')
        .select()
        .eq('id', meta['selected_character_id'])
        .maybeSingle();

    if (charData == null) return null;

    return Character(
      x: 0,
      y: 0,
      width: 70,
      height: 70,
      velocityY: -(charData['jump_strength']?.toDouble() ?? 12),
      spritePath: charData['sprite_path'],
    );
  }

  Widget buildWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        "assets/character sprites/$spritePath",
        fit: BoxFit.contain,
      ),
    );
  }
}
