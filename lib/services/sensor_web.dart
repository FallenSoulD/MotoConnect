import 'package:web/web.dart' as web;
import 'dart:js_interop' as js;

void initWebSensors({
  required Function(double) onAngle,
  required Function(double) onGForce,
}) {
  try {
    web.window.addEventListener('deviceorientation', ((web.DeviceOrientationEvent event) {
      final gamma = event.gamma;
      if (gamma != null) {
        onAngle(gamma.toDouble());
      }
    }).toJS);

    web.window.addEventListener('devicemotion', ((web.DeviceMotionEvent event) {
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
    }).toJS);
  } catch (_) {}
}

@js.JS('requestMotoSensorPermission')
external js.JSPromise<js.JSAny>? _requestMotoSensorPermission();

@js.JS('window.requestMotoSensorPermission')
external js.JSFunction? get _hasRequestMotoSensorPermission;

Future<bool> requestWebPermission() async {
  try {
    if (_hasRequestMotoSensorPermission != null) {
      final promise = _requestMotoSensorPermission();
      if (promise != null) {
        await promise.toDart;
        return true;
      }
    }
  } catch (_) {}
  return true;
}
