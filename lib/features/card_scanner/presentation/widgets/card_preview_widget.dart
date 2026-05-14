import 'package:flutter/material.dart';
import '../../data/models/card_details.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/string_utils.dart';

class CardPreviewWidget extends StatelessWidget {
  final CardDetails cardDetails;

  const CardPreviewWidget({super.key, required this.cardDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cardDetails.bankName != null)
            Text(cardDetails.bankName!,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(
            StringUtils.formatCardNumber(cardDetails.cardNumber),
            style: const TextStyle(
                color: Colors.white, fontSize: 20, letterSpacing: 2, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARD HOLDER', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(cardDetails.cardHolderName,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(cardDetails.expiryDate,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}