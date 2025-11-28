import 'package:supabase_flutter/supabase_flutter.dart';

class CharacterService {
  final supabase = Supabase.instance.client;

  // Get list of characters + unlock status
  Future<List<Map<String, dynamic>>> loadCharacters() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final characters = await supabase.from('characters').select();
    final unlockedRows = await supabase
        .from('user_characters')
        .select()
        .eq('user_id', user.id);

    return characters.map((c) {
      final unlocked = unlockedRows.any(
        (u) => u['character_id'] == c['id'] && u['is_unlocked'],
      );
      return {
        ...c,
        'is_unlocked': unlocked || c['is_default'] == true,
      };
    }).toList();
  }

  // Select a character
  Future<void> selectCharacter(int characterId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('users_meta')
        .update({'selected_character_id': characterId})
        .eq('user_id', user.id);
  }

  // Unlock a character
  Future<void> unlockCharacter(int characterId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_characters').upsert({
      'user_id': user.id,
      'character_id': characterId,
      'is_unlocked': true,
    });
  }
  Future<Map<String, dynamic>?> loadCharacterConfig(int characterId) async {
    final result = await supabase
        .from('characters')
        .select()
        .eq('id', characterId)
        .maybeSingle();

    if (result == null) return null;

    // Ensure we return typed numbers
    return {
      'id': result['id'],
      'name': result['name'],
      'sprite_path': result['sprite_path'],
      'speed': (result['speed'] as num?)?.toDouble() ?? 180.0,
      'jump_strength': (result['jump_strength'] as num?)?.toDouble() ?? 350.0,
      'max_health': (result['max_health'] as num?)?.toInt() ?? 100,
      'is_default': result['is_default'] == true,
    };
  }
}

/*import 'package:supabase_flutter/supabase_flutter.dart';

class CharacterService {
  final supabase = Supabase.instance.client;

  // Get list of characters + unlock status
  Future<List<Map<String, dynamic>>> loadCharacters() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final characters = await supabase.from('characters').select();
    final unlockedRows = await supabase
        .from('user_characters')
        .select()
        .eq('user_id', user.id);

    return characters.map((c) {
      final unlocked = unlockedRows.any(
        (u) => u['character_id'] == c['id'] && u['is_unlocked'],
      );
      return {
        ...c,
        'is_unlocked': unlocked || c['is_default'] == true,
      };
    }).toList();
  }

  // Select a character
  Future<void> selectCharacter(int characterId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('users_meta')
        .update({'selected_character_id': characterId})
        .eq('user_id', user.id);
  }

  // Unlock a character
  Future<void> unlockCharacter(int characterId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_characters').upsert({
      'user_id': user.id,
      'character_id': characterId,
      'is_unlocked': true,
    });
  }
}*/
