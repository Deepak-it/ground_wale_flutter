import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/labeled_text_field.dart';
import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class AcademyBatchSetupScreen extends StatefulWidget {
  const AcademyBatchSetupScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<AcademyBatchSetupScreen> createState() =>
      _AcademyBatchSetupScreenState();
}

class _AcademyBatchSetupScreenState extends State<AcademyBatchSetupScreen> {
  static const List<String> _categories = <String>[
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
  static const List<String> _days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _durationOptions = <String>[
    'Monthly',
    'Quarterly',
    'Yearly',
    'Custom',
  ];

  late final TextEditingController _batchNameController;
  late final TextEditingController _coachController;
  late final TextEditingController _studentsController;

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController(
      text: widget.controller.data.academyBatchName,
    );
    _coachController = TextEditingController(
      text: widget.controller.data.academyCoachName,
    );
    _studentsController = TextEditingController(
      text: widget.controller.data.academyPerBatchStudents,
    );
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _coachController.dispose();
    _studentsController.dispose();
    super.dispose();
  }

  void _syncBasicFields() {
    widget.controller.data.academyBatchName = _batchNameController.text.trim();
    widget.controller.data.academyCoachName = _coachController.text.trim();
    widget.controller.data.academyPerBatchStudents = _studentsController.text
        .trim();
    widget.controller.update();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final String source = isStart
        ? widget.controller.data.academyStartTime
        : widget.controller.data.academyEndTime;
    final TimeOfDay initial =
        _parseTime(source) ?? const TimeOfDay(hour: 6, minute: 0);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFDDF730)),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    final String formatted = _formatTime(picked);
    setState(() {
      if (isStart) {
        widget.controller.data.academyStartTime = formatted;
      } else {
        widget.controller.data.academyEndTime = formatted;
      }
    });
    widget.controller.update();
  }

  TimeOfDay? _parseTime(String value) {
    final RegExp regExp = RegExp(
      r'^(\d{1,2}):(\d{2})\s?(AM|PM)$',
      caseSensitive: false,
    );
    final Match? match = regExp.firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    int hour = int.tryParse(match.group(1) ?? '') ?? 6;
    final int minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final String period = (match.group(3) ?? 'AM').toUpperCase();

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }
    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay value) {
    final int hour12 = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  Future<void> _openDurationSelector(int index) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              const Text(
                'Choose Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ..._durationOptions.map((String option) {
                return ListTile(
                  title: Text(option),
                  onTap: () => Navigator.of(context).pop(option),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    String value = selected;
    if (selected == 'Custom') {
      if (!mounted) {
        return;
      }
      final TextEditingController customController = TextEditingController();
      final String? custom = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Custom Duration'),
            content: AppTextField(
              controller: customController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Example: 75 Days'),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(customController.text.trim()),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      customController.dispose();
      if (custom == null || custom.isEmpty) {
        return;
      }
      value = custom;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      widget.controller.data.academyFeePlans[index].duration = value;
    });
    widget.controller.update();
  }

  Future<void> _editPrice(int index) async {
    final TextEditingController priceController = TextEditingController(
      text: widget.controller.data.academyFeePlans[index].price,
    );

    final String? updated = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Price'),
          content: AppTextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter price'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(priceController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    priceController.dispose();

    if (updated == null || updated.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }
    final String normalized = updated.startsWith('₹')
        ? updated.replaceFirst('₹', '')
        : updated;
    setState(() {
      widget.controller.data.academyFeePlans[index].price = normalized;
    });
    widget.controller.update();
  }

  void _deletePlan(int index) {
    if (widget.controller.data.academyFeePlans.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one plan is required')),
      );
      return;
    }
    setState(() {
      widget.controller.data.academyFeePlans.removeAt(index);
    });
    widget.controller.update();
  }

  void _addPlan() {
    setState(() {
      widget.controller.data.academyFeePlans.add(
        AcademyFeePlan(duration: 'Monthly', price: '0'),
      );
    });
    widget.controller.update();
  }

  @override
  Widget build(BuildContext context) {
    final GroundRegistrationData data = widget.controller.data;

    Widget categoryChip(String value) {
      final bool selected = data.academyCategory == value;
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              data.academyCategory = value;
            });
            widget.controller.update();
          },
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x1FFFFFFF)),
              color: selected
                  ? const Color(0xFFDDF730)
                  : const Color(0x0FFFFFFF),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: selected ? const Color(0xFF242424) : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    Widget dayChip(String day) {
      final bool selected = data.academyRecurringDays.contains(day);
      return InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              data.academyRecurringDays.remove(day);
            } else {
              data.academyRecurringDays.add(day);
            }
          });
          widget.controller.update();
        },
        child: Container(
          width: 63,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            color: selected ? const Color(0xFFDDF730) : const Color(0x0FFFFFFF),
          ),
          child: Text(
            day,
            style: TextStyle(
              color: selected ? const Color(0xFF242424) : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    Widget timeCard({
      required String label,
      required String value,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: onTap,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.schedule, size: 18, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget planRow(AcademyFeePlan plan, int index) {
      return Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () => _openDurationSelector(index),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        plan.duration,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _editPrice(index),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${plan.price}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => _editPrice(index),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x3DFFFFFF)),
              ),
              child: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _deletePlan(index),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x3DFFFFFF)),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Color(0xFFE3220D),
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Create Academy Batch',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: <Widget>[
                LabeledTextField(
                  label: 'Batch Name',
                  controller: _batchNameController,
                  hint: 'Morning Practice',
                  onChanged: (_) => _syncBasicFields(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Coach (Optional)',
                  controller: _coachController,
                  hint: 'Rahul Kumar',
                  onChanged: (_) => _syncBasicFields(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Per Batch Students',
                  controller: _studentsController,
                  keyboardType: TextInputType.number,
                  hint: '40',
                  onChanged: (_) => _syncBasicFields(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Category',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(children: _categories.map(categoryChip).toList(growable: false)),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Schedule (Recurring)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _days.map(dayChip).toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              timeCard(
                label: 'Start Time',
                value: data.academyStartTime,
                onTap: () => _pickTime(isStart: true),
              ),
              const SizedBox(width: 12),
              timeCard(
                label: 'End Time',
                value: data.academyEndTime,
                onTap: () => _pickTime(isStart: false),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              children: <Widget>[
                ...data.academyFeePlans.asMap().entries.map(
                  (MapEntry<int, AcademyFeePlan> entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == data.academyFeePlans.length - 1
                          ? 0
                          : 12,
                    ),
                    child: planRow(entry.value, entry.key),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addPlan,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Plan'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08B36A),
                foregroundColor: const Color(0xFF1D1D1D),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _syncBasicFields();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batch saved successfully')),
                );
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          NeonButton(
            label: 'Save & Continue',
            onPressed: () {
              _syncBasicFields();
              if (data.academyBatchName.isEmpty ||
                  data.academyPerBatchStudents.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill batch name and student count'),
                  ),
                );
                return;
              }
              if (data.academyFeePlans.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please add at least one fee plan'),
                  ),
                );
                return;
              }
              widget.controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}


