import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class FinanceCategoryUi {
  const FinanceCategoryUi({
    required this.name,
    required this.badge,
    required this.color,
  });

  final String name;
  final String badge;
  final Color color;
}

const financeCategories = <FinanceCategoryUi>[
  FinanceCategoryUi(name: 'Coffee', badge: 'CF', color: AppColors.accentPink),
  FinanceCategoryUi(
      name: 'Groceries', badge: 'GR', color: AppColors.accentGreen),
  FinanceCategoryUi(
      name: 'Transport', badge: 'TR', color: AppColors.accentPurple),
  FinanceCategoryUi(name: 'Dining', badge: 'DN', color: AppColors.accentYellow),
  FinanceCategoryUi(name: 'Shopping', badge: 'SH', color: AppColors.accentPink),
  FinanceCategoryUi(name: 'Bills', badge: 'BL', color: AppColors.accentPurple),
  FinanceCategoryUi(name: 'Salary', badge: 'SA', color: AppColors.accentGreen),
  FinanceCategoryUi(
      name: 'Freelance', badge: 'FR', color: AppColors.accentGreen),
];

FinanceCategoryUi categoryUiByName(String name) {
  return financeCategories.firstWhere(
    (item) => item.name == name,
    orElse: () => const FinanceCategoryUi(
      name: 'Other',
      badge: 'OT',
      color: AppColors.surface,
    ),
  );
}

String formatCurrency(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final whole = abs.floor();
  final cents = ((abs - whole) * 100).round().toString().padLeft(2, '0');
  final wholeText = whole.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
  return '${isNegative ? '-' : ''}\$$wholeText.$cents';
}

String shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
