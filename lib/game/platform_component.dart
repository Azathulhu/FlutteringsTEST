import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlatformComponent extends PositionComponent {
  PlatformComponent({
    required Vector2 position,
    required Vector2 size,
  }) {
    this.position = position;
    this.size = size;
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = size.toRect();
    final paint = Paint()..color = Colors.brown;
    canvas.drawRect(rect, paint);
  }
}
