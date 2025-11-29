import 'package:flutter/material.dart';
import 'character.dart';
import 'world.dart';
import 'platform.dart';

class EngineWidget extends StatefulWidget {
  final Character character;
  final double screenWidth;
  final double screenHeight;

  EngineWidget({
    required this.character,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  _EngineWidgetState createState() => _EngineWidgetState();
}

class _EngineWidgetState extends State<EngineWidget>
    with SingleTickerProviderStateMixin {
  late World world;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    world = World(
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      character: widget.character,
    );

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          world.update(0.0); // you can pass tiltX later
        });
      });

    controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ...world.platforms.map((p) {
          return Positioned(
            top: p.y,
            left: p.x,
            child: Container(
              width: p.width,
              height: p.height,
              color: Colors.brown,
            ),
          );
        }).toList(),
        Positioned(
          top: world.character.y,
          left: world.character.x,
          child: world.character.buildWidget(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
