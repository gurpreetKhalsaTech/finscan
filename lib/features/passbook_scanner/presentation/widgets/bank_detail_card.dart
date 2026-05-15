import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/bank_details.dart';
import '../../../../core/theme/app_colors.dart';

class BankDetailCard extends StatelessWidget {
  final BankDetails bankDetails;

  const BankDetailCard({super.key, required this.bankDetails});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bankDetails.bankName != null) ...[
              Text(bankDetails.bankName!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
            ],
            if (bankDetails.accountNumber != null)
              _CopyableRow(label: 'Account No.', value: bankDetails.accountNumber!),
            if (bankDetails.ifscCode != null)
              _CopyableRow(label: 'IFSC', value: bankDetails.ifscCode!),
            if (bankDetails.accountHolderName != null)
              _CopyableRow(label: 'Name', value: bankDetails.accountHolderName!),
            if (bankDetails.branchName != null)
              _CopyableRow(label: 'Branch', value: bankDetails.branchName!),
            if (bankDetails.micrCode != null)
              _CopyableRow(label: 'MICR', value: bankDetails.micrCode!),
          ],
        ),
      ),
    );
  }
}

class _CopyableRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.maskedText, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$label copied')));
            },
          ),
        ],
      ),
    );
  }
}