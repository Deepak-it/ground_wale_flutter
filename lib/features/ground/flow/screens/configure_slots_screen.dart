import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/neon_button.dart';
import '../models/ground_registration_data.dart';

class ConfigureSlotsScreen extends StatefulWidget {
  const ConfigureSlotsScreen({super.key, required this.data});

  final GroundRegistrationData data;

  @override
  State<ConfigureSlotsScreen> createState() => _ConfigureSlotsScreenState();
}

class _ConfigureSlotsScreenState extends State<ConfigureSlotsScreen> {
  bool get showOverlapWarning {
    final DaySlotConfig sun = widget.data.daySlots.last;
    return sun.isEnabled && sun.slotsPerDay >= 6;
  }

  @override
  Widget build(BuildContext context) {
    Widget dayRow(DaySlotConfig day) {
      final bool warningRow = day.day == 'Sun' && day.slotsPerDay >= 6;
      final Color accent = warningRow ? const Color(0xFFF59E0B) : const Color(0xFF08B36A);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: warningRow ? const Color(0x66F59E0B) : const Color(0x22FFFFFF)),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(day.day, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      Switch(
                        value: day.isEnabled,
                        activeThumbColor: accent,
                        onChanged: (bool value) {
                          setState(() {
                            day.isEnabled = value;
                            if (!value) {
                              day.slotsPerDay = 0;
                            } else if (day.slotsPerDay == 0) {
                              day.slotsPerDay = 1;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: !day.isEnabled || day.slotsPerDay <= 0
                            ? null
                            : () {
                                setState(() {
                                  day.slotsPerDay--;
                                });
                              },
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${day.slotsPerDay}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      IconButton(
                        onPressed: !day.isEnabled
                            ? null
                            : () {
                                setState(() {
                                  day.slotsPerDay++;
                                });
                              },
                        icon: Icon(Icons.add, color: warningRow ? const Color(0xFFF59E0B) : const Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: day.isEnabled ? const Color(0x14FFFFFF) : const Color(0x14000000),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  child: Text(day.isEnabled ? day.startTime : 'Off', style: TextStyle(color: day.isEnabled ? Colors.white : Colors.white60)),
                ),
              ],
            ),
            if (warningRow)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Too many slots warning (Overlaps next day)',
                        style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFDDF730)),
                    ),
                    const Text('Configure Slots', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  children: <Widget>[
                    const GlassCard(
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text('WEEKDAYS', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6))),
                          Expanded(child: Text('SLOTS/DAY', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6))),
                          Expanded(child: Text('START TIME', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.data.daySlots.map(dayRow),
                    if (showOverlapWarning)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Too many slots warning (Overlaps next day)',
                                style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: NeonButton(
                        label: 'Cancel',
                        outline: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonButton(
                        label: 'Next',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
