import 'package:flutter/material.dart';
import 'game_page.dart';

class SubLevelSelectionPage extends StatelessWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> selectedCharacter;
  final List<Map<String, dynamic>> subLevels;

  SubLevelSelectionPage({
    required this.level,
    required this.selectedCharacter,
    required this.subLevels,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select SubLevel')),
      body: PageView.builder(
        itemCount: subLevels.length,
        controller: PageController(viewportFraction: 0.7),
        itemBuilder: (context, index) {
          final subLevel = subLevels[index];
          final isUnlocked = subLevel['is_unlocked'] ?? false;

          return GestureDetector(
            onTap: isUnlocked
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GamePage(
                          level: level,
                          subLevel: subLevel,
                          character: selectedCharacter, // ✅ required!
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: isUnlocked ? Colors.green : Colors.red),
                borderRadius: BorderRadius.circular(15),
                color: Colors.blueGrey,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subLevel['name'], style: TextStyle(fontSize: 24, color: Colors.white)),
                  SizedBox(height: 10),
                  Text(isUnlocked ? 'Unlocked' : 'Locked', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
