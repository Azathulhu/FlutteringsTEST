import 'package:flutter/material.dart';
import '../services/input_service.dart';

class ControlsOverlay extends StatelessWidget {
  final InputService inputService;

  ControlsOverlay({required this.inputService});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left / Right buttons
        Positioned(
          left: 20,
          bottom: 20,
          child: Row(
            children: [
              GestureDetector(
                onTapDown: (_) => inputService.setMoveLeft(true),
                onTapUp: (_) => inputService.setMoveLeft(false),
                onTapCancel: () => inputService.setMoveLeft(false),
                child: Container(width: 60, height: 60, color: Colors.blue.withOpacity(0.5), child: Icon(Icons.arrow_left)),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTapDown: (_) => inputService.setMoveRight(true),
                onTapUp: (_) => inputService.setMoveRight(false),
                onTapCancel: () => inputService.setMoveRight(false),
                child: Container(width: 60, height: 60, color: Colors.green.withOpacity(0.5), child: Icon(Icons.arrow_right)),
              ),
            ],
          ),
        ),
        // Jump button
        Positioned(
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onTapDown: (_) => inputService.setJump(true),
            onTapUp: (_) => inputService.setJump(false),
            onTapCancel: () => inputService.setJump(false),
            child: Container(width: 60, height: 60, color: Colors.red.withOpacity(0.5), child: Icon(Icons.arrow_upward)),
          ),
        ),
      ],
    );
  }
}
