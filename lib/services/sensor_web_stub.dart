void initWebSensors({
  required Function(double) onAngle,
  required Function(double) onGForce,
}) {}

Future<bool> requestWebPermission() async => true;
