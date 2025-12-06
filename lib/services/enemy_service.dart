// lib/services/enemy_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../game/enemy.dart';

/// Represents a spawn entry for a wave: prototype, spawn rate, and remaining count.
class WaveEntry {
  final Enemy prototype;
  final double spawnRate;
  int remaining; // how many left to spawn in this wave

  WaveEntry({
    required this.prototype,
    required this.spawnRate,
    required this.remaining,
  });
}

class EnemyService {
  final supabase = Supabase.instance.client;

  /// Loads wave pool for a sublevel.
  /// Returns a map: waveNumber -> list of WaveEntry
  Future<Map<int, List<WaveEntry>>> loadWavePool(
      int subLevelId, double spawnX, double spawnY) async {
    final poolRows = await supabase
        .from('sub_level_enemies')
        .select('wave_number, quantity, spawn_rate, enemies(*)')
        .eq('sub_level_id', subLevelId);

    if (poolRows == null || poolRows.isEmpty) return {};

    final Map<int, List<WaveEntry>> wavePool = {};

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

      int waveNumber = row['wave_number'] ?? 1;
      int quantity = row['quantity'] ?? 1;
      double spawnRate = (row['spawn_rate'] ?? 1.0).toDouble();

      if (!wavePool.containsKey(waveNumber)) wavePool[waveNumber] = [];
      wavePool[waveNumber]!.add(
        WaveEntry(prototype: prototype, spawnRate: spawnRate, remaining: quantity),
      );
    }

    return wavePool;
  }

  /// Pick a random enemy from a wave list based on spawn rate weights
  Enemy? pickRandomFromWave(List<WaveEntry> waveEntries, double spawnX, double spawnY) {
    final available = waveEntries.where((w) => w.remaining > 0).toList();
    if (available.isEmpty) return null;

    final totalWeight = available.fold<double>(0, (sum, w) => sum + w.spawnRate);
    double r = Random().nextDouble() * totalWeight;

    for (var entry in available) {
      if (r <= entry.spawnRate) {
        entry.remaining--;
        return entry.prototype.cloneAt(spawnX, spawnY);
      }
      r -= entry.spawnRate;
    }

    // fallback
    final last = available.last;
    last.remaining--;
    return last.prototype.cloneAt(spawnX, spawnY);
  }

  /// Checks if the current wave is complete (all enemies spawned and dead)
  bool isWaveComplete(List<WaveEntry> waveEntries, List<Enemy> activeEnemies) {
    final remainingEnemies = waveEntries.fold<int>(0, (sum, w) => sum + w.remaining);
    return remainingEnemies <= 0 && activeEnemies.isEmpty;
  }

  /// Get the maximum wave number from the pool
  int getMaxWave(Map<int, List<WaveEntry>> wavePool) {
    if (wavePool.isEmpty) return 1;
    return wavePool.keys.reduce(max);
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
