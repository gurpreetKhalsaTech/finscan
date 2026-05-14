class CameraException implements Exception {
  final String message;
  const CameraException(this.message);
  @override
  String toString() => 'CameraException: $message';
}

class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
  @override
  String toString() => 'OcrException: $message';
}

class ParseException implements Exception {
  final String message;
  const ParseException(this.message);
  @override
  String toString() => 'ParseException: $message';
}