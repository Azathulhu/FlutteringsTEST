import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  /// Load levels with correct unlock status
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final allLevels = await supabase.from('levels').select().order('id');

    // Fetch unlocked_levels from users_meta
    final userMeta = await supabase.from('users_meta').select('unlocked_levels').eq('user_id', user.id).maybeSingle();
    final unlockedLevels = List<int>.from(userMeta?['unlocked_levels'] ?? []);

    return allLevels.map((level) {
      return {
        ...level,
        'is_unlocked': unlockedLevels.contains(level['id']),
      };
    }).toList();
  }

  /// Load sub-levels with proper unlocks
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final subLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .order('order_index');

    if (subLevels.isEmpty) return [];

    final subLevelIds = subLevels.map((s) => s['id']).toList();

    final userSubLevels = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id)
        .filter('sub_level_id', 'in', '(${subLevelIds.join(',')})');

    return subLevels.map((s) {
      final userRow = userSubLevels.firstWhere(
        (u) => u['sub_level_id'] == s['id'],
        orElse: () => null,
      );
      return {
        ...s,
        'is_unlocked': userRow != null ? userRow['is_unlocked'] || userRow['is_completed'] : false,
      };
    }).toList();
  }

  /// Complete a sub-level and unlock next one instantly
  Future<void> completeSubLevel(int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1️⃣ Mark current sub-level as completed & unlocked
    await supabase.from('user_levels').upsert({
      'user_id': user.id,
      'sub_level_id': subLevelId,
      'is_completed': true,
      'is_unlocked': true,
    }, onConflict: 'user_id,sub_level_id');

    // 2️⃣ Unlock next sub-level in same level
    final currentSub = await supabase.from('sub_levels').select('id, level_id, order_index').eq('id', subLevelId).maybeSingle();
    if (currentSub == null) return;

    final nextSub = await supabase
        .from('sub_levels')
        .select('id')
        .eq('level_id', currentSub['level_id'])
        .gt('order_index', currentSub['order_index'])
        .order('order_index', ascending: true)
        .limit(1)
        .maybeSingle();

    if (nextSub != null) {
      await supabase.from('user_levels').upsert({
        'user_id': user.id,
        'sub_level_id': nextSub['id'],
        'is_unlocked': true,
      }, onConflict: 'user_id,sub_level_id');
    } else {
      // 3️⃣ If no more sub-levels in this level, unlock next level & its default sub-level
      final nextLevel = await supabase
          .from('levels')
          .select('id')
          .gt('id', currentSub['level_id'])
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();

      if (nextLevel != null) {
        final nextLevelId = nextLevel['id'];

        // Append next level to unlocked_levels
        await supabase.from('users_meta').update({
          'unlocked_levels': supabase.rpc('array_append', args: ['unlocked_levels', nextLevelId])
        }).eq('user_id', user.id);

        // Unlock default sub-level of next level
        final defaultSub = await supabase
            .from('sub_levels')
            .select('id')
            .eq('level_id', nextLevelId)
            .eq('is_default', true)
            .maybeSingle();

        if (defaultSub != null) {
          await supabase.from('user_levels').upsert({
            'user_id': user.id,
            'sub_level_id': defaultSub['id'],
            'is_unlocked': true,
          }, onConflict: 'user_id,sub_level_id');
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
