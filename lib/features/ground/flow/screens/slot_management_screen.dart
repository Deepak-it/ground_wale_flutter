import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/neon_button.dart';
import '../models/ground_registration_data.dart';
import 'configure_slots_screen.dart';

class SlotManagementScreen extends StatefulWidget {
  const SlotManagementScreen({super.key});

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> {
  final GroundRegistrationData data = GroundRegistrationData();
  static const List<String> _openingOptions = <String>[
    '05:00 AM',
    '06:00 AM',
    '07:00 AM',
    '08:00 AM',
  ];
  static const List<String> _slotSizeOptions = <String>[
    '1 hour',
    '90 mins',
    '2 hours',
    '3 hours',
  ];
  static const List<String> _gapOptions = <String>[
    '15 Minutes',
    '30 Minutes',
    '45 Minutes',
    '60 Minutes',
  ];

  Future<void> _pickDate(bool isStart) async {
    final DateTime initialDate = isStart ? data.startDate : data.endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          data.startDate = picked;
        } else {
          data.endDate = picked;
        }
      });
    }
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...options.map((String option) {
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

    setState(() => onSelected(selected));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> matchTypes = <String>['T20', 'T10', 'Full Day'];

    Widget dropdownTile(String label, String value, VoidCallback onTap) {
      final bool isDateLabel = label.contains('Date');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x30FFFFFF)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(value)),
                  Icon(
                    isDateLabel ? Icons.calendar_today_outlined : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF1C2C1A), Color(0xFF1D1D1D), Color(0xFF111311)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Slot Management', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: <Widget>[
                      dropdownTile(
                        'Opening Time',
                        data.openingTime,
                        () => _pickOption(
                          title: 'Select Opening Time',
                          options: _openingOptions,
                          onSelected: (String value) => data.openingTime = value,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Schedule Duration', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Slots will be active only within this date range.', style: TextStyle(color: Color(0xFF6B7280))),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(child: dropdownTile('Start Date', '${data.startDate.toLocal()}'.split(' ')[0], () => _pickDate(true))),
                          const SizedBox(width: 10),
                          Expanded(child: dropdownTile('End Date', '${data.endDate.toLocal()}'.split(' ')[0], () => _pickDate(false))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: dropdownTile(
                          'Slots Size',
                          data.slotSize,
                          () => _pickOption(
                            title: 'Select Slot Size',
                            options: _slotSizeOptions,
                            onSelected: (String value) => data.slotSize = value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: dropdownTile(
                          'Gap Between Slots',
                          data.gap,
                          () => _pickOption(
                            title: 'Select Gap',
                            options: _gapOptions,
                            onSelected: (String value) => data.gap = value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Select Match Type:', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: matchTypes.map((String type) {
                          final bool selected = data.matchType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: selected,
                            selectedColor: const Color(0xFFDDF730),
                            labelStyle: TextStyle(color: selected ? const Color(0xFF242424) : Colors.white),
                            backgroundColor: const Color(0x14FFFFFF),
                            side: const BorderSide(color: Color(0x30FFFFFF)),
                            onSelected: (_) {
                              setState(() {
                                data.matchType = type;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NeonButton(
                  label: 'Generate Slots',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ConfigureSlotsScreen(data: data)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
