abstract class Failure {
  final String message;
  const Failure(this.message);
}

class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}