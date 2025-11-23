import 'package:supabase_flutter/supabase_flutter.dart';

class LevelService {
  final supabase = Supabase.instance.client;

  // Get all levels
  Future<List<Map<String, dynamic>>> getLevels() async {
    return await supabase.from('levels').select();
  }

  // Get sublevels of a level + whether user unlocked it
  Future<List<Map<String, dynamic>>> getSublevels(int levelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final sublevels = await supabase
        .from('sublevels')
        .select()
        .eq('level_id', levelId)
        .order('order_index');

    final progressRows = await supabase
        .from('user_progress')
        .select()
        .eq('user_id', user.id);

    return sublevels.map((s) {
      final completed = progressRows.any(
        (p) => p['sublevel_id'] == s['id'] && p['completed'] == true,
      );
      final orderIndex = s['order_index'];
      // Unlock first sublevel or if previous sublevel is completed
      final unlocked = orderIndex == 1 ||
          progressRows.any(
              (p) => p['sublevel_id'] == (orderIndex - 1) && p['completed'] == true);
      return {...s, 'completed': completed, 'is_unlocked': unlocked};
    }).toList();
  }

  // Mark sublevel as completed
  Future<void> completeSublevel(int sublevelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_progress').upsert({
      'user_id': user.id,
      'sublevel_id': sublevelId,
      'completed': true,
    });
  }
}
