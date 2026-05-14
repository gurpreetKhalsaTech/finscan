import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/card_details.dart';
import '../widgets/card_preview_widget.dart';
import '../widgets/masked_card_widget.dart';

class CardResultScreen extends StatelessWidget {
  final CardDetails cardDetails;
  final String? imagePath;

  const CardResultScreen({super.key, required this.cardDetails, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null) _ScannedImagePreview(imagePath: imagePath!),
            const SizedBox(height: 16),
            CardPreviewWidget(cardDetails: cardDetails),
            const SizedBox(height: 24),
            MaskedCardWidget(cardNumber: cardDetails.cardNumber),
            const SizedBox(height: 16),
            _DetailRow(label: 'Holder', value: cardDetails.cardHolderName),
            _DetailRow(label: 'Expiry', value: cardDetails.expiryDate),
            if (cardDetails.bankName != null)
              _DetailRow(label: 'Bank', value: cardDetails.bankName!),
            if (cardDetails.cardNetwork != null)
              _DetailRow(label: 'Network', value: cardDetails.cardNetwork!),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}