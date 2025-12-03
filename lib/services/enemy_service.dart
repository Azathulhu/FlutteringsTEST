// lib/services/enemy_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../game/enemy.dart';

class SpawnEntry {
  final Enemy prototype;
  final double weight;
  SpawnEntry({required this.prototype, required this.weight});
}

class EnemyService {
  final supabase = Supabase.instance.client;

  /// Load spawn pool for a sublevel.
  /// Returns a list of SpawnEntry (prototypes + spawn weight)
  Future<List<SpawnEntry>> loadSpawnPoolForSubLevel(
      int subLevelId, double spawnX, double spawnY) async {
    final poolRows = await supabase
        .from('sub_level_enemies')
        .select('spawn_rate, enemies(*)')
        .eq('sub_level_id', subLevelId);

    if (poolRows == null || poolRows.isEmpty) return [];

    final List<SpawnEntry> pool = [];

    for (var row in poolRows) {
      final e = row['enemies'];
      if (e == null) continue;

      // Make sure behavior is a Map<String, dynamic>
      final Map<String, dynamic> behavior =
          Map<String, dynamic>.from(e['behavior'] ?? {});

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

  /// Pick a random prototype from pool considering weights.
  /// Returns a cloned Enemy instance at specified spawn coordinates.
  Enemy? pickRandomFromPool(
      List<SpawnEntry> pool, double spawnX, double spawnY) {
    if (pool.isEmpty) return null;

    final totalWeight = pool.fold<double>(0, (sum, e) => sum + e.weight);
    double r = Random().nextDouble() * totalWeight;

    for (var entry in pool) {
      if (r <= entry.weight) {
        return entry.prototype.cloneAt(spawnX, spawnY);
      }
      r -= entry.weight;
    }

    // fallback in case of rounding errors
    return pool.last.prototype.cloneAt(spawnX, spawnY);
  }

  /// Optional: spawn multiple enemies at once (useful for waves later)
  List<Enemy> spawnMultipleFromPool(
      List<SpawnEntry> pool, double spawnX, double spawnY, int count) {
    final List<Enemy> spawned = [];
    for (int i = 0; i < count; i++) {
      final e = pickRandomFromPool(pool, spawnX, spawnY);
      if (e != null) spawned.add(e);
    }
    return spawned;
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
