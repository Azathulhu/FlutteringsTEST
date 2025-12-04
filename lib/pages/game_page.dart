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

  double nextSpawnIn = 0.0;
  final double minSpawnInterval = 1.0;
  final double maxSpawnInterval = 3.0;
  int maxActiveEnemies = 6;

  late DateTime _lastTime;

  Weapon? equippedWeapon;
  List<Projectile> activeProjectiles = [];
  double timeSinceLastShot = 0.0;
  double weaponAngle = 0.0; // stores rotation of weapon

  // scaling constants (change these to scale more/less)
  final double weaponW = 48.0;
  final double weaponH = 24.0;
  final double projW = 48.0;
  final double projH = 24.0;

  @override
  void initState() {
    super.initState();
    maxActiveEnemies = widget.subLevel['max_active_enemies'] ?? 6;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCharacter();
      await loadWeapon();
      await prepareSpawnPool();
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

  Future<void> loadWeapon() async {
    final weaponService = WeaponService();
    final user = supabase.auth.currentUser;
    if (user != null) {
      equippedWeapon = await weaponService.getUserWeapon(user.id);
    }
  }

  void updateWeapon(double dt) {
    if (equippedWeapon == null || enemies.isEmpty) return;

    timeSinceLastShot += dt;

    // Find nearest enemy by Euclidean distance (more accurate than sum of abs)
    enemies.sort((a, b) {
      double da = sqrt(pow((a.x + a.width/2) - (character.x + character.width/2), 2) +
          pow((a.y + a.height/2) - (character.y + character.height/2), 2));
      double db = sqrt(pow((b.x + b.width/2) - (character.x + character.width/2), 2) +
          pow((b.y + b.height/2) - (character.y + character.height/2), 2));
      return da.compareTo(db);
    });

    final target = enemies.first;

    // Calculate weapon rotation (aim at center of target)
    double dx = (target.x + target.width / 2) - (character.x + character.width / 2);
    double dy = (target.y + target.height / 2) - (character.y + character.height / 2);
    weaponAngle = atan2(dy, dx);

    // Auto-shoot (spawn projectile centered on character)
    double fireInterval = 1 / max(0.0001, equippedWeapon!.fireRate);
    if (timeSinceLastShot >= fireInterval) {
      timeSinceLastShot = 0;
      // spawn projectile at character center
      Projectile proj = Projectile(
        x: character.x + character.width / 2,
        y: character.y + character.height / 2,
        speed: equippedWeapon!.projectile.speed,
        damage: equippedWeapon!.damage,
        spritePath: equippedWeapon!.projectile.spritePath,
      );
      double dist = sqrt(dx * dx + dy * dy);
      if (dist == 0) dist = 0.0001;
      proj.vx = dx / dist * proj.speed;
      proj.vy = dy / dist * proj.speed;

      activeProjectiles.add(proj);
    }

    // Update projectiles robustly: mark removal with flag to avoid mid-loop issues
    for (int i = activeProjectiles.length - 1; i >= 0; i--) {
      final p = activeProjectiles[i];
      p.update(dt);

      bool shouldRemove = false;

      // collision check (use actual scaled projectile hitbox for accuracy)
      for (int j = enemies.length - 1; j >= 0; j--) {
        final e = enemies[j];
        // projectile hitbox (using projectile width/height)
        final pLeft = p.x - projW / 2;
        final pRight = p.x + projW / 2;
        final pTop = p.y - projH / 2;
        final pBottom = p.y + projH / 2;

        final eLeft = e.x;
        final eRight = e.x + e.width;
        final eTop = e.y;
        final eBottom = e.y + e.height;

        if (!(pRight < eLeft || pLeft > eRight || pBottom < eTop || pTop > eBottom)) {
          // collision!
          e.currentHealth -= p.damage;
          shouldRemove = true;

          if (e.currentHealth <= 0) {
            // remove enemy immediately
            enemies.removeAt(j);
          }
          break; // no need to check other enemies for this projectile
        }
      }

      // Off-screen removal: let projectile travel until completely out of screen bounds
      if (!shouldRemove) {
        // Here, we consider it out when its center crosses bounds +/- half-size
        if (p.x + projW / 2 < 0 ||
            p.x - projW / 2 > screenWidth ||
            p.y + projH / 2 < 0 ||
            p.y - projH / 2 > screenHeight) {
          shouldRemove = true;
        }
      }

      if (shouldRemove) {
        activeProjectiles.removeAt(i);
      }
    }
  }

  Future<void> prepareSpawnPool() async {
    final enemyService = EnemyService();
    spawnPool = await enemyService.loadSpawnPoolForSubLevel(
      widget.subLevel['id'],
      0,
      -120,
    );
  }

  Future<void> loadCharacter() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final meta = await supabase.from('users_meta').select().eq('user_id', user.id).maybeSingle();
    if (meta == null || meta['selected_character_id'] == null) return;

    final charData = await supabase.from('characters').select().eq('id', meta['selected_character_id']).maybeSingle();
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
        if (tiltX > 0.1) character.facingRight = true;
        else if (tiltX < -0.1) character.facingRight = false;

        world.update(tiltX);
        // updateWeapon will also be called in _gameTick with the real dt
      }
    });
  }

  void _gameTick() {
    final now = DateTime.now();
    double dt = now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;
    dt = dt.clamp(0.016, 0.033);

    if (!paused && !gameOver) {
      _updateSpawner(dt);
      _updateEnemies(dt);
      updateWeapon(dt);

      character.y += character.vy * dt;

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
      if (prototype != null) enemies.add(prototype);
      nextSpawnIn = minSpawnInterval + random.nextDouble() * (maxSpawnInterval - minSpawnInterval);
    }
  }

  void _updateEnemies(double dt) {
    for (int i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      e.update(character, dt);
      if (e.y > screenHeight + 200) enemies.removeAt(i);
    }

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

            // Weapon sprite (drawn on top of character)
            if (equippedWeapon != null)
              Positioned(
                // keep same coordinate system as character: use bottom-based positioning
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

            // Projectiles (scaled and rotated so tip faces velocity)
            ...activeProjectiles.map((p) {
              // position projectiles in same coordinate system (convert to bottom-based)
              final left = p.x - projW / 2;
              final bottom = screenHeight - p.y - projH / 2;
              final angle = atan2(p.vy, p.vx);

              return Positioned(
                left: left,
                bottom: bottom,
                child: Transform.rotate(
                  angle: angle, // no extra +pi; if tip faces opposite, change to angle + pi
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

            // Health bar
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
