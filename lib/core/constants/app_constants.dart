class AppConstants {
  AppConstants._();

  static const String appName = 'FinScan';
  static const int cardNumberLength = 16;
  static const int cvvLength = 3;
  static const int expiryLength = 5; // MM/YY
  static const Duration cameraInitTimeout = Duration(seconds: 5);
}