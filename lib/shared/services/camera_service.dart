import 'package:camera/camera.dart';

class CameraService {
  static List<CameraDescription>? _cameras;

  static Future<List<CameraDescription>> getAvailableCameras() async {
    _cameras ??= await availableCameras();
    return _cameras!;
  }
}