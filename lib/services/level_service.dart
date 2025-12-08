import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> loadLevels() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final userMeta = await supabase
          .from('users_meta')
          .select('unlocked_levels')
          .eq('user_id', user.id)
          .maybeSingle();

      final unlockedLevels =
          (userMeta?['unlocked_levels'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              [];

      final allLevels =
          await supabase.from('levels').select().order('id');

      return allLevels.map<Map<String, dynamic>>((level) {
        final levelId = level['id'] as int;

        return {
          ...level,
          'is_unlocked': unlockedLevels.contains(levelId) ||
              level['is_default'] == true,
        };
      }).toList();
    } catch (e, st) {
      debugPrint('loadLevels ERROR: $e\n$st');
      return [];
    }
  }

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

        final isUnlocked = userRow != null
            ? (userRow['is_unlocked'] == true ||
                userRow['is_completed'] == true)
            : s['is_default'] == true;

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

  /// NEW FIXED SIGNATURE
  Future<void> completeSubLevel(String userId, int subLevelId) async {
    try {
      /// 1. mark this sub-level complete + unlocked
      await supabase.from('user_levels').upsert({
        'user_id': userId,
        'sub_level_id': subLevelId,
        'is_completed': true,
        'is_unlocked': true,
      }, onConflict: 'user_id,sub_level_id');

      /// 2. get this sub-level
      final current = await supabase
          .from('sub_levels')
          .select()
          .eq('id', subLevelId)
          .maybeSingle();

      if (current == null) return;

      final levelId = current['level_id'] as int;
      final orderIndex = current['order_index'] as int;

      /// 3. fetch sub levels in order
      final subLevels = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', levelId)
          .order('order_index');

      /// 4. find next sub-level
      Map<String, dynamic>? nextSubLevel;
      for (var s in subLevels) {
        if ((s['order_index'] as int) > orderIndex) {
          nextSubLevel = s;
          break;
        }
      }

      if (nextSubLevel != null) {
        /// unlock next sub-level
        await supabase.from('user_levels').upsert({
          'user_id': userId,
          'sub_level_id': nextSubLevel['id'],
          'is_unlocked': true,
        }, onConflict: 'user_id,sub_level_id');

        return;
      }

      /// no next sub level → move to next level
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
            'user_id': userId,
            'sub_level_id': firstSub['id'],
            'is_unlocked': true,
          }, onConflict: 'user_id,sub_level_id');

          /// ADD next level id to unlocked_levels (NO RAW)
          final userMeta = await supabase
              .from('users_meta')
              .select('unlocked_levels')
              .eq('user_id', userId)
              .maybeSingle();

          List<int> unlockedLevels =
              List<int>.from(userMeta?['unlocked_levels'] ?? []);

          if (!unlockedLevels.contains(nextLevel['id'])) {
            unlockedLevels.add(nextLevel['id']);
            await supabase
                .from('users_meta')
                .update({'unlocked_levels': unlockedLevels})
                .eq('user_id', userId);
          }
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
