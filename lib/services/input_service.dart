import 'package:flutter/material.dart';

class InputService {
  bool moveLeft = false;
  bool moveRight = false;
  bool jump = false;

  void setMoveLeft(bool value) => moveLeft = value;
  void setMoveRight(bool value) => moveRight = value;
  void setJump(bool value) => jump = value;
}
