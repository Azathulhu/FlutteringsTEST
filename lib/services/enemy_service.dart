// lib/services/enemy_service.dart
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../game/enemy.dart';

class SpawnEntry {
  final Enemy prototype;
  final double weight;
  final int maxActive;         // max per sublevel
  final double rarityMultiplier; // optional for rare enemies
  int activeCount = 0;         // track how many are alive

  SpawnEntry({
    required this.prototype,
    required this.weight,
    this.maxActive = 3,
    this.rarityMultiplier = 1.0,
  });
}

class EnemyService {
  final supabase = Supabase.instance.client;
  final Random random = Random();

  /// Load spawn pool for sublevel
  Future<List<SpawnEntry>> loadSpawnPoolForSubLevel(
      int subLevelId, double spawnX, double spawnY) async {
    final poolRows = await supabase
        .from('sub_level_enemies')
        .select('spawn_rate, max_active, rarity_multiplier, enemies(*)')
        .eq('sub_level_id', subLevelId);

    if (poolRows == null || poolRows.isEmpty) return [];

    final List<SpawnEntry> pool = [];

    for (var row in poolRows) {
      final e = row['enemies'];
      if (e == null) continue;

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

      final weight =
          (row['spawn_rate'] ?? 1.0).toDouble() * (row['rarity_multiplier'] ?? 1.0);

      pool.add(SpawnEntry(
        prototype: prototype,
        weight: weight,
        maxActive: row['max_active'] ?? 3,
        rarityMultiplier: row['rarity_multiplier']?.toDouble() ?? 1.0,
      ));
    }

    return pool;
  }

  /// Pick a random enemy considering weight & maxActive
  Enemy? pickRandomFromPool(List<SpawnEntry> pool, double spawnX, double spawnY) {
    if (pool.isEmpty) return null;

    // Filter entries under maxActive
    final availablePool = pool.where((e) => e.activeCount < e.maxActive).toList();
    if (availablePool.isEmpty) return null;

    final totalWeight = availablePool.fold<double>(0, (sum, e) => sum + e.weight);
    double r = random.nextDouble() * totalWeight;

    for (var entry in availablePool) {
      if (r <= entry.weight) {
        entry.activeCount += 1;
        return entry.prototype.cloneAt(spawnX, spawnY);
      }
      r -= entry.weight;
    }

    // fallback
    final last = availablePool.last;
    last.activeCount += 1;
    return last.prototype.cloneAt(spawnX, spawnY);
  }

  /// Call this when an enemy dies to decrement active count
  void notifyEnemyDeath(List<SpawnEntry> pool, Enemy enemy) {
    final entry = pool.firstWhere(
      (e) => e.prototype.name == enemy.name,
      orElse: () => null,
    );
    if (entry != null) {
      entry.activeCount = max(0, entry.activeCount - 1);
    }
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
