import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/passbook_repository_impl.dart';
import '../presentation/viewmodels/passbook_viewmodel.dart';
import '../../../shared/services/ocr_service.dart';

final _passbookOcrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

final passbookRepositoryProvider = Provider<PassbookRepositoryImpl>((ref) {
  return PassbookRepositoryImpl(ref.read(_passbookOcrServiceProvider));
});

final passbookViewModelProvider =
    NotifierProvider<PassbookViewModel, PassbookState>(PassbookViewModel.new);