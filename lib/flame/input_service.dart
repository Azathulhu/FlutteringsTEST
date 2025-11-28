import 'package:flutter/material.dart';

class InputService extends ChangeNotifier {
  bool moveLeft = false;
  bool moveRight = false;
  bool jump = false;

  void setMoveLeft(bool value) {
    moveLeft = value;
    notifyListeners();
  }

  void setMoveRight(bool value) {
    moveRight = value;
    notifyListeners();
  }

  void setJump(bool value) {
    jump = value;
    notifyListeners();
  }
}
