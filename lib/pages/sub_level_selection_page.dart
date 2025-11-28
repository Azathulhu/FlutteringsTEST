import 'package:flutter/material.dart';
import 'game_page.dart';

class SubLevelSelectionPage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> selectedCharacter;
  final List<Map<String, dynamic>> subLevels;

  SubLevelSelectionPage({
    required this.level,
    required this.selectedCharacter,
    required this.subLevels,
  });

  @override
  State<SubLevelSelectionPage> createState() => _SubLevelSelectionPageState();
}

class _SubLevelSelectionPageState extends State<SubLevelSelectionPage> {
  int currentPage = 0;
  final PageController _controller = PageController(viewportFraction: 0.7);

  @override
  Widget build(BuildContext context) {
    if (widget.subLevels.isEmpty) return Center(child: Text("No SubLevels"));

    return Scaffold(
      appBar: AppBar(title: Text(widget.level['name'])),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.subLevels.length,
              onPageChanged: (i) => setState(() => currentPage = i),
              itemBuilder: (context, index) {
                final sub = widget.subLevels[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GamePage(
                          level: widget.level,
                          subLevel: sub,
                          character: widget.selectedCharacter,
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
                            "assets/images/background/${sub['background_image']}"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        sub['name'],
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
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
