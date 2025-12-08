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
  final LevelService levelService = LevelService();
  List<Map<String, dynamic>> subLevels = [];

  @override
  void initState() {
    super.initState();
    _loadSubLevels();
  }

  Future<void> _loadSubLevels() async {
    final subs = await levelService.loadSubLevels(widget.level['id']);
    setState(() {
      subLevels = subs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.level['name'])),
      body: GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: subLevels.length,
        itemBuilder: (_, i) {
          final sub = subLevels[i];
          return GestureDetector(
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
            child: Opacity(
              opacity: sub['is_unlocked'] ? 1.0 : 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sub['is_unlocked'] ? Colors.white : Colors.red,
                      width: 3),
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
