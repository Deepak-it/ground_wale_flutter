import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/labeled_text_field.dart';
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
  late final TextEditingController _coachNumberController;
  late final TextEditingController _studentsController;
  // ignore: unused_field
  String _selectedSport = 'Cricket';
  final Set<String> _selectedSports = <String>{'Cricket'};
  // ignore: unused_field
  final String _sportSearch = '';
  final TextEditingController _sportSearchController = TextEditingController();
  final Map<AcademyFeePlan, TextEditingController> _priceControllers =
      <AcademyFeePlan, TextEditingController>{};

  static const List<Map<String, String>> _allSports = <Map<String, String>>[
    <String, String>{'emoji': '🎯', 'name': 'Archery'},
    <String, String>{'emoji': '💪', 'name': 'Arm Wrestling'},
    <String, String>{'emoji': '🏸', 'name': 'Badminton'},
    <String, String>{'emoji': '⚾', 'name': 'Baseball'},
    <String, String>{'emoji': '🏀', 'name': 'Basketball'},
    <String, String>{'emoji': '🎱', 'name': 'Billiards'},
    <String, String>{'emoji': '🏋️', 'name': 'Bodybuilding'},
    <String, String>{'emoji': '🏏', 'name': 'Box Cricket'},
    <String, String>{'emoji': '🥊', 'name': 'Boxing'},
    <String, String>{'emoji': '♟️', 'name': 'Chess'},
    <String, String>{'emoji': '🏏', 'name': 'Cricket'},
    <String, String>{'emoji': '🚴', 'name': 'Cycling'},
    <String, String>{'emoji': '🤺', 'name': 'Fencing'},
    <String, String>{'emoji': '⚽', 'name': 'Football'},
    <String, String>{'emoji': '⚽', 'name': 'Futsal'},
    <String, String>{'emoji': '⛳', 'name': 'Golf'},
    <String, String>{'emoji': '🤸', 'name': 'Gymnastics'},
    <String, String>{'emoji': '🤾', 'name': 'Handball'},
    <String, String>{'emoji': '🏑', 'name': 'Hockey'},
    <String, String>{'emoji': '🏒', 'name': 'Ice Hockey'},
    <String, String>{'emoji': '🥋', 'name': 'Judo'},
    <String, String>{'emoji': '🤼', 'name': 'Kabaddi'},
    <String, String>{'emoji': '🥋', 'name': 'Karate'},
    <String, String>{'emoji': '🏃', 'name': 'Kho-Kho'},
    <String, String>{'emoji': '🎾', 'name': 'Lawn Tennis'},
    <String, String>{'emoji': '🤸', 'name': 'Mallakhamb'},
    <String, String>{'emoji': '🏎️', 'name': 'Motor Sports'},
    <String, String>{'emoji': '🏀', 'name': 'Netball'},
    <String, String>{'emoji': '🐎', 'name': 'Polo'},
    <String, String>{'emoji': '🏋️‍♂️', 'name': 'Powerlifting'},
    <String, String>{'emoji': '🛼', 'name': 'Roller Skating'},
    <String, String>{'emoji': '🚣', 'name': 'Rowing'},
    <String, String>{'emoji': '🏉', 'name': 'Rugby'},
    <String, String>{'emoji': '🎯', 'name': 'Shooting'},
    <String, String>{'emoji': '🛹', 'name': 'Skateboarding'},
    <String, String>{'emoji': '⚾', 'name': 'Softball'},
    <String, String>{'emoji': '🎾', 'name': 'Squash'},
    <String, String>{'emoji': '🏊', 'name': 'Swimming'},
    <String, String>{'emoji': '🏓', 'name': 'Table Tennis'},
    <String, String>{'emoji': '🥋', 'name': 'Taekwondo'},
    <String, String>{'emoji': '🎾', 'name': 'Tennis'},
    <String, String>{'emoji': '🏐', 'name': 'Throwball'},
    <String, String>{'emoji': '🏊🚴🏃', 'name': 'Triathlon'},
    <String, String>{'emoji': '🏐', 'name': 'Volleyball'},
    <String, String>{'emoji': '🤽', 'name': 'Water Polo'},
    <String, String>{'emoji': '🏋️', 'name': 'Weightlifting'},
    <String, String>{'emoji': '🤼', 'name': 'Wrestling'},
    <String, String>{'emoji': '🥋', 'name': 'Wushu'},
    <String, String>{'emoji': '⛵', 'name': 'Yachting'},
  ];

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController(
      text: widget.controller.data.academyBatchName,
    );
    _coachController = TextEditingController(
      text: widget.controller.data.academyCoachName,
    );
    _coachNumberController = TextEditingController();
    _studentsController = TextEditingController(
      text: widget.controller.data.academyPerBatchStudents,
    );
    _coachExperience = widget.controller.data.academyCoachExperience;

    final List<String> initialSports = widget.controller.data.selectedSports
        .where((String sport) => sport.trim().isNotEmpty)
        .toList(growable: false);
    _selectedSports
      ..clear()
      ..add(initialSports.isNotEmpty ? initialSports.first : 'Cricket');
    _selectedSport = _selectedSports.first;
    widget.controller.data.selectedSports
      ..clear()
      ..add(_selectedSport);
  }

  late int _coachExperience;

  @override
  void dispose() {
    _batchNameController.dispose();
    _coachController.dispose();
    _coachNumberController.dispose();
    _studentsController.dispose();
    _sportSearchController.dispose();
    for (final TextEditingController controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _priceControllerForPlan(AcademyFeePlan plan) {
    return _priceControllers.putIfAbsent(
      plan,
      () => TextEditingController(text: plan.price),
    );
  }

  void _syncBasicFields() {
    widget.controller.data.academyBatchName = _batchNameController.text.trim();
    widget.controller.data.academyCoachName = _coachController.text.trim();
    widget.controller.data.academyCoachExperience = _coachExperience;
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

  void _deletePlan(int index) {
    final String dur = widget.controller.data.academyFeePlans[index].duration
        .toLowerCase();
    if (dur == 'monthly') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monthly fee plan is required and cannot be removed'),
        ),
      );
      return;
    }
    if (widget.controller.data.academyFeePlans.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one plan is required')),
      );
      return;
    }
    final AcademyFeePlan removed =
        widget.controller.data.academyFeePlans[index];
    _priceControllers.remove(removed)?.dispose();
    setState(() {
      widget.controller.data.academyFeePlans.removeAt(index);
    });
    widget.controller.update();
  }

  void _addPlan() {
    final AcademyFeePlan plan = AcademyFeePlan(duration: 'Monthly', price: '0');
    setState(() {
      widget.controller.data.academyFeePlans.add(plan);
    });
    _priceControllers[plan] = TextEditingController(text: plan.price);
    widget.controller.update();
  }

  Future<void> _openSportsSheet() async {
    final Set<String> tempSelected = Set<String>.from(_selectedSports);
    final TextEditingController searchCtrl = TextEditingController();
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter sheetSetState) {
            final List<Map<String, String>> visible = query.isEmpty
                ? _allSports
                : _allSports
                      .where(
                        (Map<String, String> s) => s['name']!
                            .toLowerCase()
                            .contains(query.toLowerCase()),
                      )
                      .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (BuildContext _, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: <Widget>[
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'All Sports Events',
                            style: TextStyle(
                              color: Color(0xFF242424),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final TextEditingController ctrl =
                                  TextEditingController();
                              final String? custom = await showDialog<String>(
                                context: ctx,
                                builder: (BuildContext dlgCtx) => AlertDialog(
                                  title: const Text('Add Sport'),
                                  content: TextField(
                                    controller: ctrl,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Martial Arts',
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dlgCtx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        dlgCtx,
                                      ).pop(ctrl.text.trim()),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              );
                              ctrl.dispose();
                              if (custom != null && custom.isNotEmpty) {
                                sheetSetState(() {
                                  tempSelected
                                    ..clear()
                                    ..add(custom);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFF242424),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Add Sport',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search bar
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x1F242424)),
                          color: const Color(0x1FFFFFFF),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.search,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: searchCtrl,
                                style: const TextStyle(
                                  color: Color(0xFF242424),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search sports',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (String value) {
                                  sheetSetState(() => query = value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 4-column grid
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: visible.length,
                          itemBuilder: (BuildContext _, int index) {
                            final String name = visible[index]['name']!;
                            final String emoji = visible[index]['emoji']!;
                            final bool sel = tempSelected.contains(name);
                            return GestureDetector(
                              onTap: () {
                                sheetSetState(() {
                                  tempSelected
                                    ..clear()
                                    ..add(name);
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 56,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sel
                                          ? const Color(0xFF1C333B)
                                          : const Color(0x1F0D1B2A),
                                      boxShadow: sel
                                          ? const <BoxShadow>[
                                              BoxShadow(
                                                color: Color(0x663B82F6),
                                                blurRadius: 12,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF242424),
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Done button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C333B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    searchCtrl.dispose();
    setState(() {
      _selectedSports
        ..clear()
        ..addAll(tempSelected);
      _selectedSport = _selectedSports.isNotEmpty ? _selectedSports.first : '';
      widget.controller.data.selectedSports
        ..clear()
        ..addAll(_selectedSports.take(1));
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
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x1FFFFFFF)),
                color: const Color(0x0FFFFFFF),
              ),
              alignment: Alignment.centerLeft,
              child: AppTextField(
                key: ValueKey<String>('plan_price_input_$index'),
                controller: _priceControllerForPlan(plan),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  prefixText: '₹',
                  hintText: '0',
                ),
                onChanged: (String value) {
                  final String normalized = value.startsWith('₹')
                      ? value.replaceFirst('₹', '')
                      : value;
                  widget.controller.data.academyFeePlans[index].price =
                      normalized;
                  widget.controller.update();
                },
              ),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Step 3 of 5',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 16),
          // Choose Sports — tappable field that opens Figma-style bottom sheet
          const Text(
            'Choose Sports',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openSportsSheet(),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x1FFFFFFF)),
                color: const Color(0x0FFFFFFF),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _selectedSports.isEmpty
                          ? 'Select sports'
                          : _selectedSports.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _selectedSports.isEmpty
                            ? Colors.white54
                            : Colors.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 24,
                  ),
                ],
              ),
            ),
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
                  hint: 'Munish Rathee',
                  onChanged: (_) => _syncBasicFields(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Coach Number (Optional)',
                  controller: _coachNumberController,
                  hint: '+91 9876543210',
                  keyboardType: TextInputType.phone,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 14),
                // Coach Experience stepper
                const Text(
                  'Coach Experience',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'In years',
                  style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                    color: const Color(0x0AFFFFFF),
                  ),
                  child: Row(
                    children: <Widget>[
                      _StepperBtn(
                        icon: Icons.remove,
                        onTap: () {
                          if (_coachExperience > 0) {
                            setState(() => _coachExperience--);
                            _syncBasicFields();
                          }
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$_coachExperience yr${_coachExperience == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      _StepperBtn(
                        icon: Icons.add,
                        onTap: () {
                          if (_coachExperience < 99) {
                            setState(() => _coachExperience++);
                            _syncBasicFields();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Batch Capacity',
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
                  'Coaching Days',
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
          const Text(
            'Add Fee Structure',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDDF730),
                foregroundColor: const Color(0xFF1D1D1D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: const Color(0x3DDDF730),
              ),
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
              child: const Text(
                'Add Batch',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0x0AFFFFFF),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}
