import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zorvyn_finance/features/finance/data/utils/finance_id_generator.dart';

void main() {
  group('finance id generator', () {
    test('generates collision-safe ids even with same timestamp', () {
      final now = DateTime.utc(2026, 4, 3, 12, 0, 0);
      final random = Random(42);
      final ids = <String>{};

      for (var i = 0; i < 5000; i++) {
        ids.add(
          generateFinanceTransactionId(
            now: now,
            random: random,
          ),
        );
      }

      expect(ids.length, 5000);
      expect(ids.first, startsWith('tx_'));
    });

    test('normalizeOrGenerateFinanceTransactionId keeps valid id as-is', () {
      const existing = 'tx_existing_123';
      final resolved = normalizeOrGenerateFinanceTransactionId(existing);
      expect(resolved, existing);
    });

    test('normalizeOrGenerateFinanceTransactionId creates id for empty value',
        () {
      final generated = normalizeOrGenerateFinanceTransactionId('   ');
      expect(generated, startsWith('tx_'));
      expect(generated.length, greaterThan(12));
    });
  });
}
