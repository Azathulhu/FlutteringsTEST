import 'package:flutter/material.dart';

class CharacterSelectionPage extends StatefulWidget {
  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  final PageController _controller = PageController(viewportFraction: 0.5);
  int currentPage = 0;

  final List<String> characters = [
    "Default", 
    "Character 2",
    "Character 3",
    "Character 4",
  ];

  final List<bool> unlocked = [
    true,  // Default unlocked
    false,
    false,
    false,
  ];

  // Placeholder sprite for each character (replace with actual sprites later)
  final List<String> characterSprites = [
    'assets/character sprites/fluttering1.png',
    'assets/character sprites/fluttering2.png',
    'assets/character sprites/fluttering3.png',
    'assets/character sprites/fluttering4.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Your Character")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _controller,
              itemCount: characters.length,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemBuilder: (context, index) {
                double scale = index == currentPage ? 1.0 : 0.7;
                double angle = (index - currentPage) * 0.3;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: Opacity(
                    opacity: unlocked[index] ? 1.0 : 0.5,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: unlocked[index] ? Colors.white : Colors.redAccent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            characters[index],
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Image.asset(
                            characterSprites[index],
                            width: 64, // scale 16x16 pixel sprite
                            height: 64,
                            filterQuality: FilterQuality.none, // keep pixelated
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 30),
          Text(
            unlocked[currentPage]
                ? "Character Selected!"
                : "Locked. Reach level X to unlock.",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: unlocked[currentPage] ? () {} : null,
            child: Text("Select"),
          ),
        ],
      ),
    );
  }
}
