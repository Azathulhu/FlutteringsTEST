import 'package:flutter/material.dart';
import '../services/character_service.dart';
import 'level_selection_page.dart'; // Make sure this exists!

class CharacterSelectionPage extends StatefulWidget {
  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  final PageController _controller = PageController(viewportFraction: 0.6);
  final CharacterService _characterService = CharacterService();

  int currentPage = 0;
  List<Map<String, dynamic>> characters = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCharacters();
  }

  Future<void> loadCharacters() async {
    final data = await _characterService.loadCharacters();
    setState(() {
      characters = data;
      loading = false;
    });
    print("Loaded characters: $characters"); // Debug
  }

  void selectCharacter() async {
    final c = characters[currentPage];
    final charId = c['id'];

    print("Selecting character: ${c['name']} (ID: $charId)"); // Debug

    await _characterService.selectCharacter(charId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${c['name']} selected!")),
    );

    // Navigate to Level Selection
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LevelSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());

    final c = characters[currentPage];

    return Scaffold(
      appBar: AppBar(title: Text("Select Your Character")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _controller,
              itemCount: characters.length,
              onPageChanged: (i) => setState(() => currentPage = i),
              itemBuilder: (context, index) {
                final character = characters[index];
                double angle = (index - currentPage) * 0.3;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: Opacity(
                    opacity: character['is_unlocked'] ? 1 : 0.5,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 12),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: character['is_unlocked']
                              ? Colors.white
                              : Colors.redAccent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            character['name'],
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            width: 180,
                            height: 180,
                            child: Image.asset(
                              "assets/character sprites/${character['sprite_path']}",
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                            ),
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
            c['is_unlocked']
                ? "This character is unlocked."
                : "Locked. Reach level X to unlock.",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: c['is_unlocked'] ? selectCharacter : null,
            child: Text("Select"),
          ),
        ],
      ),
    );
  }
}
