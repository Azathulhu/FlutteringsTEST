import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
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
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double tiltX = 0.0;

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
          world.update(tiltX);
        });
      });
    controller.repeat();

    _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        tiltX = -event.x;
      });
    });
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
    _accelSub?.cancel();
    super.dispose();
  }
}
