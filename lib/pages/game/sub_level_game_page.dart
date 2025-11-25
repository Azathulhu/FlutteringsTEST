import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class SubLevelGamePage extends StatefulWidget {
  final Map<String, dynamic> level; // main level data
  final Map<String, dynamic> subLevel; // sub-level data

  const SubLevelGamePage({
    required this.level,
    required this.subLevel,
    Key? key,
  }) : super(key: key);

  @override
  State<SubLevelGamePage> createState() => _SubLevelGamePageState();
}

class _SubLevelGamePageState extends State<SubLevelGamePage> {
  late final FlameGame game;

  @override
  void initState() {
    super.initState();
    game = FlameGame(); // just an empty game for now
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       body: Image.asset(
         'assets/images/background/forest.jpeg',
         fit: BoxFit.cover,
         width: double.infinity,
         height: double.infinity,
       ),
     );
   }
}
