import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyFeeStructureScreen extends StatefulWidget {
  const AcademyFeeStructureScreen({super.key});

  @override
  State<AcademyFeeStructureScreen> createState() =>
      _AcademyFeeStructureScreenState();
}

class _AcademyFeeStructureScreenState extends State<AcademyFeeStructureScreen> {
  List<_FeePlan> _plans = <_FeePlan>[
    const _FeePlan(name: 'Monthly Fee', amount: '₹2000', duration: 'Custom'),
    const _FeePlan(
      name: 'Quarterly Fee',
      amount: '₹5000',
      duration: 'Quarterly',
    ),
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> profile = await GroundWaleApi.instance
          .getOwnerProfile(ownerId);
      final List<dynamic> rawPlans =
          profile['feePlans'] as List<dynamic>? ?? <dynamic>[];
      final List<_FeePlan> apiPlans = rawPlans
          .whereType<Map>()
          .map((Map item) => _FeePlan.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      if (!mounted) {
        return;
      }
      setState(() {
        if (apiPlans.isNotEmpty) {
          _plans = apiPlans;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePlans() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }
    try {
      await GroundWaleApi.instance.updateOwnerProfile(
        ownerId,
        <String, dynamic>{'feePlans': _plans.map((e) => e.toMap()).toList()},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Fees structure',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ..._plans.asMap().entries.map(
                      (MapEntry<int, _FeePlan> entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FeePlanCard(
                          plan: entry.value,
                          onEdit: () => _showPlanDialog(editIndex: entry.key),
                          onDelete: () => _showDeleteDialog(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _showPlanDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9A7),
                          foregroundColor: const Color(0xFF242424),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: null,
    );
  }

  Future<void> _showPlanDialog({int? editIndex}) async {
    final bool editing = editIndex != null;
    final _FeePlan? plan = editing ? _plans[editIndex] : null;
    final TextEditingController nameController = TextEditingController(
      text: plan?.name ?? 'Pro Annual Plan',
    );
    final TextEditingController priceController = TextEditingController(
      text: plan?.amount ?? '₹ 5,000',
    );
    final TextEditingController percentageController = TextEditingController(
      text: plan?.discountLabel ?? 'Percentage (%)',
    );
    final TextEditingController valueController = TextEditingController(
      text: plan?.discountValue ?? '10%',
    );
    final TextEditingController conditionController = TextEditingController(
      text: plan?.condition ?? 'Early Payment',
    );
    final TextEditingController dateController = TextEditingController(
      text: plan?.payBeforeDate ?? '07 Dec, 2024',
    );

    String selectedDuration = plan?.duration ?? 'yearly';
    bool discountEnabled = plan?.discountEnabled ?? true;

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: 358,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              editing ? 'Edit Fee Plan' : 'Add New Plan',
                              style: const TextStyle(
                                color: Color(0xFF313638),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF242424),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DialogField(
                        label: 'Plan Name',
                        child: _DialogInput(controller: nameController),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: _DialogField(
                              label: 'Price',
                              child: _DialogInput(controller: priceController),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DialogField(
                              label: 'Duration',
                              child: _DialogSelect(
                                value: selectedDuration,
                                items: const <String>[
                                  'Monthly',
                                  'Quarterly',
                                  'Half-Yearly',
                                  'yearly',
                                  'Custom',
                                ],
                                onChanged: (String value) {
                                  setDialogState(
                                    () => selectedDuration = value,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Discount',
                                  style: TextStyle(
                                    color: Color(0xFF313638),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Optional offer for this plan',
                                  style: TextStyle(
                                    color: Color(0xFF313638),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: discountEnabled,
                            onChanged: (bool value) {
                              setDialogState(() => discountEnabled = value);
                            },
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF08B36A),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0x4D242424),
                          ),
                        ],
                      ),
                      if (discountEnabled) ...<Widget>[
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: _DialogField(
                                label: 'Percentage',
                                child: _DialogInput(
                                  controller: percentageController,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DialogField(
                                label: 'Value',
                                child: _DialogInput(
                                  controller: valueController,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DialogField(
                          label: 'Condition',
                          child: _DialogInput(controller: conditionController),
                        ),
                        const SizedBox(height: 16),
                        _DialogField(
                          label: 'Pay Before Date',
                          child: _DateInput(
                            controller: dateController,
                            onTap: () async {
                              final DateTime? selectedDate =
                                  await showDatePicker(
                                    context: dialogContext,
                                    initialDate: DateTime(2024, 12, 7),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                              if (selectedDate != null) {
                                const List<String> months = <String>[
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                  'Jul',
                                  'Aug',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Dec',
                                ];
                                dateController.text =
                                    '${selectedDate.day.toString().padLeft(2, '0')} '
                                    '${months[selectedDate.month - 1]}, '
                                    '${selectedDate.year}';
                                setDialogState(() {});
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x1FFFCC80),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xFF08B36A),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Text(
                            'Pay before ${dateController.text} & get '
                            '${valueController.text} Discount',
                            style: const TextStyle(
                              color: Color(0xFF242424),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final _FeePlan updatedPlan = _FeePlan(
                              name: nameController.text.trim().isEmpty
                                  ? 'Untitled Plan'
                                  : nameController.text.trim(),
                              amount: priceController.text.trim().isEmpty
                                  ? '₹0'
                                  : priceController.text.trim(),
                              duration: selectedDuration,
                              discountEnabled: discountEnabled,
                              discountLabel: percentageController.text.trim(),
                              discountValue: valueController.text.trim(),
                              condition: conditionController.text.trim(),
                              payBeforeDate: dateController.text.trim(),
                            );

                            setState(() {
                              if (editing) {
                                _plans[editIndex] = updatedPlan;
                              } else {
                                _plans.add(updatedPlan);
                              }
                            });
                            _savePlans();
                            Navigator.of(dialogContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C333B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            editing ? 'Update Plan' : 'Add Plan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(int index) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Delete Fee Plan?',
                  style: TextStyle(
                    color: Color(0xFF313638),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Remove ${_plans[index].name} from the fee structure list.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4F5D73),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: const BorderSide(color: Color(0xFFE3220D)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFFE3220D)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _plans.removeAt(index));
                          _savePlans();
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: const Color(0xFFE3220D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeePlanCard extends StatelessWidget {
  const _FeePlanCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  final _FeePlan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.amount,
                  style: const TextStyle(
                    color: Color(0xFF08B36A),
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.duration,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE3220D),
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF313638),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DialogInput extends StatelessWidget {
  const _DialogInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1F242424)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1F242424)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1C333B)),
        ),
      ),
      style: const TextStyle(
        color: Color(0xFF242424),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _DialogSelect extends StatelessWidget {
  const _DialogSelect({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1F242424)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items
              .map(
                (String item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({required this.controller, required this.onTap});

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1F242424)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1F242424)),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                controller.text,
                style: const TextStyle(
                  color: Color(0xFF242424),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0x99242424),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeePlan {
  const _FeePlan({
    required this.name,
    required this.amount,
    required this.duration,
    this.discountEnabled = false,
    this.discountLabel = '',
    this.discountValue = '',
    this.condition = '',
    this.payBeforeDate = '',
  });

  final String name;
  final String amount;
  final String duration;
  final bool discountEnabled;
  final String discountLabel;
  final String discountValue;
  final String condition;
  final String payBeforeDate;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'amount': amount,
      'duration': duration,
      'discountEnabled': discountEnabled,
      'discountLabel': discountLabel,
      'discountValue': discountValue,
      'condition': condition,
      'payBeforeDate': payBeforeDate,
    };
  }

  static _FeePlan fromMap(Map<String, dynamic> map) {
    return _FeePlan(
      name: map['name']?.toString() ?? 'Untitled Plan',
      amount: map['amount']?.toString() ?? '₹0',
      duration: map['duration']?.toString() ?? 'Custom',
      discountEnabled: map['discountEnabled'] == true,
      discountLabel: map['discountLabel']?.toString() ?? '',
      discountValue: map['discountValue']?.toString() ?? '',
      condition: map['condition']?.toString() ?? '',
      payBeforeDate: map['payBeforeDate']?.toString() ?? '',
    );
  }
}


