import 'package:rive/rive.dart';

class RiveControllerManager {
  late RiveAnimationController _controller;

  RiveAnimationController get controller => _controller;

  void initialize() {
    _controller = SimpleAnimation('idle'); // Change state as needed
  }

  void play(String animationName) {
    _controller.isActive = false;
    _controller = SimpleAnimation(animationName);
  }
}
