import 'package:flutter/material.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/theme/app_colors.dart';

class MaskedCardWidget extends StatelessWidget {
  final String cardNumber;

  const MaskedCardWidget({super.key, required this.cardNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            StringUtils.formatMaskedCard(cardNumber),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              letterSpacing: 2,
              color: AppColors.maskedText,
            ),
          ),
        ],
      ),
    );
  }
}