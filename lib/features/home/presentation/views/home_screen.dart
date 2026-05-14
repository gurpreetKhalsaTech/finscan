import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FinScan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.document_scanner_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'What would you like to scan?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Scan Credit / Debit Card',
              icon: Icons.credit_card,
              onPressed: () => context.push(AppRouter.cardScanner),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Scan Bank Passbook',
              icon: Icons.book_outlined,
              onPressed: () => context.push(AppRouter.passbookScanner),
            ),
          ],
        ),
      ),
    );
  }
}