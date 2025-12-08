// lib/services/level_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  /// Load all levels with a boolean 'is_unlocked' from user_levels table
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("No user logged in!");
      return []; // <-- This is why loading might hang
    }
  
    try {
      // Fetch all levels
      final levelsRes = await supabase.from('levels').select().order('id', ascending: true);
      final levels = (levelsRes as List<dynamic>).cast<Map<String, dynamic>>();
  
      // Fetch user's unlocked levels
      final userLevelsRes = await supabase
          .from('user_levels')
          .select('level_id')
          .eq('user_id', user.id);
      final unlockedLevelIds = (userLevelsRes as List<dynamic>)
          .map((e) => e['level_id'] as int)
          .toSet();
  
      return levels.map((lvl) {
        final isUnlocked = lvl['is_default'] == true || unlockedLevelIds.contains(lvl['id']);
        return {
          ...lvl,
          'is_unlocked': isUnlocked,
        };
      }).toList();
    } catch (e) {
      print("Error loading levels: $e");
      return [];
    }
  }

  /// Load sub-levels for a specific level with user's unlocked/completed status
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    // Fetch sub-levels for this level
    final subsRes = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .order('order_index', ascending: true);
    final subLevels = (subsRes as List<dynamic>).cast<Map<String, dynamic>>();

    // Fetch user's sub-level rows for this level
    final subIds = subLevels.map((s) => s['id']).toList();
    List<Map<String, dynamic>> userRows = [];
    if (subIds.isNotEmpty) {
      final userSubsRes = await supabase
          .from('user_sub_levels')
          .select()
          .eq('user_id', user.id)
          .filter('sub_level_id', 'in', '(${subIds.join(",")})');
      userRows = (userSubsRes as List<dynamic>).cast<Map<String, dynamic>>();
    }

    // Combine sub-level info with user status
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

  /// Mark a sub-level completed and unlock the next sub-level in the SAME level
  /// Also unlock the next level if all sub-levels in the current level are completed
  Future<void> completeSubLevel(int subLevelId, int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1) Upsert current sub-level as completed & unlocked
    await supabase.from('user_sub_levels').upsert({
      'user_id': user.id,
      'sub_level_id': subLevelId,
      'is_unlocked': true,
      'is_completed': true,
    });

    // 2) Get current sub-level info
    final currentRes = await supabase
        .from('sub_levels')
        .select('id, level_id, order_index')
        .eq('id', subLevelId)
        .maybeSingle();
    if (currentRes == null) return;
    final currentOrder = currentRes['order_index'] as int;
    final currentLevelId = currentRes['level_id'] as int;

    // 3) Unlock next sub-level in same level
    final nextSubRes = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', currentLevelId)
        .gt('order_index', currentOrder)
        .order('order_index', ascending: true)
        .limit(1)
        .maybeSingle();

    if (nextSubRes != null) {
      await supabase.from('user_sub_levels').upsert({
        'user_id': user.id,
        'sub_level_id': nextSubRes['id'],
        'is_unlocked': true,
        'is_completed': false,
      });
      return; // next sub-level unlocked, done
    }

    // 4) No next sub-level → check if all sub-levels in current level are completed
    final levelSubsRes = await supabase
        .from('sub_levels')
        .select('id')
        .eq('level_id', currentLevelId);
    final levelSubs = (levelSubsRes as List<dynamic>).cast<Map<String, dynamic>>();
    final levelSubIds = levelSubs.map((s) => s['id']).toList();

    final userLevelRowsRes = await supabase
        .from('user_sub_levels')
        .select()
        .eq('user_id', user.id)
        .filter('sub_level_id', 'in', '(${levelSubIds.join(",")})');
    final userLevelRows = (userLevelRowsRes as List<dynamic>).cast<Map<String, dynamic>>();

    final allCompleted = levelSubIds.every((sid) {
      final row = userLevelRows.firstWhere(
          (r) => (r['sub_level_id']?.toString() ?? '') == sid.toString(),
          orElse: () => {});
      return row.isNotEmpty && row['is_completed'] == true;
    });

    if (!allCompleted) return;

    // 5) All sub-levels completed → unlock next level in user_levels
    final nextLevelRes = await supabase
        .from('levels')
        .select('id')
        .gt('id', currentLevelId)
        .order('id', ascending: true)
        .limit(1)
        .maybeSingle();

    if (nextLevelRes == null) return;
    final nextLevelId = nextLevelRes['id'];

    await supabase.from('user_levels').upsert({
      'user_id': user.id,
      'level_id': nextLevelId,
      'is_unlocked': true,
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
