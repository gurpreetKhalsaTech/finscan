import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/bank_details.dart';
import '../widgets/bank_detail_card.dart';

class PassbookResultScreen extends StatelessWidget {
  final BankDetails bankDetails;
  final String? imagePath;

  const PassbookResultScreen({super.key, required this.bankDetails, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null) _ScannedImagePreview(imagePath: imagePath!),
            const SizedBox(height: 16),
            BankDetailCard(bankDetails: bankDetails),
          ],
        ),
      ),
    );
  }
}

class _ScannedImagePreview extends StatelessWidget {
  final String imagePath;
  const _ScannedImagePreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath),
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}