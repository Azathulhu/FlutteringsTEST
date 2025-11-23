import 'package:flutter/material.dart';
import '../services/level_service.dart';
import 'package:flame/game.dart';
import '../game/my_game.dart'; // your Flame Game class

class LevelSelectionPage extends StatefulWidget {
  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  final LevelService _levelService = LevelService();
  List<Map<String, dynamic>> levels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadLevels();
  }

  Future<void> loadLevels() async {
    final data = await _levelService.getLevels();
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
      body: ListView.builder(
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          return ListTile(
            title: Text(level['name']),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SublevelSelectionPage(levelId: level['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SublevelSelectionPage extends StatefulWidget {
  final int levelId;
  SublevelSelectionPage({required this.levelId});

  @override
  State<SublevelSelectionPage> createState() => _SublevelSelectionPageState();
}

class _SublevelSelectionPageState extends State<SublevelSelectionPage> {
  final LevelService _levelService = LevelService();
  List<Map<String, dynamic>> sublevels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSublevels();
  }

  Future<void> loadSublevels() async {
    final data = await _levelService.getSublevels(widget.levelId);
    setState(() {
      sublevels = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text("Select Area")),
      body: ListView.builder(
        itemCount: sublevels.length,
        itemBuilder: (context, index) {
          final s = sublevels[index];

          return ListTile(
            title: Text(s['name']),
            subtitle: s['completed'] ? Text("Completed") : null,
            enabled: s['is_unlocked'],
            onTap: s['is_unlocked']
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: GameWidget(
                            game: MyGame(sublevelId: s['id']),
                          ),
                        ),
                      ),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }
}
