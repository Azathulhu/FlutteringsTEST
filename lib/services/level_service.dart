import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  /// Load all levels (biomes) with proper progression
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    // Fetch all levels
    final allLevels = await supabase.from('levels').select().order('id');

    List<Map<String, dynamic>> unlockedLevels = [];

    for (var level in allLevels) {
      // Check if this level should be unlocked
      // Default level is always unlocked
      if (level['is_default'] == true) {
        unlockedLevels.add({...level, 'is_unlocked': true});
      } else {
        // Fetch sub-levels of previous level
        final prevLevelId = level['id'] - 1;
        final prevSubLevels = await supabase
            .from('sub_levels')
            .select()
            .eq('level_id', prevLevelId);

        // Fetch completed sub-levels for the user in previous level
        if (prevSubLevels.isEmpty) continue;

        final prevSubLevelIds = prevSubLevels.map((s) => s['id']).toList();

        final completedPrev = await supabase
            .from('user_levels')
            .select()
            .eq('user_id', user.id)
            .filter('sub_level_id', 'in', '(${prevSubLevelIds.join(',')})')
            .eq('is_completed', true);

        // Unlock this level only if all sub-levels of previous level are completed
        if (completedPrev.length == prevSubLevels.length) {
          unlockedLevels.add({...level, 'is_unlocked': true});
        } else {
          unlockedLevels.add({...level, 'is_unlocked': false});
        }
      }
    }

    return unlockedLevels;
  }

  /// Load sub-levels for a specific level
  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    // Fetch all sub-levels in this level
    final subLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', levelId)
        .order('order_index');

    // Fetch user's progress for these sub-levels
    final subLevelIds = subLevels.map((s) => s['id']).toList();
    final unlockedRows = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id)
        .filter('sub_level_id', 'in', '(${subLevelIds.join(',')})');

    return subLevels.map((s) {
      final unlocked = unlockedRows.any((u) =>
          u['sub_level_id'] == s['id'] && (u['is_unlocked'] == true || u['is_completed'] == true));
      return {
        ...s,
        'is_unlocked': unlocked || s['is_default'] == true,
      };
    }).toList();
  }

  /// Unlock next sub-level after completing current
  Future<void> unlockNextSubLevel(int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final current = await supabase
        .from('sub_levels')
        .select()
        .eq('id', subLevelId)
        .maybeSingle();

    if (current == null) return;

    // Unlock next sub-level in same level
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
      return;
    }

    // If no next sub-level in current level, unlock first sub-level of next level
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
        });
      }
    }
  }

  /// Mark a sub-level as completed
  // lib/services/level_service.dart

  Future<void> completeSubLevel(int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
  
    // Mark current sub-level as completed
    await supabase.from('user_levels').upsert({
      'user_id': user.id,
      'sub_level_id': subLevelId,
      'is_completed': true,
      'is_unlocked': true,
    });
  
    // Unlock next sub-level in the same level
    await unlockNextSubLevel(subLevelId);
  
    // Check if current level is fully completed to unlock next level
    final currentSubLevels = await supabase
        .from('sub_levels')
        .select()
        .eq('level_id', (await supabase.from('sub_levels').select('level_id').eq('id', subLevelId).maybeSingle())?['level_id']);
  
    final completedRows = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id)
        .in_('sub_level_id', currentSubLevels.map((s) => s['id']).toList());
  
    // If all sub-levels in current level are completed, unlock next level
    if (completedRows.length == currentSubLevels.length) {
      final currentLevelId = currentSubLevels.first['level_id'];
      final nextLevel = await supabase
          .from('levels')
          .select()
          .gt('id', currentLevelId)
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();
  
      if (nextLevel != null) {
        await supabase.from('users_meta').upsert({
          'user_id': user.id,
          'unlocked_levels': SupabasePostgrestArray.append([nextLevel['id']]),
        });
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
