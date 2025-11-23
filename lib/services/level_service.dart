import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  // Load all levels with their sub-levels and unlock status
  Future<List<Map<String, dynamic>>> loadLevels() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final levels = await supabase.from('levels').select();
    final subLevels = await supabase.from('sub_levels').select();
    final userLevels = await supabase
        .from('user_levels')
        .select()
        .eq('user_id', user.id);

    return levels.map((lvl) {
      final subs = subLevels.where((s) => s['level_id'] == lvl['id']).toList();

      final updatedSubs = subs.map((sub) {
        final userSub = userLevels.firstWhere(
          (u) => u['level_id'] == lvl['id'] && u['sub_level_id'] == sub['id'],
          orElse: () => {},
        );
        return {
          ...sub,
          'is_unlocked': userSub['is_unlocked'] ?? sub['is_default'] ?? false,
          'is_completed': userSub['is_completed'] ?? false,
        };
      }).toList();

      return {
        ...lvl,
        'sub_levels': updatedSubs,
      };
    }).toList();
  }

  // Unlock a level/sub-level
  Future<void> unlockSubLevel(int levelId, int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_levels').upsert({
      'user_id': user.id,
      'level_id': levelId,
      'sub_level_id': subLevelId,
      'is_unlocked': true,
    });
  }

  // Mark a level/sub-level as completed
  Future<void> completeSubLevel(int levelId, int subLevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_levels').upsert({
      'user_id': user.id,
      'level_id': levelId,
      'sub_level_id': subLevelId,
      'is_unlocked': true,
      'is_completed': true,
    });
  }
}
