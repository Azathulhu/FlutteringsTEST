import 'package:flutter/material.dart';
import '../services/character_service.dart';

class CharacterSelectionPage extends StatefulWidget {
  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  final PageController _controller = PageController(viewportFraction: 0.55);
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
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text("Select Your Character")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _controller,
              itemCount: characters.length,
              onPageChanged: (i) => setState(() => currentPage = i),
              itemBuilder: (context, index) {
                final c = characters[index];

                double angle = (index - currentPage) * 0.3;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: Opacity(
                    opacity: c['is_unlocked'] ? 1 : 0.5,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: c['is_unlocked']
                              ? Colors.white
                              : Colors.redAccent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c['name'],
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Image.asset(
                            "assets/character sprites/${c['sprite_path']}",
                            width: 512,
                            height: 512,
                            filterQuality: FilterQuality.none,
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
            characters[currentPage]['is_unlocked']
                ? "This character is unlocked."
                : "Locked. Reach level X to unlock.",
            style: TextStyle(fontSize: 18),
          ),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: characters[currentPage]['is_unlocked']
                ? () async {
                    final charId = characters[currentPage]['id'];
                    await _characterService.selectCharacter(charId);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Character selected!")),
                    );
                  }
                : null,
            child: Text("Select"),
          ),
        ],
      ),
    );
  }
}
