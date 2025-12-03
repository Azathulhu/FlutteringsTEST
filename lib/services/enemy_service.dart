import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../game/enemy.dart';

class SpawnEntry {
  final Enemy prototype;
  final double weight;
  final int minSpawn;
  final int maxSpawn;

  SpawnEntry({
    required this.prototype,
    required this.weight,
    required this.minSpawn,
    required this.maxSpawn,
  });
}

class EnemyService {
  final supabase = Supabase.instance.client;
  final Random _rand = Random();

  Future<List<SpawnEntry>> loadSpawnPoolForSubLevel(
      int subLevelId, double spawnX, double spawnY) async {
    final poolRows = await supabase
        .from('sub_level_enemies')
        .select('spawn_rate, min_spawn, max_spawn, rarity_multiplier, enemies(*)')
        .eq('sub_level_id', subLevelId);

    if (poolRows == null || poolRows.isEmpty) return [];

    List<SpawnEntry> pool = [];

    for (var row in poolRows) {
      final e = row['enemies'];
      if (e == null) continue;

      final behavior = Map<String, dynamic>.from(e['behavior'] ?? {});

      final prototype = Enemy.fromMap(
        x: spawnX,
        y: spawnY,
        name: e['name'] ?? 'enemy',
        spritePath: e['sprite_path'] ?? '',
        maxHealth: (e['max_health'] ?? 50) as int,
        damage: (e['damage'] ?? 10) as int,
        speed: (e['speed'] ?? 150.0).toDouble(),
        behavior: behavior,
      );

      final weight =
          ((row['spawn_rate'] ?? 1.0) * (row['rarity_multiplier'] ?? 1.0))
              .toDouble();
      final minSpawn = (row['min_spawn'] ?? 1) as int;
      final maxSpawn = (row['max_spawn'] ?? 3) as int;

      pool.add(SpawnEntry(
          prototype: prototype, weight: weight, minSpawn: minSpawn, maxSpawn: maxSpawn));
    }

    return pool;
  }

  /// Pick random enemy from pool, considering weights, min/max spawn
  List<Enemy> pickRandomFromPool(
      List<SpawnEntry> pool, double spawnX, double spawnY) {
    if (pool.isEmpty) return [];

    double totalWeight = pool.fold(0, (p, e) => p + e.weight);

    double r = _rand.nextDouble() * totalWeight;

    SpawnEntry? selected;

    for (var entry in pool) {
      if (r <= entry.weight) {
        selected = entry;
        break;
      }
      r -= entry.weight;
    }

    selected ??= pool.last;

    int count =
        selected.minSpawn + _rand.nextInt(selected.maxSpawn - selected.minSpawn + 1);

    return List.generate(
        count, (_) => selected!.prototype.cloneAt(spawnX, spawnY));
  }
}



/*import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../game/enemy.dart';

class SpawnEntry {
  final Enemy prototype;
  final double weight;
  SpawnEntry({required this.prototype, required this.weight});
}

class EnemyService {
  final supabase = Supabase.instance.client;

  /// Load spawn pool for a sublevel. Returns list of SpawnEntry (prototypes).
  Future<List<SpawnEntry>> loadSpawnPoolForSubLevel(int subLevelId, double spawnX, double spawnY) async {
    final poolRows = await supabase
        .from('sub_level_enemies')
        .select('spawn_rate, enemies(*)')
        .eq('sub_level_id', subLevelId);

    if (poolRows == null || poolRows.isEmpty) return [];

    final List<SpawnEntry> pool = [];
    for (var row in poolRows) {
      final e = row['enemies'];
      if (e == null) continue;

      // Behavior may be JSONB - ensure it's Map<String, dynamic>
      final Map<String, dynamic> behavior = Map<String, dynamic>.from(e['behavior'] ?? {});

      final prototype = Enemy.fromMap(
        x: spawnX,
        y: spawnY,
        name: e['name'] ?? 'enemy',
        spritePath: e['sprite_path'] ?? '',
        maxHealth: (e['max_health'] ?? 50) as int,
        damage: (e['damage'] ?? 10) as int,
        speed: (e['speed'] ?? 150.0).toDouble(),
        behavior: behavior,
      );

      final weight = (row['spawn_rate'] ?? 1.0).toDouble();

      pool.add(SpawnEntry(prototype: prototype, weight: weight));
    }

    return pool;
  }

  /// Pick a random prototype from pool (weights considered) and clone it with spawn coords
  Enemy? pickRandomFromPool(List<SpawnEntry> pool, double spawnX, double spawnY) {
    if (pool.isEmpty) return null;
    final total = pool.fold<double>(0, (p, e) => p + e.weight);
    double r = Random().nextDouble() * total;
    for (var entry in pool) {
      if (r <= entry.weight) {
        // clone prototype to new actual instance (preserve behavior)
        return entry.prototype.cloneAt(spawnX, spawnY);
      }
      r -= entry.weight;
    }
    // fallback
    return pool.last.prototype.cloneAt(spawnX, spawnY);
  }
}*/
