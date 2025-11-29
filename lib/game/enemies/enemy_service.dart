import 'package:supabase_flutter/supabase_flutter.dart';
import 'enemy.dart';
import 'dart:math';

class EnemyService {
  final supabase = Supabase.instance.client;
  final Random random = Random();

  Future<List<Enemy>> loadEnemiesForSubLevel(int subLevelId) async {
    final enemyRows = await supabase
        .from('sub_level_enemies')
        .select('enemy_id, enemies(*)')
        .eq('sub_level_id', subLevelId)
        .execute();

    if (enemyRows.error != null) return [];

    List<Enemy> enemies = [];
    for (final row in enemyRows.data) {
      final e = row['enemies'];
      enemies.add(Enemy(
        x: 100 + random.nextDouble() * 200, // random spawn x
        y: 100 + random.nextDouble() * 200, // random spawn y
        width: 50,
        height: 50,
        health: e['health'] ?? 50,
        spritePath: "assets/enemies/${e['sprite_path']}",
        behavior: e['behavior'] ?? {},
      ));
    }

    return enemies;
  }
}
