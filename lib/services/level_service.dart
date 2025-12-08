import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  /// Load all levels (biomes) with proper progression
  Future<List<Map<String, dynamic>>> loadLevels() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final allLevels = await supabase.from('levels').select().order('id');

      List<Map<String, dynamic>> unlockedLevels = [];

      for (var level in allLevels) {
        if (level['is_default'] == true) {
          unlockedLevels.add({...level, 'is_unlocked': true});
        } else {
          final prevLevelId = level['id'] - 1;
          final prevSubLevels = await supabase
              .from('sub_levels')
              .select()
              .eq('level_id', prevLevelId);

          if (prevSubLevels.isEmpty) {
            // No previous sublevels — keep locked
            unlockedLevels.add({...level, 'is_unlocked': false});
            continue;
          }

          final prevSubLevelIds = prevSubLevels.map((s) => s['id']).toList();

          // Use filter with properly formatted "(1,2,3)" for the 'in' operator
          final completedPrev = await supabase
              .from('user_levels')
              .select()
              .eq('user_id', user.id)
              .filter('sub_level_id', 'in', '(${prevSubLevelIds.join(',')})')
              .eq('is_completed', true);

          unlockedLevels.add({
            ...level,
            'is_unlocked': completedPrev.length == prevSubLevels.length,
          });
        }
      }

      return unlockedLevels;
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

      final subLevelIds = subLevels.map((s) => s['id']).toList();

      // If there are no sublevels, return empty list
      if (subLevelIds.isEmpty) {
        return subLevels.map<Map<String, dynamic>>((s) => {...s, 'is_unlocked': s['is_default'] == true}).toList();
      }

      final unlockedRows = await supabase
          .from('user_levels')
          .select()
          .eq('user_id', user.id)
          .filter('sub_level_id', 'in', '(${subLevelIds.join(',')})');

      return subLevels.map((s) {
        final unlocked = unlockedRows.any((u) =>
            u['sub_level_id'] == s['id'] &&
            (u['is_unlocked'] == true || u['is_completed'] == true));
        return {
          ...s,
          'is_unlocked': unlocked || s['is_default'] == true,
        };
      }).toList();
    } catch (e, st) {
      debugPrint('loadSubLevels ERROR: $e\n$st');
      return [];
    }
  }

  /// Unlock next sub-level after completing current
  Future<void> unlockNextSubLevel(int subLevelId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final current = await supabase
          .from('sub_levels')
          .select()
          .eq('id', subLevelId)
          .maybeSingle();

      if (current == null) return;

      // 1) Unlock the next sub-level in the same level (by order_index)
      final nextSubLevel = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', current['level_id'])
          .gt('order_index', current['order_index'])
          .order('order_index', ascending: true)
          .limit(1)
          .maybeSingle();

      if (nextSubLevel != null) {
        // upsert using onConflict as a string: 'user_id,sub_level_id'
        await supabase.from('user_levels').upsert({
          'user_id': user.id,
          'sub_level_id': nextSubLevel['id'],
          'is_unlocked': true,
        }, onConflict: 'user_id,sub_level_id');
        return;
      }

      // 2) No next sub-level in this level -> unlock first sub-level of next level
      final nextLevel = await supabase
          .from('levels')
          .select()
          .gt('id', current['level_id'])
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
          final firstSubLevel = nextLevelSubLevels.first;
          await supabase.from('user_levels').upsert({
            'user_id': user.id,
            'sub_level_id': firstSubLevel['id'],
            'is_unlocked': true,
          }, onConflict: 'user_id,sub_level_id');
        }
      }
    } catch (e, st) {
      debugPrint('unlockNextSubLevel ERROR: $e\n$st');
    }
  }

  /// Mark a sub-level as completed and handle unlocking progression
  Future<void> completeSubLevel(int subLevelId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1) Mark current sub-level as completed & unlocked (create row if needed)
      await supabase.from('user_levels').upsert({
        'user_id': user.id,
        'sub_level_id': subLevelId,
        'is_completed': true,
        'is_unlocked': true,
      }, onConflict: 'user_id,sub_level_id');

      // 2) Unlock next sub-level (or first of next level)
      await unlockNextSubLevel(subLevelId);

      // 3) Check if all sub-levels in current level are completed; if yes, unlock next level
      final levelRow = await supabase
          .from('sub_levels')
          .select('level_id')
          .eq('id', subLevelId)
          .maybeSingle();
      if (levelRow == null) return;

      final currentLevelId = levelRow['level_id'];

      final currentSubLevels = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', currentLevelId);

      final currentSubLevelIds = currentSubLevels.map((s) => s['id']).toList();

      if (currentSubLevelIds.isEmpty) return;

      final completedRows = await supabase
          .from('user_levels')
          .select()
          .eq('user_id', user.id)
          .filter('sub_level_id', 'in', '(${currentSubLevelIds.join(',')})')
          .eq('is_completed', true);

      if (completedRows.length == currentSubLevels.length) {
        final nextLevel = await supabase
            .from('levels')
            .select()
            .gt('id', currentLevelId)
            .order('id', ascending: true)
            .limit(1)
            .maybeSingle();

        if (nextLevel != null) {
          // append to unlocked_levels array in users_meta using .update + append map
          await supabase
              .from('users_meta')
              .update({
                'unlocked_levels': {'append': [nextLevel['id']]}
              })
              .eq('user_id', user.id);
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
