import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../game/enemy.dart';

class WaveEntry {
  final Enemy prototype;
  final double spawnRate;
  int remaining;

  WaveEntry({
    required this.prototype,
    required this.spawnRate,
    required this.remaining,
  });
}

class EnemyService {
  final supabase = Supabase.instance.client;

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

    final last = available.last;
    last.remaining--;
    return last.prototype.cloneAt(spawnX, spawnY);
  }

  bool isWaveComplete(List<WaveEntry> waveEntries, List<Enemy> activeEnemies) {
    final remainingEnemies = waveEntries.fold<int>(0, (sum, w) => sum + w.remaining);
    return remainingEnemies <= 0 && activeEnemies.isEmpty;
  }

  int getMaxWave(Map<int, List<WaveEntry>> wavePool) {
    if (wavePool.isEmpty) return 1;
    return wavePool.keys.reduce(max);
  }
}
