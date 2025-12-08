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
      final userMeta = await supabase
          .from('users_meta')
          .select('unlocked_levels')
          .eq('user_id', user.id)
          .maybeSingle();

      final List<int> unlockedLevelIds =
          List<int>.from(userMeta?['unlocked_levels'] ?? []);

      return allLevels.map<Map<String, dynamic>>((level) {
        final isUnlocked = unlockedLevelIds.contains(level['id']) ||
            (level['is_default'] == true && unlockedLevelIds.isEmpty);
        return {...level, 'is_unlocked': isUnlocked};
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

      final userSubLevels = await supabase
          .from('user_levels')
          .select()
          .eq('user_id', user.id)
          .filter(
            'sub_level_id',
            'in',
            '(${subLevels.map((s) => s['id']).join(',')})',
          );

      return subLevels.map((s) {
        final Map<String, dynamic>? userRow = userSubLevels.firstWhere(
          (u) => u['sub_level_id'] == s['id'],
          orElse: () => {},
        );
        final unlocked = (userRow.isNotEmpty &&
                (userRow['is_unlocked'] == true || userRow['is_completed'] == true)) ||
            s['is_default'] == true;
        return {...s, 'is_unlocked': unlocked};
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

      // 1) Unlock the next sub-level in the same level
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
        }, onConflict: 'user_id,sub_level_id');
        return;
      }

      // 2) Unlock first sub-level of next level
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

          // Also update unlocked_levels in users_meta
          final userMeta = await supabase
              .from('users_meta')
              .select('unlocked_levels')
              .eq('user_id', user.id)
              .maybeSingle();
          final List<int> unlocked =
              List<int>.from(userMeta?['unlocked_levels'] ?? []);
          if (!unlocked.contains(nextLevel['id'])) unlocked.add(nextLevel['id']);
          await supabase
              .from('users_meta')
              .update({'unlocked_levels': unlocked})
              .eq('user_id', user.id);
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

      // Mark current sub-level as completed & unlocked
      await supabase.from('user_levels').upsert({
        'user_id': user.id,
        'sub_level_id': subLevelId,
        'is_completed': true,
        'is_unlocked': true,
      }, onConflict: 'user_id,sub_level_id');

      // Unlock next sub-level
      await unlockNextSubLevel(subLevelId);
    } catch (e, st) {
      debugPrint('completeSubLevel ERROR: $e\n$st');
    }
  }

  /// Called when a new account is created
  Future<void> initializeNewUser(String userId) async {
    try {
      final defaultLevel = await supabase
          .from('levels')
          .select()
          .eq('is_default', true)
          .limit(1)
          .maybeSingle();

      if (defaultLevel == null) return;

      final defaultSubLevel = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', defaultLevel['id'])
          .eq('is_default', true)
          .limit(1)
          .maybeSingle();

      await supabase.from('users_meta').upsert({
        'user_id': userId,
        'unlocked_levels': [defaultLevel['id']],
      }, onConflict: 'user_id');

      if (defaultSubLevel != null) {
        await supabase.from('user_levels').upsert({
          'user_id': userId,
          'sub_level_id': defaultSubLevel['id'],
          'is_unlocked': true,
        }, onConflict: 'user_id,sub_level_id');
      }
    } catch (e, st) {
      debugPrint('initializeNewUser ERROR: $e\n$st');
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
