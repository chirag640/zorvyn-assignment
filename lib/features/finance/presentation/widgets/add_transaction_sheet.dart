import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/haptic_feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../providers/finance_provider.dart';
import '../providers/finance_value_provider.dart';
import 'finance_ui_helpers.dart';

class AddTransactionResult {
  const AddTransactionResult({
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.transactionId,
  });

  final double amount;
  final FinanceTransactionType type;
  final String category;
  final DateTime date;
  final String? note;
  final String? transactionId;
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    super.key,
    required this.onSave,
    this.initialTransaction,
    this.submitLabel,
  });

  final ValueChanged<AddTransactionResult> onSave;
  final FinanceTransaction? initialTransaction;
  final String? submitLabel;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  FinanceTransactionType _type = FinanceTransactionType.expense;
  String _category = financeCategories.first.name;
  String _amount = '0.00';
  DateTime _date = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _categoryWasExplicitlySelected = false;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    _noteController.addListener(_onNoteChanged);

    final initial = widget.initialTransaction;
    if (initial == null) {
      return;
    }

    _type = initial.type;
    _category = initial.category;
    _amount = initial.amount.toStringAsFixed(2);
    _date = initial.date;
    _noteController.text = initial.note ?? '';
    _categoryWasExplicitlySelected = true;
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    _maybeAutoAssignCategory();
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  FinanceCategorySuggestion? get _categorySuggestionDetails {
    final history = ref.read(financeProvider).transactions;
    final recurringPatterns = ref.read(financeRecurringPatternsProvider);
    final amount = double.tryParse(_amount) ?? 0;

    return suggestFinanceCategoryWithConfidence(
      note: _noteController.text,
      type: _type,
      amount: amount,
      history: history,
      recurringPatterns: recurringPatterns,
    );
  }

  void _maybeAutoAssignCategory() {
    if (_categoryWasExplicitlySelected || _isEditing) {
      return;
    }

    final suggestion = _categorySuggestionDetails;
    if (suggestion == null ||
        suggestion.category == _category ||
        suggestion.confidence < 0.78) {
      return;
    }

    _category = suggestion.category;
  }

  void _applyKey(String key) {
    unawaited(HapticFeedbackService.light());

    setState(() {
      if (key == 'back') {
        if (_amount.length <= 1) {
          _amount = '0.00';
          return;
        }
        _amount = _amount.substring(0, _amount.length - 1);
        if (_amount == '-' || _amount.isEmpty) {
          _amount = '0.00';
        }
        return;
      }

      if (key == '.') {
        if (_amount.contains('.')) {
          return;
        }
        _amount = '$_amount.';
        return;
      }

      if (_amount == '0.00') {
        _amount = key;
      } else {
        _amount = '$_amount$key';
      }

      final parsed = double.tryParse(_amount) ?? 0;
      if (parsed > 999999) {
        _amount = '999999';
      }

      _maybeAutoAssignCategory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amount) ?? 0;
    final categorySuggestion = _categorySuggestionDetails;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.rs(16),
                  context.rs(12),
                  context.rs(16),
                  context.rs(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: context.rs(48),
                      height: context.rs(5),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius:
                            BorderRadius.circular(context.rRadius(99)),
                      ),
                    ),
                    SizedBox(height: context.rs(20)),
                    Text(
                      '$activeCurrencySymbol${amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    SizedBox(height: context.rs(6)),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(
                        Icons.calendar_today_rounded,
                        size: context.rIcon(16),
                      ),
                      label: Text(
                        'Date: ${shortDate(_date)}',
                        style: TextStyle(fontSize: context.rFont(13)),
                      ),
                    ),
                    SizedBox(height: context.rs(16)),
                    _buildTypeToggle(),
                    SizedBox(height: context.rs(16)),
                    SizedBox(
                      height: context.rs(44),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: financeCategories.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(width: context.rs(8)),
                        itemBuilder: (context, index) {
                          final item = financeCategories[index];
                          final selected = item.name == _category;
                          return AnimatedScale(
                            duration: const Duration(milliseconds: 140),
                            scale: selected ? 0.98 : 1,
                            child: ChoiceChip(
                              selected: selected,
                              backgroundColor: AppColors.surface,
                              selectedColor: AppColors.primary,
                              label: Text(
                                '${item.badge} ${item.name}',
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.background
                                      : AppColors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _categoryWasExplicitlySelected = true;
                                  _category = item.name;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: context.rs(12)),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Note (optional)',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(context.rRadius(20)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.rs(16),
                          vertical: context.rs(14),
                        ),
                      ),
                    ),
                    if (categorySuggestion != null &&
                        categorySuggestion.category != _category) ...[
                      SizedBox(height: context.rs(8)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.14),
                          side: BorderSide.none,
                          label: Text(
                            'Suggested: ${categorySuggestion.category} (${(categorySuggestion.confidence * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _categoryWasExplicitlySelected = true;
                              _category = categorySuggestion.category;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: context.rs(4)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Based on ${categorySuggestion.sourceLabel}',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: context.rFont(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: context.rs(12)),
                    _buildNumpad(),
                    SizedBox(height: context.rs(12)),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          minimumSize: Size.fromHeight(context.rs(56)),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(context.rRadius(20)),
                          ),
                        ),
                        onPressed: amount <= 0
                            ? null
                            : () {
                                unawaited(HapticFeedbackService.success());
                                widget.onSave(
                                  AddTransactionResult(
                                    amount: amount,
                                    type: _type,
                                    category: _category,
                                    date: _date,
                                    note: _noteController.text.trim().isEmpty
                                        ? null
                                        : _noteController.text.trim(),
                                    transactionId:
                                        widget.initialTransaction?.id,
                                  ),
                                );
                              },
                        child: Text(widget.submitLabel ??
                            (_isEditing ? 'Update' : 'Save')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _date = picked;
    });
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              selected: _type == FinanceTransactionType.expense,
              selectedColor: AppColors.accentPink,
              label: 'Expense',
              onTap: () {
                setState(() {
                  _type = FinanceTransactionType.expense;
                  _maybeAutoAssignCategory();
                });
              },
            ),
          ),
          Expanded(
            child: _ToggleButton(
              selected: _type == FinanceTransactionType.income,
              selectedColor: AppColors.accentGreen,
              label: 'Income',
              onTap: () {
                setState(() {
                  _type = FinanceTransactionType.income;
                  _maybeAutoAssignCategory();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    const keys = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      'back',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: context.rs(8),
        crossAxisSpacing: context.rs(8),
        childAspectRatio: context.rValue(
          mobile: 1.9,
          tablet: 2.25,
          desktop: 2.5,
        ),
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        return InkWell(
          borderRadius: BorderRadius.circular(context.rRadius(14)),
          onTap: () => _applyKey(key),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(context.rRadius(14)),
            ),
            child: Center(
              child: Text(
                key == 'back' ? '<' : key,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.selected,
    required this.selectedColor,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final Color selectedColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.all(context.rs(4)),
        padding: EdgeInsets.symmetric(vertical: context.rs(10)),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(context.rRadius(10)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            fontSize: context.rFont(14),
          ),
        ),
      ),
    );
  }
}
