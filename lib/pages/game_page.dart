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
import '../services/weapon_service.dart'; // adjust path to match your project


import '../services/enemy_service.dart';
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

  final double spawnYOffset = 150;
  final Random random = Random();

  List<Enemy> enemies = [];
  List<SpawnEntry> spawnPool = [];

  // Spawner config
  double nextSpawnIn = 0.0; // seconds until next spawn
  final double minSpawnInterval = 1.0;
  final double maxSpawnInterval = 3.0;
  //final int maxActiveEnemies = 6;
  int maxActiveEnemies = 6;

  // Timing
  late DateTime _lastTime;

  Weapon? equippedWeapon;
  List<Projectile> activeProjectiles = [];
  double timeSinceLastShot = 0.0;

  double weaponAngle = 0.0;

  @override
  void initState() {
    super.initState();
    maxActiveEnemies = widget.subLevel['max_active_enemies'] ?? 6;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCharacter();
      await prepareSpawnPool();
      // give a small delay before first spawn so player sees descending
      nextSpawnIn = 0.5 + random.nextDouble() * 1.0;
      startGameLoop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
  //
  Future<void> loadWeapon() async {
    final weaponService = WeaponService();
    final user = supabase.auth.currentUser;
    if (user != null) {
      equippedWeapon = await weaponService.getUserWeapon(user.id);
    }
  }

  // update the updateWeapon() function
  void updateWeapon(double dt) {
    if (equippedWeapon == null || enemies.isEmpty) return;
  
    timeSinceLastShot += dt;
  
    // Find nearest enemy
    enemies.sort((a, b) {
      double da = ((a.x - character.x).abs() + (a.y - character.y).abs());
      double db = ((b.x - character.x).abs() + (b.y - character.y).abs());
      return da.compareTo(db);
    });
  
    final target = enemies.first;
  
    // Weapon rotation
    double dx = target.x + target.width / 2 - (character.x + character.width / 2);
    double dy = target.y + target.height / 2 - (character.y + character.height / 2);
    weaponAngle = atan2(dy, dx);
  
    // Auto-shoot
    double fireInterval = 1 / equippedWeapon!.fireRate;
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
  
    // Update projectiles
    for (int i = activeProjectiles.length - 1; i >= 0; i--) {
      final p = activeProjectiles[i];
      p.update(dt);
  
      // Collision check
      for (int j = enemies.length - 1; j >= 0; j--) {
        final e = enemies[j];
        if (p.x < e.x + e.width &&
            p.x + 20 > e.x &&
            p.y < e.y + e.height &&
            p.y + 20 > e.y) {
          e.currentHealth -= p.damage;
          activeProjectiles.removeAt(i);
          if (e.currentHealth <= 0) {
            enemies.removeAt(j);
          }
          break;
        }
      }
  
      // Remove projectiles off-screen
      if (p.x < 0 || p.x > screenWidth || p.y < 0 || p.y > screenHeight) {
        activeProjectiles.removeAt(i);
      }
    }
  }
  //

  Future<void> prepareSpawnPool() async {
    final enemyService = EnemyService();
    // spawn coords are placeholders; clones will be placed at chosen spawn X/Y
    spawnPool = await enemyService.loadSpawnPoolForSubLevel(
      widget.subLevel['id'],
      0,
      -120,
    );
  }

  Future<void> loadCharacter() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final meta = await supabase
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (meta == null || meta['selected_character_id'] == null) return;

    final charData = await supabase
        .from('characters')
        .select()
        .eq('id', meta['selected_character_id'])
        .maybeSingle();

    if (charData == null) return;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    character = Character(
      x: screenWidth / 2 - 40,
      y: screenHeight - spawnYOffset - 80,
      width: 80,
      height: 80,
      jumpStrength: charData['jump_strength']?.toDouble() ?? 20,
      spritePath: charData['sprite_path'],
      horizontalSpeedMultiplier: 2.0,
      maxHealth: (charData['max_health'] ?? 100) as int,
      currentHealth: (charData['current_health'] ?? 100) as int,
    );

    world = World(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      character: character,
    );

    _addStartingPlatform();
  }

  void startGameLoop() {
    _lastTime = DateTime.now();
    _controller = AnimationController(vsync: this)..addListener(_gameTick);
    _controller.repeat(min: 0, max: 1, period: Duration(milliseconds: 16));

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!paused) {
        double tiltX = -event.x;
        if (tiltX > 0.1) {
          character.facingRight = true;
        } else if (tiltX < -0.1) {
          character.facingRight = false;
        }
        world.update(tiltX);
      }
    });
  }

  void _gameTick() {
    final now = DateTime.now();
    double dt = now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;
  
    // Clamp dt to avoid physics glitches (slow-mo or spikes)
    dt = dt.clamp(0.016, 0.033); // ~30–60 FPS
  
    if (!paused && !gameOver) {
      _updateSpawner(dt);
      _updateEnemies(dt);
  
      // Update character's vertical movement using vy
      character.y += character.vy * dt;
  
      // Optional: clamp to screen
      //character.y = character.y.clamp(0, screenHeight - character.height);
  
      _checkGameOver();
      setState(() {});
    }
  }
  
  void _updateSpawner(double dt) {
    if (spawnPool.isEmpty) return;
    nextSpawnIn -= dt;
    if (nextSpawnIn <= 0 && enemies.length < maxActiveEnemies) {
      final spawnX = random.nextDouble() * (screenWidth - 80);
      final spawnY = -60.0 - random.nextDouble() * 120.0;
      final enemyService = EnemyService();
      final prototype = enemyService.pickRandomFromPool(spawnPool, spawnX, spawnY);
      if (prototype != null) {
        enemies.add(prototype);
      }
      nextSpawnIn = minSpawnInterval + random.nextDouble() * (maxSpawnInterval - minSpawnInterval);
    }
  }

  void _updateEnemies(double dt) {
    for (int i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      e.update(character, dt);
  
      // remove enemies that fall too far below the screen
      if (e.y > screenHeight + 200) {
        enemies.removeAt(i);
      }
    }
  
    // check if player is dead
    if (character.currentHealth <= 0 && !gameOver) {
      gameOver = true;
      paused = true;
      _showGameOverDialog();
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
    enemies.clear();
    character.x = screenWidth / 2 - character.width / 2;
    character.y = screenHeight - spawnYOffset - character.height;
    character.vy = 0;
    character.currentHealth = character.maxHealth;
    _addStartingPlatform();
    nextSpawnIn = 0.5;
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
            Positioned(
              bottom: screenHeight - character.y - character.height,
              left: character.x,
              child: character.buildWidget(),
            ),

                        // Weapon sprite in hand
            if (equippedWeapon != null)
              Positioned(
                left: character.x + character.width / 2 - 16,
                top: character.y + character.height / 2 - 16,
                child: Transform.rotate(
                  angle: weaponAngle, // now uses field instead of undefined "angle"
                  alignment: Alignment.center,
                  child: Image.asset(
                    equippedWeapon!.spritePath,
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            
            // Projectiles
            ...activeProjectiles.map((p) => p.buildWidget()),

            // Bottom-right health bar
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
                    Center(
                      child: Text(
                        "${character.currentHealth}/${character.maxHealth} HP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
