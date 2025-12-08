// lib/services/level_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  // Load all levels with unlocked info
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final levelsRes = await supabase.from('levels').select().order('id', ascending: true);
    final levels = (levelsRes as List<dynamic>).cast<Map<String, dynamic>>();

    final userLevelsRes = await supabase.from('user_levels').select('level_id').eq('user_id', user.id);
    final unlockedLevelIds = (userLevelsRes as List<dynamic>).map((e) => e['level_id'] as int).toSet();

    return levels.map((lvl) {
      final isUnlocked = lvl['is_default'] == true || unlockedLevelIds.contains(lvl['id']);
      return {
        ...lvl,
        'is_unlocked': isUnlocked,
      };
    }).toList();
  }

  // Load sub-levels with unlocked/completed info
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final subsRes = await supabase.from('sub_levels').select().eq('level_id', levelId).order('order_index');
    final subLevels = (subsRes as List<dynamic>).cast<Map<String, dynamic>>();

    if (subLevels.isEmpty) return [];

    final userSubsRes = await supabase
        .from('user_sub_levels')
        .select()
        .eq('user_id', user.id)
        .filter('sub_level_id', 'in', '(${subLevels.map((s) => s['id']).join(",")})');
    final userRows = (userSubsRes as List<dynamic>).cast<Map<String, dynamic>>();

    return subLevels.map((sl) {
      final found = userRows.firstWhere((u) => u['sub_level_id'] == sl['id'], orElse: () => {});
      final isUnlocked = found.isNotEmpty ? (found['is_unlocked'] == true) : (sl['is_default'] == true);
      final isCompleted = found.isNotEmpty ? (found['is_completed'] == true) : false;
      return {
        ...sl,
        'is_unlocked': isUnlocked,
        'is_completed': isCompleted,
      };
    }).toList();
  }

  // Complete a sub-level and unlock next sub-level / next level
  Future<void> completeSubLevel(int subLevelId, int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_sub_levels').upsert({
      'user_id': user.id,
      'sub_level_id': subLevelId,
      'is_unlocked': true,
      'is_completed': true,
    });

    final subLevels = await supabase.from('sub_levels').select('id').eq('level_id', levelId).order('order_index');
    final subIds = (subLevels as List<dynamic>).map((s) => s['id'] as int).toList();

    // Check if all sub-levels completed
    final userSubsRes = await supabase
        .from('user_sub_levels')
        .select()
        .eq('user_id', user.id)
        .filter('sub_level_id', 'in', '(${subIds.join(",")})');
    final userSubs = (userSubsRes as List<dynamic>).cast<Map<String, dynamic>>();

    final allCompleted = subIds.every((id) {
      final row = userSubs.firstWhere((u) => u['sub_level_id'] == id, orElse: () => {});
      return row.isNotEmpty && row['is_completed'] == true;
    });

    // Unlock next level if all sub-levels complete
    if (allCompleted) {
      final nextLevelRes = await supabase
          .from('levels')
          .select('id')
          .gt('id', levelId)
          .order('id')
          .limit(1)
          .maybeSingle();
      if (nextLevelRes != null) {
        await supabase.from('user_levels').upsert({
          'user_id': user.id,
          'level_id': nextLevelRes['id'],
          'is_unlocked': true,
        });
      }
    }
  }

  // Check if all sub-levels in a level are completed
  Future<bool> areAllSubLevelsCompleted(int levelId, String userId) async {
    final subLevelsRes = await supabase.from('sub_levels').select('id').eq('level_id', levelId);
    final subIds = (subLevelsRes as List<dynamic>).map((s) => s['id'] as int).toList();
    if (subIds.isEmpty) return false;

    final userSubsRes = await supabase.from('user_sub_levels').select().eq('user_id', userId);
    final userSubs = (userSubsRes as List<dynamic>).cast<Map<String, dynamic>>();

    return subIds.every((id) {
      final row = userSubs.firstWhere((u) => u['sub_level_id'] == id, orElse: () => {});
      return row.isNotEmpty && row['is_completed'] == true;
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
