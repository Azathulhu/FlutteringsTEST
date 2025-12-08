import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

import '../game/character.dart';
import '../game/world.dart';
import '../game/platform.dart';
import '../game/enemy.dart';
import '../game/projectile.dart';
import '../game/weapon.dart';
import '../services/weapon_service.dart';
import '../services/enemy_service.dart';
import '../services/level_service.dart';
import 'level_selection_page.dart';

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;
  final VoidCallback? onLevelComplete;

  GamePage({required this.level, required this.subLevel, this.onLevelComplete});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late Character character;
  late World world;

  double screenWidth = 0;
  double screenHeight = 0;

  late AnimationController _controller;
  StreamSubscription? _accelerometerSubscription;

  bool gameOver = false;
  bool paused = false;
  bool levelComplete = false;

  final double spawnYOffset = 150;
  final Random random = Random();

  List<Enemy> enemies = [];
  Weapon? equippedWeapon;
  List<Projectile> activeProjectiles = [];

  double timeSinceLastShot = 0.0;
  double weaponAngle = 0.0;

  final double weaponW = 48.0;
  final double weaponH = 24.0;
  final double projW = 48.0;
  final double projH = 24.0;

  double latestTiltX = 0.0;
  double gravity = 800.0;

  int currentWave = 1;
  late int maxWaves;
  Map<int, List<WaveEntry>> wavePool = {};

  final double minSpawnInterval = 1.0;
  final double maxSpawnInterval = 3.0;
  double nextSpawnIn = 0.0;

  late EnemyService enemyService;
  late WeaponService weaponService;
  late LevelService levelService;

  Map<int, List<int>> originalWaveCounts = {};

  @override
  void initState() {
    super.initState();
    levelService = LevelService();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadGameData();
      nextSpawnIn = 0.5 + random.nextDouble();
      startGameLoop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    enemyService = EnemyService();
    weaponService = WeaponService();

    wavePool = await enemyService.loadWavePool(widget.subLevel['id'], 0, -120);
    maxWaves = enemyService.getMaxWave(wavePool);

    for (var entry in wavePool.entries) {
      originalWaveCounts[entry.key] = entry.value.map((e) => e.remaining).toList();
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final metaRaw = await supabase.from('users_meta').select().eq('user_id', user.id).maybeSingle();
    final meta = metaRaw as Map<String, dynamic>?;
    if (meta == null || meta['selected_character_id'] == null) return;

    final charRaw = await supabase.from('characters').select()
        .eq('id', meta['selected_character_id'])
        .maybeSingle();
    final charData = charRaw as Map<String, dynamic>?;
    if (charData == null) return;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    character = Character(
      x: screenWidth / 2 - 40,
      y: screenHeight - spawnYOffset - 80,
      width: 80,
      height: 80,
      jumpStrength: charData['jump_strength']?.toDouble() ?? 20.0,
      spritePath: charData['sprite_path'],
      horizontalSpeedMultiplier: charData['speed']?.toDouble() ?? 200.0,
      maxHealth: (charData['max_health'] ?? 100) as int,
      currentHealth: (charData['current_health'] ?? 100) as int,
    );

    world = World(screenWidth: screenWidth, screenHeight: screenHeight, character: character);

    _addStartingPlatform();

    final results = await Future.wait([
      weaponService.getUserWeapon(user.id),
    ]);

    equippedWeapon = results[0] as Weapon?;

    List<Future> precacheFutures = [];
    precacheFutures.add(precacheImage(AssetImage(character.spritePath), context));
    if (equippedWeapon != null) {
      precacheFutures.add(precacheImage(AssetImage(equippedWeapon!.spritePath), context));
      precacheFutures.add(precacheImage(AssetImage(equippedWeapon!.projectile.spritePath), context));
    }
    await Future.wait(precacheFutures);
  }

  void startGameLoop() {
    _lastTime = DateTime.now();
    _controller = AnimationController(vsync: this)..addListener(_gameTick);
    _controller.repeat(min: 0, max: 1, period: Duration(milliseconds: 16));

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!paused) {
        latestTiltX = -event.x;
        character.facingRight = latestTiltX > 0.1 ? true : latestTiltX < -0.1 ? false : character.facingRight;
      }
    });
  }

  late DateTime _lastTime;

  void _gameTick() {
    final now = DateTime.now();
    double dt = now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;
    dt = dt.clamp(0.016, 0.033);

    if (!paused && !gameOver) {
      _updateSpawner(dt);
      _updateEnemies(dt);
      world.update(latestTiltX, dt);
      updateWeapon(dt);
      _checkGameOver();
      setState(() {});
    }
  }

  void _updateSpawner(double dt) {
    if (wavePool[currentWave] == null || wavePool[currentWave]!.isEmpty) return;

    nextSpawnIn -= dt;
    if (nextSpawnIn <= 0) {
      Enemy? enemy = enemyService.pickRandomFromWave(
          wavePool[currentWave]!, random.nextDouble() * (screenWidth - 80), -60 - random.nextDouble() * 120);

      if (enemy != null) {
        enemies.add(enemy);
        nextSpawnIn = minSpawnInterval + random.nextDouble() * (maxSpawnInterval - minSpawnInterval);
      }
    }

    if (enemyService.isWaveComplete(wavePool[currentWave]!, enemies)) {
      if (currentWave < maxWaves) {
        currentWave++;
        nextSpawnIn = 0.5;
      } else if (!levelComplete) {
        levelComplete = true;
        paused = true;
        _showCompleteDialog();
      }
    }
  }

  void _updateEnemies(double dt) {
    for (int i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      e.update(character, dt);

      for (int j = e.activeProjectiles.length - 1; j >= 0; j--) {
        final p = e.activeProjectiles[j];
        p.update(dt);

        if (p.x >= character.x &&
            p.x <= character.x + character.width &&
            p.y >= character.y &&
            p.y <= character.y + character.height) {
          character.takeDamage(p.damage);
          e.activeProjectiles.removeAt(j);
          continue;
        }

        if (p.x < 0 || p.x > screenWidth || p.y < 0 || p.y > screenHeight) {
          e.activeProjectiles.removeAt(j);
        }
      }

      if (e.y > screenHeight + 200) enemies.removeAt(i);
    }

    if (character.currentHealth <= 0 && !gameOver) {
      gameOver = true;
      paused = true;
      _showGameOverDialog();
    }
  }

  void updateWeapon(double dt) {
    timeSinceLastShot += dt;

    if (equippedWeapon != null && enemies.isNotEmpty) {
      enemies.sort((a, b) {
        double da = ((a.x + a.width/2) - (character.x + character.width/2)).abs() +
                    ((a.y + a.height/2) - (character.y + character.height/2)).abs();
        double db = ((b.x + b.width/2) - (character.x + character.width/2)).abs() +
                    ((b.y + b.height/2) - (character.y + character.height/2)).abs();
        return da.compareTo(db);
      });

      final target = enemies.first;
      double dx = (target.x + target.width / 2) - (character.x + character.width / 2);
      double dy = (target.y + target.height / 2) - (character.y + character.height / 2);
      weaponAngle = atan2(dy, dx);

      double fireInterval = 1 / max(0.0001, equippedWeapon!.fireRate);
      if (timeSinceLastShot >= fireInterval) {
        timeSinceLastShot = 0;

        Projectile proj = Projectile(
          x: character.x + character.width / 2,
          y: character.y + character.height / 2,
          speed: equippedWeapon!.projectile.speed,
          damage: equippedWeapon!.damage,
          spritePath: equippedWeapon!.projectile.spritePath,
        );

        double dist = sqrt(dx * dx + dy * dy);
        proj.vx = dx / dist * proj.speed;
        proj.vy = dy / dist * proj.speed;

        activeProjectiles.add(proj);
      }
    }

    for (int i = activeProjectiles.length - 1; i >= 0; i--) {
      final p = activeProjectiles[i];
      p.update(dt);

      bool shouldRemove = false;

      for (int j = enemies.length - 1; j >= 0; j--) {
        final e = enemies[j];

        if (!(p.x + projW / 2 < e.x ||
              p.x - projW / 2 > e.x + e.width ||
              p.y + projH / 2 < e.y ||
              p.y - projH / 2 > e.y + e.height)) {
          e.currentHealth -= p.damage;
          shouldRemove = true;
          if (e.currentHealth <= 0) enemies.removeAt(j);
          break;
        }
      }

      if (!shouldRemove) {
        if (p.x + projW / 2 < 0 ||
            p.x - projW / 2 > screenWidth ||
            p.y + projH / 2 < 0 ||
            p.y - projH / 2 > screenHeight) {
          shouldRemove = true;
        }
      }

      if (shouldRemove) activeProjectiles.removeAt(i);
    }
  }

  void _checkGameOver() {
    if (character.y > screenHeight && !gameOver) {
      gameOver = true;
      paused = true;
      _showGameOverDialog();
    }
  }

  void _addStartingPlatform() {
    world.platforms.clear();
    world.platforms.add(Platform(
      x: screenWidth / 2 - 60,
      y: screenHeight - spawnYOffset,
      width: 120,
      height: 20,
    ));
  }

  Future<bool> _onWillPop() async {
    paused = true;
    bool? result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Are you sure you want to go back?"),
        actions: [
          TextButton(
            onPressed: () {
              paused = false;
              Navigator.of(context).pop(false);
            },
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Yes"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showCompleteDialog() async {
    await levelService.completeSubLevel(widget.subLevel['id']);

    // call the callback to refresh sub-levels
    if (widget.onLevelComplete != null) {
      widget.onLevelComplete!();
    }

    setState(() {
      levelComplete = true;
      paused = true;
    });

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Level Complete!"),
        content: Text("Congratulations! You've completed this sub-level."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: Text("Back"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: Text("Try Again"),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Game Over"),
        content: Text("Do you want to try again?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LevelSelectionPage()),
              );
            },
            child: Text("Back"),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    paused = false;
    gameOver = false;
    levelComplete = false;
    enemies.clear();
    activeProjectiles.clear();
    character.x = screenWidth / 2 - character.width / 2;
    character.y = screenHeight - spawnYOffset - character.height;
    character.vy = 0;
    character.currentHealth = character.maxHealth;
    nextSpawnIn = 0.5;
    currentWave = 1;

    for (var entry in wavePool.entries) {
      for (int i = 0; i < entry.value.length; i++) {
        entry.value[i].remaining = originalWaveCounts[entry.key]![i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/background/${widget.level['background_image']}",
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
            ...world.platforms.map((p) => Positioned(
              bottom: screenHeight - p.y,
              left: p.x,
              child: Container(
                width: p.width,
                height: p.height,
                color: Colors.brown,
              ),
            )),
            ...enemies.map((e) => Positioned(
              bottom: screenHeight - e.y - e.height,
              left: e.x,
              child: e.buildWidget(),
            )),
            ...enemies.expand((e) => e.activeProjectiles.map((p) {
              final left = p.x - projW / 2;
              final bottom = screenHeight - p.y - projH / 2;
              final angle = atan2(p.vy, p.vx);
              return Positioned(
                left: left,
                bottom: bottom,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: projW,
                    height: projH,
                    child: Image.asset(
                      p.spritePath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              );
            })),
            Positioned(
              bottom: screenHeight - character.y - character.height,
              left: character.x,
              child: character.buildWidget(),
            ),
            if (equippedWeapon != null)
              Positioned(
                bottom: screenHeight - (character.y + character.height / 2) - weaponH / 2,
                left: character.x + character.width / 2 - weaponW / 2,
                child: Transform.rotate(
                  angle: weaponAngle,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: weaponW,
                    height: weaponH,
                    child: Image.asset(
                      equippedWeapon!.spritePath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              ),
            ...activeProjectiles.map((p) {
              final left = p.x - projW / 2;
              final bottom = screenHeight - p.y - projH / 2;
              final angle = atan2(p.vy, p.vx);
              return Positioned(
                left: left,
                bottom: bottom,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: projW,
                    height: projH,
                    child: Image.asset(
                      p.spritePath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              );
            }),
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                children: List.generate(maxWaves, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      height: 12,
                      decoration: BoxDecoration(
                        color: (i + 1) <= currentWave ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                width: 160,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: character.currentHealth / character.maxHealth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

import '../game/character.dart';
import '../game/world.dart';
import '../game/platform.dart';
import '../game/enemy.dart';
import '../game/projectile.dart';
import '../game/weapon.dart';
import '../services/weapon_service.dart';
import '../services/enemy_service.dart';
import '../services/level_service.dart';
import 'level_selection_page.dart';

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;

  GamePage({required this.level, required this.subLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late Character character;
  late World world;

  double screenWidth = 0;
  double screenHeight = 0;

  late AnimationController _controller;
  StreamSubscription? _accelerometerSubscription;

  bool gameOver = false;
  bool paused = false;
  bool levelComplete = false;

  final double spawnYOffset = 150;
  final Random random = Random();

  List<Enemy> enemies = [];
  Weapon? equippedWeapon;
  List<Projectile> activeProjectiles = [];

  double timeSinceLastShot = 0.0;
  double weaponAngle = 0.0;

  final double weaponW = 48.0;
  final double weaponH = 24.0;
  final double projW = 48.0;
  final double projH = 24.0;

  // Accelerometer
  double latestTiltX = 0.0;

  // Gravity (can also come from Supabase or sublevel)
  double gravity = 800.0;

  int currentWave = 1;
  late int maxWaves;
  Map<int, List<WaveEntry>> wavePool = {};

  final double minSpawnInterval = 1.0;
  final double maxSpawnInterval = 3.0;
  double nextSpawnIn = 0.0;

  late EnemyService enemyService;
  late WeaponService weaponService;

  late LevelService levelService;


  Map<int, List<int>> originalWaveCounts = {};

  @override
  void initState() {
    super.initState();
    levelService = LevelService();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadGameData();
      nextSpawnIn = 0.5 + random.nextDouble();
      startGameLoop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    enemyService = EnemyService();
    weaponService = WeaponService();

    // Load waves
    wavePool = await enemyService.loadWavePool(widget.subLevel['id'], 0, -120);
    maxWaves = enemyService.getMaxWave(wavePool);

    // Save original counts for restart
    for (var entry in wavePool.entries) {
      originalWaveCounts[entry.key] = entry.value.map((e) => e.remaining).toList();
    }

    // Load user character
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final metaRaw = await supabase.from('users_meta').select().eq('user_id', user.id).maybeSingle();
    final meta = metaRaw as Map<String, dynamic>?;
    if (meta == null || meta['selected_character_id'] == null) return;

    final charRaw = await supabase.from('characters').select()
        .eq('id', meta['selected_character_id'])
        .maybeSingle();
    final charData = charRaw as Map<String, dynamic>?;
    if (charData == null) return;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    character = Character(
      x: screenWidth / 2 - 40,
      y: screenHeight - spawnYOffset - 80,
      width: 80,
      height: 80,
      jumpStrength: charData['jump_strength']?.toDouble() ?? 20.0,
      spritePath: charData['sprite_path'],
      horizontalSpeedMultiplier: charData['speed']?.toDouble() ?? 200.0,
      maxHealth: (charData['max_health'] ?? 100) as int,
      currentHealth: (charData['current_health'] ?? 100) as int,
    );

    world = World(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      character: character,
    );

    _addStartingPlatform();

    final results = await Future.wait([
      weaponService.getUserWeapon(user.id),
    ]);

    equippedWeapon = results[0] as Weapon?;

    // Precache images
    List<Future> precacheFutures = [];
    precacheFutures.add(precacheImage(AssetImage(character.spritePath), context));
    if (equippedWeapon != null) {
      precacheFutures.add(precacheImage(AssetImage(equippedWeapon!.spritePath), context));
      precacheFutures.add(precacheImage(AssetImage(equippedWeapon!.projectile.spritePath), context));
    }
    await Future.wait(precacheFutures);
  }

  void startGameLoop() {
    _lastTime = DateTime.now();
    _controller = AnimationController(vsync: this)..addListener(_gameTick);
    _controller.repeat(min: 0, max: 1, period: Duration(milliseconds: 16));

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!paused) {
        latestTiltX = -event.x;
        if (latestTiltX > 0.1) character.facingRight = true;
        else if (latestTiltX < -0.1) character.facingRight = false;
      }
    });
  }

  late DateTime _lastTime;

  void _gameTick() {
    final now = DateTime.now();
    double dt = now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;
    dt = dt.clamp(0.016, 0.033);

    if (!paused && !gameOver) {
      _updateSpawner(dt);
      _updateEnemies(dt);
      world.update(latestTiltX, dt);
      updateWeapon(dt);
      _checkGameOver();
      setState(() {});
    }
  }

  void _updateSpawner(double dt) {
    if (wavePool[currentWave] == null || wavePool[currentWave]!.isEmpty) return;

    nextSpawnIn -= dt;
    if (nextSpawnIn <= 0) {
      Enemy? enemy = enemyService.pickRandomFromWave(
          wavePool[currentWave]!, random.nextDouble() * (screenWidth - 80), -60 - random.nextDouble() * 120);

      if (enemy != null) {
        enemies.add(enemy);
        nextSpawnIn = minSpawnInterval + random.nextDouble() * (maxSpawnInterval - minSpawnInterval);
      }
    }

    if (enemyService.isWaveComplete(wavePool[currentWave]!, enemies)) {
      if (currentWave < maxWaves) {
        currentWave++;
        nextSpawnIn = 0.5;
      } else {
        levelComplete = true; // <-- prevent repeated dialogs
        paused = true;  
        _showCompleteDialog();
      }
    }
  }

  void _updateEnemies(double dt) {
    for (int i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      e.update(character, dt);

      for (int j = e.activeProjectiles.length - 1; j >= 0; j--) {
        final p = e.activeProjectiles[j];
        p.update(dt);

        if (p.x >= character.x &&
            p.x <= character.x + character.width &&
            p.y >= character.y &&
            p.y <= character.y + character.height) {
          character.takeDamage(p.damage);
          e.activeProjectiles.removeAt(j);
          continue;
        }

        if (p.x < 0 || p.x > screenWidth || p.y < 0 || p.y > screenHeight) {
          e.activeProjectiles.removeAt(j);
        }
      }

      if (e.y > screenHeight + 200) enemies.removeAt(i);
    }

    if (character.currentHealth <= 0 && !gameOver) {
      gameOver = true;
      paused = true;
      _showGameOverDialog();
    }
  }

  void updateWeapon(double dt) {
    timeSinceLastShot += dt;

    if (equippedWeapon != null && enemies.isNotEmpty) {
      enemies.sort((a, b) {
        double da = ((a.x + a.width/2) - (character.x + character.width/2)).abs() +
                    ((a.y + a.height/2) - (character.y + character.height/2)).abs();
        double db = ((b.x + b.width/2) - (character.x + character.width/2)).abs() +
                    ((b.y + b.height/2) - (character.y + character.height/2)).abs();
        return da.compareTo(db);
      });

      final target = enemies.first;
      double dx = (target.x + target.width / 2) - (character.x + character.width / 2);
      double dy = (target.y + target.height / 2) - (character.y + character.height / 2);
      weaponAngle = atan2(dy, dx);

      double fireInterval = 1 / max(0.0001, equippedWeapon!.fireRate);
      if (timeSinceLastShot >= fireInterval) {
        timeSinceLastShot = 0;

        Projectile proj = Projectile(
          x: character.x + character.width / 2,
          y: character.y + character.height / 2,
          speed: equippedWeapon!.projectile.speed,
          damage: equippedWeapon!.damage,
          spritePath: equippedWeapon!.projectile.spritePath,
        );

        double dist = sqrt(dx * dx + dy * dy);
        proj.vx = dx / dist * proj.speed;
        proj.vy = dy / dist * proj.speed;

        activeProjectiles.add(proj);
      }
    }

    for (int i = activeProjectiles.length - 1; i >= 0; i--) {
      final p = activeProjectiles[i];
      p.update(dt);

      bool shouldRemove = false;

      for (int j = enemies.length - 1; j >= 0; j--) {
        final e = enemies[j];

        final pLeft = p.x - projW / 2;
        final pRight = p.x + projW / 2;
        final pTop = p.y - projH / 2;
        final pBottom = p.y + projH / 2;

        final eLeft = e.x;
        final eRight = e.x + e.width;
        final eTop = e.y;
        final eBottom = e.y + e.height;

        if (!(pRight < eLeft || pLeft > eRight || pBottom < eTop || pTop > eBottom)) {
          e.currentHealth -= p.damage;
          shouldRemove = true;
          if (e.currentHealth <= 0) enemies.removeAt(j);
          break;
        }
      }

      if (!shouldRemove) {
        if (p.x + projW / 2 < 0 ||
            p.x - projW / 2 > screenWidth ||
            p.y + projH / 2 < 0 ||
            p.y - projH / 2 > screenHeight) {
          shouldRemove = true;
        }
      }

      if (shouldRemove) activeProjectiles.removeAt(i);
    }
  }

  void _checkGameOver() {
    if (character.y > screenHeight && !gameOver) {
      gameOver = true;
      paused = true;
      _showGameOverDialog();
    }
  }

  void _addStartingPlatform() {
    world.platforms.clear();
    world.platforms.add(Platform(
      x: screenWidth / 2 - 60,
      y: screenHeight - spawnYOffset,
      width: 120,
      height: 20,
    ));
  }

  Future<bool> _onWillPop() async {
    paused = true;
    bool? result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Are you sure you want to go back?"),
        actions: [
          TextButton(
            onPressed: () {
              paused = false;
              Navigator.of(context).pop(false);
            },
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Yes"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showCompleteDialog() async {
    // Complete the sub-level in Supabase and unlock the next one
    await levelService.completeSubLevel(
      widget.subLevel['id'],
      widget.level['id'],
    );
  
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: Text("COMPLETE!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LevelSelectionPage()),
              );
            },
            child: Text("Back"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: Text("Try Again"),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Game Over"),
        content: Text("Do you want to try again?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LevelSelectionPage()),
              );
            },
            child: Text("Back"),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    paused = false;
    gameOver = false;
    levelComplete = false;
    enemies.clear();
    activeProjectiles.clear();
    character.x = screenWidth / 2 - character.width / 2;
    character.y = screenHeight - spawnYOffset - character.height;
    character.vy = 0;
    character.currentHealth = character.maxHealth;
    nextSpawnIn = 0.5;
    currentWave = 1;

    // reset wave remaining counts
    for (var entry in wavePool.entries) {
      for (int i = 0; i < entry.value.length; i++) {
        entry.value[i].remaining = originalWaveCounts[entry.key]![i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/background/${widget.level['background_image']}",
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
            ...world.platforms.map((p) => Positioned(
              bottom: screenHeight - p.y,
              left: p.x,
              child: Container(
                width: p.width,
                height: p.height,
                color: Colors.brown,
              ),
            )),
            ...enemies.map((e) => Positioned(
              bottom: screenHeight - e.y - e.height,
              left: e.x,
              child: e.buildWidget(),
            )),
            ...enemies.expand((e) => e.activeProjectiles.map((p) {
              final left = p.x - projW / 2;
              final bottom = screenHeight - p.y - projH / 2;
              final angle = atan2(p.vy, p.vx);
              return Positioned(
                left: left,
                bottom: bottom,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: projW,
                    height: projH,
                    child: Image.asset(
                      p.spritePath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              );
            })),
            Positioned(
              bottom: screenHeight - character.y - character.height,
              left: character.x,
              child: character.buildWidget(),
            ),
            if (equippedWeapon != null)
              Positioned(
                bottom: screenHeight - (character.y + character.height / 2) - weaponH / 2,
                left: character.x + character.width / 2 - weaponW / 2,
                child: Transform.rotate(
                  angle: weaponAngle,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: weaponW,
                    height: weaponH,
                    child: Image.asset(
                      equippedWeapon!.spritePath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              ),
            ...activeProjectiles.map((p) {
              final left = p.x - projW / 2;
              final bottom = screenHeight - p.y - projH / 2;
              final angle = atan2(p.vy, p.vx);
              return Positioned(
                left: left,
                bottom: bottom,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: projW,
                    height: projH,
                    child: Image.asset(
                      p.spritePath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              );
            }),
            // waves
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                children: List.generate(maxWaves, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      height: 12,
                      decoration: BoxDecoration(
                        color: (i + 1) <= currentWave ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                width: 160,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: character.currentHealth / character.maxHealth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/
