import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  /// Load all levels with proper progression
  Future<List<Map<String, dynamic>>> loadLevels() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      // Get user's unlocked levels array
      final userMeta = await supabase
          .from('users_meta')
          .select('unlocked_levels')
          .eq('user_id', user.id)
          .maybeSingle();

      final unlockedLevels = (userMeta?['unlocked_levels'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [];

      final allLevels = await supabase.from('levels').select().order('id');

      return allLevels.map<Map<String, dynamic>>((level) {
        final levelId = level['id'] as int;
        return {
          ...level,
          'is_unlocked': unlockedLevels.contains(levelId) || level['is_default'] == true,
        };
      }).toList();
    } catch (e, st) {
      debugPrint('loadLevels ERROR: $e\n$st');
      return [];
    }
  }

  /// Load sub-levels for a specific level
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final subLevels = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', levelId)
          .order('order_index');

      final userLevels = await supabase
          .from('user_levels')
          .select()
          .eq('user_id', user.id);

      final Map<int, Map<String, dynamic>> userLevelMap = {
        for (var row in userLevels) row['sub_level_id'] as int: row
      };

      return subLevels.map<Map<String, dynamic>>((s) {
        final id = s['id'] as int;
        final userRow = userLevelMap[id];
        final isUnlocked =
            userRow != null ? (userRow['is_unlocked'] == true || userRow['is_completed'] == true) : s['is_default'] == true;

        return {
          ...s,
          'is_unlocked': isUnlocked,
        };
      }).toList();
    } catch (e, st) {
      debugPrint('loadSubLevels ERROR: $e\n$st');
      return [];
    }
  }

  Future<void> unlockNextSubLevel(String userId, Map<String, dynamic> currentSubLevel) async {
    // 1. Fetch all sub-levels of the same level, ordered by order_index
    final subLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', currentSubLevel['level_id'])
        .order('order_index', ascending: true) as List<dynamic>;
  
    // 2. Find the next sub-level after the current one
    int currentIndex = subLevels.indexWhere((s) => s['id'] == currentSubLevel['id']);
    if (currentIndex == -1 || currentIndex + 1 >= subLevels.length) return;
  
    final nextSubLevel = subLevels[currentIndex + 1];
  
    // 3. Fetch user's unlocked levels array
    final userMeta = await supabase
        .from('users_meta')
        .select('unlocked_levels')
        .eq('user_id', userId)
        .maybeSingle();
  
    if (userMeta == null) return;
  
    List<int> unlockedLevels = List<int>.from(userMeta['unlocked_levels'] ?? []);
  
    // 4. If next level not unlocked, append and update
    if (!unlockedLevels.contains(nextSubLevel['id'])) {
      unlockedLevels.add(nextSubLevel['id']);
  
      await supabase
          .from('users_meta')
          .update({'unlocked_levels': unlockedLevels})
          .eq('user_id', userId);
  
      // Also mark the sub-level as unlocked in user_levels table
      await supabase
          .from('user_levels')
          .upsert({
            'user_id': userId,
            'sub_level_id': nextSubLevel['id'],
            'is_unlocked': true,
          }, onConflict: ['user_id', 'sub_level_id']);
    }
  }

  /// Mark sub-level as completed & unlock next
  Future<void> completeSubLevel(int subLevelId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1) Mark current sub-level completed
      await supabase.from('user_levels').upsert({
        'user_id': user.id,
        'sub_level_id': subLevelId,
        'is_completed': true,
        'is_unlocked': true,
      }, onConflict: 'user_id,sub_level_id');

      // 2) Get current sub-level
      final current = await supabase.from('sub_levels').select().eq('id', subLevelId).maybeSingle();
      if (current == null) return;

      final levelId = current['level_id'] as int;

      // 3) Get all sub-levels of current level ordered
      final subLevels = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', levelId)
          .order('order_index');

      // 4) Find next sub-level
      Map<String, dynamic>? nextSubLevel;
      for (var s in subLevels) {
        if ((s['order_index'] as int) > (current['order_index'] as int)) {
          nextSubLevel = s;
          break;
        }
      }

      if (nextSubLevel != null) {
        // Unlock next sub-level
        await supabase.from('user_levels').upsert({
          'user_id': user.id,
          'sub_level_id': nextSubLevel['id'],
          'is_unlocked': true,
        }, onConflict: 'user_id,sub_level_id');
        return;
      }

      // 5) If no next sub-level in this level, unlock first sub-level of next level
      final nextLevel = await supabase
          .from('levels')
          .select()
          .gt('id', levelId)
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();

      if (nextLevel != null) {
        final nextLevelSubLevels = await supabase
            .from('sub_levels')
            .select()
            .eq('level_id', nextLevel['id'])
            .order('order_index');

        if (nextLevelSubLevels.isNotEmpty) {
          final firstSub = nextLevelSubLevels.first;
          await supabase.from('user_levels').upsert({
            'user_id': user.id,
            'sub_level_id': firstSub['id'],
            'is_unlocked': true,
          }, onConflict: 'user_id,sub_level_id');

          // Update unlocked_levels array in users_meta
          await supabase.from('users_meta').update({
            'unlocked_levels': (supabase.raw('array_append(unlocked_levels, ?)'), [nextLevel['id']])
          }).eq('user_id', user.id);
        }
      }
    } catch (e, st) {
      debugPrint('completeSubLevel ERROR: $e\n$st');
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
