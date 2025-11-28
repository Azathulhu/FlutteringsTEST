import 'package:flutter/material.dart';
import '../services/level_service.dart';
import 'sub_level_selection_page.dart';

class LevelSelectionPage extends StatefulWidget {
  final Map<String, dynamic> selectedCharacter; // ⚠ Pass selected character

  LevelSelectionPage({required this.selectedCharacter});

  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  final PageController _controller = PageController(viewportFraction: 0.7);
  final LevelService _levelService = LevelService();

  int currentPage = 0;
  List<Map<String, dynamic>> levels = [];
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

    return Scaffold(
      appBar: AppBar(title: Text("Select Biome")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _controller,
              itemCount: levels.length,
              onPageChanged: (i) => setState(() => currentPage = i),
              itemBuilder: (context, index) {
                final level = levels[index];

                return GestureDetector(
                  onTap: () {
                    // Load sublevels from level service or directly from level map
                    final subLevels = level['subLevels'] ?? [];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubLevelSelectionPage(
                          level: level,
                          selectedCharacter: widget.selectedCharacter, // ✅ Pass it
                          subLevels: subLevels,                        // ✅ Pass sublevels
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 3),
                      image: DecorationImage(
                        image: AssetImage(
                            "assets/images/background/${level['background_image']}"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        level['name'],
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
