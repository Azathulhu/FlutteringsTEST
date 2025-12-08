import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  /// Load all levels with user's unlocked info
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final levels = await supabase.from('levels').select();
    final userSubLevels = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id);

    return levels.map((level) {
      // unlocked if any sub-level is unlocked or level is default
      final unlocked = userSubLevels.any((ul) {
        final subLevelId = ul['sub_level_id'];
        return ul['is_unlocked'] == true &&
            subLevelId != null &&
            userSubLevels.any((u) => u['sub_level_id'] == subLevelId);
      });
      return {
        ...level,
        'is_unlocked': unlocked || level['is_default'] == true,
      };
    }).toList();
  }

  /// Load all sub-levels for a level with user's progress
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final subLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .order('order_index', ascending: true);

    final userSubLevels = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id);

    return subLevels.map((sl) {
      final ul = userSubLevels.firstWhere(
          (u) => u['sub_level_id'] == sl['id'],
          orElse: () => {'is_unlocked': false, 'is_completed': false});
      return {
        ...sl,
        'is_unlocked': ul['is_unlocked'] ?? false,
        'is_completed': ul['is_completed'] ?? false,
      };
    }).toList();
  }

  /// Complete a sub-level and unlock the next proper sub-level
  Future<void> completeSubLevel(int subLevelId, int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Mark current sub-level as completed (upsert in case it doesn't exist)
    await supabase.from('user_levels').upsert({
      'user_id': user.id,
      'sub_level_id': subLevelId,
      'is_completed': true,
      'is_unlocked': true,
    }, onConflict: ['user_id', 'sub_level_id']);

    // Load all sub-levels for this level in order
    final subLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .order('order_index', ascending: true);

    // Load user's sub-level status for this level
    final userSubLevels = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id)
        .in_('sub_level_id', subLevels.map((s) => s['id']).toList());

    // Find next sub-level to unlock inside the same level
    Map<String, dynamic>? nextSubToUnlock;
    for (var sl in subLevels) {
      final ul = userSubLevels.firstWhere(
          (u) => u['sub_level_id'] == sl['id'],
          orElse: () => {'is_completed': false});
      if (ul['is_completed'] != true) {
        nextSubToUnlock = sl;
        break;
      }
    }

    if (nextSubToUnlock != null) {
      // Unlock the next sub-level inside the same level
      await supabase.from('user_levels').upsert({
        'user_id': user.id,
        'sub_level_id': nextSubToUnlock['id'],
        'is_unlocked': true,
        'is_completed': false,
      }, onConflict: ['user_id', 'sub_level_id']);
      return; // done, don't unlock next level yet
    }

    // If we reach here, all sub-levels in this level are completed
    // Unlock default sub-level of the next level
    final nextLevel = await supabase
        .from('levels')
        .select()
        .gt('id', levelId)
        .order('id', ascending: true)
        .limit(1)
        .maybeSingle();

    if (nextLevel != null) {
      final nextDefaultSub = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', nextLevel['id'])
          .eq('is_default', true)
          .maybeSingle();

      if (nextDefaultSub != null) {
        await supabase.from('user_levels').upsert({
          'user_id': user.id,
          'sub_level_id': nextDefaultSub['id'],
          'is_unlocked': true,
          'is_completed': false,
        }, onConflict: ['user_id', 'sub_level_id']);
      }
    }
  }
}

/*import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  // Load all levels (biomes)
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final levels = await supabase.from('levels').select();
    return levels;
  }

  // Load sub-levels for a specific level
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final subLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .order('order_index');

    final unlockedRows = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id);

    return subLevels.map((s) {
      final unlocked = unlockedRows.any((u) =>
          u['sub_level_id'] == s['id'] && u['is_unlocked'] == true);
      return {
        ...s,
        'is_unlocked': unlocked || s['is_default'] == true,
      };
    }).toList();
  }

  // Unlock next sub-level after completing current
  Future<void> unlockNextSubLevel(int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final current = await supabase
        .from('sub_levels')
        .select()
        .eq('id', subLevelId)
        .maybeSingle();

    if (current == null) return;

    final nextSubLevel = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', current['level_id'])
        .gt('order_index', current['order_index'])
        .order('order_index', ascending: true)
        .limit(1)
        .maybeSingle();

    if (nextSubLevel != null) {
      await supabase.from('user_levels').upsert({
        'user_id': user.id,
        'sub_level_id': nextSubLevel['id'],
        'is_unlocked': true,
      });
    }
  }

  // Mark a sub-level as completed
  Future<void> completeSubLevel(int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_levels').upsert({
      'user_id': user.id,
      'sub_level_id': subLevelId,
      'is_completed': true,
      'is_unlocked': true,
    });

    await unlockNextSubLevel(subLevelId);
  }
}*/
