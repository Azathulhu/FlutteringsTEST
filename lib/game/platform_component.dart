import 'package:flame/components.dart';

class PlatformComponent extends PositionComponent {
  PlatformComponent({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF888888);
    canvas.drawRect(size.toRect(), paint);
  }
}
