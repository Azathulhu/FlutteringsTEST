// lib/pages/sub_level_selection_page.dart
import 'package:flutter/material.dart';
import '../services/level_service.dart';
import 'game_page.dart';

class SubLevelSelectionPage extends StatefulWidget {
  final Map<String, dynamic> level;
  SubLevelSelectionPage({required this.level});

  @override
  State<SubLevelSelectionPage> createState() => _SubLevelSelectionPageState();
}

class _SubLevelSelectionPageState extends State<SubLevelSelectionPage> {
  final LevelService _levelService = LevelService();
  List<Map<String, dynamic>> subLevels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSubLevels();
  }

  Future<void> loadSubLevels() async {
    setState(() => loading = true);
    final data = await _levelService.loadSubLevels(widget.level['id']);
    setState(() {
      subLevels = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text("Select Sub-Level")),
      body: ListView.builder(
        itemCount: subLevels.length,
        itemBuilder: (context, index) {
          final sl = subLevels[index];
          final unlocked = sl['is_unlocked'] == true;

          return ListTile(
            title: Text(sl['name']),
            trailing: Icon(sl['is_completed'] == true ? Icons.check : null),
            enabled: unlocked,
            onTap: unlocked
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GamePage(level: widget.level, subLevel: sl),
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





/*import 'package:flutter/material.dart';
import '../services/level_service.dart';
import 'game_page.dart';

class SubLevelSelectionPage extends StatefulWidget {
  final Map<String, dynamic> level;
  SubLevelSelectionPage({required this.level});

  @override
  State<SubLevelSelectionPage> createState() => _SubLevelSelectionPageState();
}

class _SubLevelSelectionPageState extends State<SubLevelSelectionPage> {
  final PageController _controller = PageController(viewportFraction: 0.6);
  final LevelService _levelService = LevelService();

  int currentPage = 0;
  List<Map<String, dynamic>> subLevels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSubLevels();
  }

  Future<void> loadSubLevels() async {
    final data = await _levelService.loadSubLevels(widget.level['id']);
    setState(() {
      subLevels = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text("Select Sub-Level")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _controller,
              itemCount: subLevels.length,
              onPageChanged: (i) => setState(() => currentPage = i),
              itemBuilder: (context, index) {
                final sub = subLevels[index];

                return Opacity(
                  opacity: sub['is_unlocked'] ? 1 : 0.5,
                  child: GestureDetector(
                    onTap: sub['is_unlocked']
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GamePage(
                                  level: widget.level,
                                  subLevel: sub,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sub['is_unlocked'] ? Colors.white : Colors.red,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          sub['name'],
                          style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
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
}*/
