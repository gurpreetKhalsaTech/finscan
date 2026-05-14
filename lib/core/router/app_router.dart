import 'package:go_router/go_router.dart';
import '../../features/home/presentation/views/home_screen.dart';
import '../../features/card_scanner/data/models/card_details.dart';
import '../../features/card_scanner/presentation/views/card_scanner_screen.dart';
import '../../features/card_scanner/presentation/views/card_result_screen.dart';
import '../../features/passbook_scanner/data/models/bank_details.dart';
import '../../features/passbook_scanner/presentation/views/passbook_scanner_screen.dart';
import '../../features/passbook_scanner/presentation/views/passbook_result_screen.dart';

class AppRouter {
  AppRouter._();

  static const home = '/';
  static const cardScanner = '/card-scanner';
  static const cardResult = '/card-result';
  static const passbookScanner = '/passbook-scanner';
  static const passbookResult = '/passbook-result';

  static final router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(path: home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: cardScanner, builder: (_, _) => const CardScannerScreen()),
      GoRoute(
        path: cardResult,
        builder: (context, state) {
          final extra = state.extra as (CardDetails, String?);
          return CardResultScreen(cardDetails: extra.$1, imagePath: extra.$2);
        },
      ),
      GoRoute(path: passbookScanner, builder: (_, _) => const PassbookScannerScreen()),
      GoRoute(
        path: passbookResult,
        builder: (context, state) {
          final extra = state.extra as (BankDetails, String?);
          return PassbookResultScreen(bankDetails: extra.$1, imagePath: extra.$2);
        },
      ),
    ],
  );
}