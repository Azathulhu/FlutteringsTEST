import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  /// Load all levels, marking them as locked/unlocked based on users_meta
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final levels = await supabase.from('levels').select().order('id');
    final meta = await supabase
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    final unlockedLevels = (meta?['unlocked_levels'] as List?)?.cast<int>() ?? [];

    return levels.map((lvl) {
      return {
        ...lvl,
        'is_unlocked': unlockedLevels.contains(lvl['id']) || lvl['is_default'] == true,
      };
    }).toList();
  }

  /// Load sub-levels for a specific level, marking them unlocked/completed
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final subLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .order('order_index');

    final userSubLevels = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id);

    return subLevels.map((s) {
      final unlocked = userSubLevels.any((u) =>
          u['sub_level_id'] == s['id'] && u['is_unlocked'] == true);
      final completed = userSubLevels.any((u) =>
          u['sub_level_id'] == s['id'] && u['is_completed'] == true);

      return {
        ...s,
        'is_unlocked': unlocked || s['is_default'] == true,
        'is_completed': completed,
      };
    }).toList();
  }

  /// Unlock the next sub-level in the same level
  Future<void> unlockNextSubLevel(int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final current = await supabase
        .from('sub_levels')
        .select()
        .eq('id', subLevelId)
        .maybeSingle();

    if (current == null) return;

    // Next sub-level in the same level
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
    } else {
      // If no next sub-level, all sub-levels complete, unlock next level
      await unlockNextLevel(current['level_id']);
    }
  }

  /// Complete a sub-level
  Future<void> completeSubLevel(int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Mark current sub-level as completed & unlocked
    await supabase.from('user_levels').upsert({
      'user_id': user.id,
      'sub_level_id': subLevelId,
      'is_completed': true,
      'is_unlocked': true,
    });

    // Unlock next sub-level (or next level if last)
    await unlockNextSubLevel(subLevelId);
  }

  /// Unlock the next level if all sub-levels of current level are completed
  Future<void> unlockNextLevel(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final currentSubLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId);

    final completedSubLevels = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id)
        .eq('is_completed', true)
        .in_('sub_level_id', currentSubLevels.map((s) => s['id']).toList());

    if (completedSubLevels.length == currentSubLevels.length) {
      // All sub-levels complete, unlock next level
      final nextLevel = await supabase
          .from('levels')
          .select()
          .gt('id', levelId)
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();

      if (nextLevel != null) {
        // Add to user's unlocked_levels array
        final meta = await supabase
            .from('users_meta')
            .select('unlocked_levels')
            .eq('user_id', user.id)
            .maybeSingle();

        final unlocked = (meta?['unlocked_levels'] as List?)?.cast<int>() ?? [];
        if (!unlocked.contains(nextLevel['id'])) {
          unlocked.add(nextLevel['id']);
          await supabase
              .from('users_meta')
              .update({'unlocked_levels': unlocked})
              .eq('user_id', user.id);

          // Unlock first sub-level in the new level
          final firstSub = await supabase
              .from('sub_levels')
              .select()
              .eq('level_id', nextLevel['id'])
              .order('order_index')
              .limit(1)
              .maybeSingle();

          if (firstSub != null) {
            await supabase.from('user_levels').upsert({
              'user_id': user.id,
              'sub_level_id': firstSub['id'],
              'is_unlocked': true,
            });
          }
        }
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
