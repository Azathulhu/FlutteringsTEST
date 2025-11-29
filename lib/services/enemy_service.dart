import 'package:supabase_flutter/supabase_flutter.dart';
import '../game/enemy.dart';

class EnemyService {
  final supabase = Supabase.instance.client;

  Future<List<Enemy>> loadEnemiesForSubLevel(int subLevelId, double spawnX, double spawnY) async {
    final pool = await supabase
        .from('sub_level_enemies')
        .select('enemy_id, enemies(*)')
        .eq('sub_level_id', subLevelId);

    if (pool.isEmpty) return [];

    final enemies = <Enemy>[];
    for (var row in pool) {
      final e = row['enemies'];
      enemies.add(Enemy(
        x: spawnX,
        y: spawnY,
        name: e['name'],
        spritePath: e['sprite_path'],
        maxHealth: e['max_health'],
        damage: e['damage'],
        speed: e['speed'].toDouble(),
        behavior: e['behavior'],
      ));
    }

    return enemies;
  }
}
