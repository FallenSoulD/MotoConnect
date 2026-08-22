import 'dart:html' as html;
import 'dart:js' as js;

void initWebSensors({
  required Function(double) onAngle,
  required Function(double) onGForce,
}) {
  try {
    html.window.onDeviceOrientation.listen((html.DeviceOrientationEvent event) {
      final gamma = event.gamma;
      if (gamma != null) {
        onAngle(gamma.toDouble());
      }
    });

    html.window.onDeviceMotion.listen((html.DeviceMotionEvent event) {
      final acc = event.accelerationIncludingGravity;
      if (acc != null) {
        final x = (acc.x ?? 0).toDouble();
        final y = (acc.y ?? 0).toDouble();
        final z = (acc.z ?? 0).toDouble();
        final total = (x * x + y * y + z * z);
        if (total > 0) {
          final g = (total / (9.80665 * 9.80665)).clamp(0.0, 3.5);
          onGForce(g);
        }
      }
    });
  } catch (_) {}
}

Future<bool> requestWebPermission() async {
  try {
    if (js.context.hasProperty('requestMotoSensorPermission')) {
      final res = await js.context.callMethod('requestMotoSensorPermission', []);
      return res == true;
    }
  } catch (_) {}
  return true;
}
