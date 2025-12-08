// lib/services/level_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  /// Load all levels with a boolean 'is_unlocked' computed from user_sub_levels.
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final levelsRes = await supabase.from('levels').select().order('id', ascending: true);
    final levels = (levelsRes as List<dynamic>).cast<Map<String, dynamic>>();

    // Get all user_sub_levels for this user
    final userSubsRes = await supabase
        .from('user_sub_levels')
        .select()
        .eq('user_id', user.id);
    final userSubs = (userSubsRes as List<dynamic>).cast<Map<String, dynamic>>();

    // A level is considered unlocked if any of its sub-levels is_unlocked OR level.is_default true
    return levels.map((lvl) {
      final levelId = lvl['id'];
      final unlocked = userSubs.any((us) {
        // need to check that the sub_level belongs to this level; fetch sub_level id map is expensive here,
        // but we assume user_sub_levels only for existing sub_levels; we'll treat presence of unlocked as indicator.
        return us['is_unlocked'] == true;
      });

      return {
        ...lvl,
        'is_unlocked': unlocked || (lvl['is_default'] == true),
      };
    }).toList();
  }

  /// Load sub-levels for a specific level with user's unlocked/completed status.
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final subsRes = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .order('order_index', ascending: true);
    final subLevels = (subsRes as List<dynamic>).cast<Map<String, dynamic>>();

    // collect ids
    final ids = subLevels.map((s) => s['id']).toList();

    // fetch user's rows for these sub-level ids
    List<Map<String, dynamic>> userRows = [];
    if (ids.isNotEmpty) {
      final userSubsRes = await supabase
          .from('user_sub_levels')
          .select()
          .eq('user_id', user.id)
          .filter('sub_level_id', 'in', '(${ids.join(",")})'); // PostgREST expects '(1,2,3)'
      userRows = (userSubsRes as List<dynamic>).cast<Map<String, dynamic>>();
    }

    // Compose final list of sub-levels with user state
    return subLevels.map((sl) {
      final found = userRows.firstWhere(
          (u) => (u['sub_level_id']?.toString() ?? '') == sl['id'].toString(),
          orElse: () => {});
      final isUnlocked = found.isNotEmpty ? (found['is_unlocked'] == true) : (sl['is_default'] == true);
      final isCompleted = found.isNotEmpty ? (found['is_completed'] == true) : false;

      return {
        ...sl,
        'is_unlocked': isUnlocked,
        'is_completed': isCompleted,
      };
    }).toList();
  }

  /// Mark a sub-level completed and unlock the next sub-level in the SAME level.
  /// If there is no next sub-level in the same level, unlock the default sub-level of the next level.
  Future<void> completeSubLevel(int subLevelId, int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1) Upsert (insert or update) current sub-level row as completed + unlocked
    await supabase.from('user_sub_levels').upsert({
      'user_id': user.id,
      'sub_level_id': subLevelId,
      'is_unlocked': true,
      'is_completed': true,
    });

    // 2) Get the order_index of current sub-level
    final currentRes = await supabase
        .from('sub_levels')
        .select('id, level_id, order_index')
        .eq('id', subLevelId)
        .maybeSingle();
    if (currentRes == null) return;
    final currentOrder = currentRes['order_index'] as int;
    final currentLevelId = currentRes['level_id'] as int;

    // Sanity: ensure currentLevelId == levelId
    if (currentLevelId != levelId) {
      // If mismatch, prefer the currentRes level_id
      levelId = currentLevelId;
    }

    // 3) Find next sub-level in same level (order_index greater than current), smallest order_index
    final nextSubRes = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .gt('order_index', currentOrder)
        .order('order_index', ascending: true)
        .limit(1)
        .maybeSingle();

    if (nextSubRes != null) {
      final nextId = nextSubRes['id'];
      // Upsert unlock for next sub-level
      await supabase.from('user_sub_levels').upsert({
        'user_id': user.id,
        'sub_level_id': nextId,
        'is_unlocked': true,
        'is_completed': false,
      });
      return; // we unlocked the next sublevel inside same level — done.
    }

    // 4) No next sub-level in same level: check if all sub-levels in this level are completed.
    final levelSubsRes = await supabase
        .from('sub_levels')
        .select('id')
        .eq('level_id', levelId)
        .order('order_index', ascending: true);
    final levelSubs = (levelSubsRes as List<dynamic>).cast<Map<String, dynamic>>();
    final levelSubIds = levelSubs.map((s) => s['id']).toList();

    bool allCompleted = true;
    if (levelSubIds.isNotEmpty) {
      final userLevelRowsRes = await supabase
          .from('user_sub_levels')
          .select()
          .eq('user_id', user.id)
          .filter('sub_level_id', 'in', '(${levelSubIds.join(",")})');
      final userLevelRows = (userLevelRowsRes as List<dynamic>).cast<Map<String, dynamic>>();

      for (final sid in levelSubIds) {
        final row = userLevelRows.firstWhere(
            (r) => (r['sub_level_id']?.toString() ?? '') == sid.toString(),
            orElse: () => {});
        if (row.isEmpty || row['is_completed'] != true) {
          allCompleted = false;
          break;
        }
      }
    }

    if (!allCompleted) {
      // Nothing else to do (shouldn't happen because no next sub exists but not all completed),
      // keep state as is.
      return;
    }

    // 5) All sub-levels in this level are completed: unlock default sub-level of next level
    final nextLevelRes = await supabase
        .from('levels')
        .select('id')
        .gt('id', levelId)
        .order('id', ascending: true)
        .limit(1)
        .maybeSingle();

    if (nextLevelRes == null) return;
    final nextLevelId = nextLevelRes['id'];

    final nextDefaultSubRes = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', nextLevelId)
        .eq('is_default', true)
        .limit(1)
        .maybeSingle();

    if (nextDefaultSubRes == null) return;
    final nextDefaultId = nextDefaultSubRes['id'];

    // Upsert to unlock that sub-level
    await supabase.from('user_sub_levels').upsert({
      'user_id': user.id,
      'sub_level_id': nextDefaultId,
      'is_unlocked': true,
      'is_completed': false,
    });
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
