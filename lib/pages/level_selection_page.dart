//REWRITE.
import 'package:flutter/material.dart';
import '../services/level_service.dart';
import 'game/sub_level_game_page.dart';

class LevelSelectionPage extends StatefulWidget {
  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  final LevelService _levelService = LevelService();
  final PageController _levelController = PageController(viewportFraction: 0.7);

  List<Map<String, dynamic>> levels = [];
  int currentLevelPage = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadLevels();
  }

  Future<void> loadLevels() async {
    final data = await _levelService.loadLevels();
    setState(() {
      levels = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());

    final currentLevel = levels[currentLevelPage];
    final subLevels = (currentLevel['sub_levels'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    // Find first unlocked sub-level
    Map<String, dynamic>? firstUnlockedSub;
    try {
      firstUnlockedSub =
          subLevels.firstWhere((s) => s['is_unlocked'] == true);
    } catch (_) {
      firstUnlockedSub = null;
    }

    // Check if there is any unlocked sub-level
    final hasUnlocked = firstUnlockedSub != null;

    return Scaffold(
      appBar: AppBar(title: Text("Select a Level")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main Level Carousel
          SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _levelController,
              itemCount: levels.length,
              onPageChanged: (i) => setState(() => currentLevelPage = i),
              itemBuilder: (context, index) {
                final lvl = levels[index];
                double scale = index == currentLevelPage ? 1.0 : 0.8;

                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: lvl['thumbnail_path'] != null
                              ? DecorationImage(
                                  image: AssetImage(
                                      "assets/level_thumbnails/${lvl['thumbnail_path']}"),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.blueGrey,
                        ),
                        child: Center(
                          child: Text(
                            lvl['name'] ?? '',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!(subLevels.any((s) => s['is_unlocked'] == true)))
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child:
                                Icon(Icons.lock, size: 50, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20),

          // Sub-Level Row
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subLevels.length,
              itemBuilder: (context, index) {
                final sub = subLevels[index];
                final unlocked = sub['is_unlocked'] ?? false;

                return GestureDetector(
                  onTap: unlocked
                      ? () {
                          // Optional: allow selecting a specific sub-level
                        }
                      : null,
                  child: Opacity(
                    opacity: unlocked ? 1 : 0.4,
                    child: Container(
                      width: 120,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: unlocked ? Colors.yellow : Colors.redAccent,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          sub['name'] ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20),

          // Play Button
          ElevatedButton(
            onPressed: hasUnlocked
                ? () {
                    // Navigate to Flame game page safely
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubLevelGamePage(
                          level: currentLevel,
                          subLevel: firstUnlockedSub!,
                        ),
                      ),
                    );
                  }
                : null,
            child: Text("Play"),
          ),
        ],
      ),
    );
  }
}
