import 'dart:math';

String generateFinanceTransactionId({
  DateTime? now,
  Random? random,
}) {
  final timestamp =
      (now ?? DateTime.now()).toUtc().microsecondsSinceEpoch.toRadixString(36);

  final rng = random ?? Random.secure();
  final entropy = List<String>.generate(
    3,
    (_) => rng.nextInt(1 << 20).toRadixString(36).padLeft(4, '0'),
  ).join();

  return 'tx_${timestamp}_$entropy';
}

String normalizeOrGenerateFinanceTransactionId(
  String? rawId, {
  DateTime? now,
  Random? random,
}) {
  final normalized = rawId?.trim();
  if (normalized != null && normalized.isNotEmpty) {
    return normalized;
  }

  return generateFinanceTransactionId(now: now, random: random);
}
