import 'package:flutter/material.dart';

import '../../../../core/api/ground_wale_api.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';

class ConfigureSlotsScreen extends StatefulWidget {
  const ConfigureSlotsScreen({super.key, required this.data, this.controller});

  final GroundRegistrationData data;
  final GroundFlowController? controller;

  @override
  State<ConfigureSlotsScreen> createState() => _ConfigureSlotsScreenState();
}

class _ConfigureSlotsScreenState extends State<ConfigureSlotsScreen> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever the controller notifies (e.g. after slots are saved)
    widget.controller?.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(ConfigureSlotsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() => setState(() {});

  String _fmt(String iso) {
    try {
      final DateTime d = DateTime.parse(iso);
      const List<String> m = <String>[
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
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  List<_DurationGroup> _groupDrafts(List<Map<String, dynamic>> drafts) {
    final Map<String, _DurationGroup> byKey = <String, _DurationGroup>{};
    for (int i = 0; i < drafts.length; i++) {
      final Map<String, dynamic> d = drafts[i];
      final String fromRaw = d['dateFrom']?.toString() ?? '';
      final String toRaw = d['dateTo']?.toString() ?? '';
      final String key = '$fromRaw|$toRaw';
      final _DurationGroup group = byKey.putIfAbsent(
        key,
        () => _DurationGroup(
          fromIso: fromRaw,
          toIso: toRaw,
          label: d['name']?.toString() ?? 'Duration',
        ),
      );
      group.indexes.add(i);
      group.slots.add(d);
    }
    return byKey.values.toList(growable: false);
  }

  Map<String, dynamic> _extractDayPrices(Map<String, dynamic> draft) {
    final dynamic raw = draft['dayPrices'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  int _deriveBasePrice(Map<String, dynamic> draft, Map<String, dynamic> dayPrices) {
    final dynamic rawPrice = draft['price'];
    final int parsedPrice = rawPrice is int
        ? rawPrice
        : int.tryParse(rawPrice?.toString() ?? '') ?? 0;
    if (parsedPrice > 0) {
      return parsedPrice;
    }
    for (final dynamic value in dayPrices.values) {
      final int parsed = value is int
          ? value
          : int.tryParse(value?.toString() ?? '') ?? 0;
      if (parsed > 0) {
        return parsed;
      }
    }
    return 0;
  }

  Future<void> _generate() async {
    final GroundFlowController? ctrl = widget.controller;
    if (ctrl == null) return;
    setState(() => _isGenerating = true);
    try {
      final String? groundId = await ctrl.ensureDraftGroundId();
      if (groundId == null || groundId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not create ground. Try again.'),
            ),
          );
        }
        return;
      }
      for (final Map<String, dynamic> draft in widget.data.customSlotDrafts) {
        final Map<String, dynamic> dayPrices = _extractDayPrices(draft);
        final int basePrice = _deriveBasePrice(draft, dayPrices);
        await GroundWaleApi.instance.createSlot(groundId, <String, dynamic>{
          'dateFrom': draft['dateFrom'],
          'dateTo': draft['dateTo'],
          'startTime': draft['startTime'],
          'endTime': draft['endTime'],
          'price': basePrice,
          if (dayPrices.isNotEmpty) 'dayPrices': dayPrices,
          'status': 'available',
        });
      }

      if (!ctrl.isAcademyFlow && ctrl.skipOwnershipVerification) {
        await ctrl.submitGroundForVerification();
      }

      if (!mounted) return;
      ctrl.nextStep();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> drafts = widget.data.customSlotDrafts;
    final List<_DurationGroup> groups = _groupDrafts(drafts);
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    const Color(0xFF22452E).withValues(alpha: 0.55),
                    const Color(0xFF1D1D1D).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 16, 0),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () {
                            if (widget.controller != null) {
                              widget.controller!.previousStep();
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFDDF730),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Configure Slot',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    children: <Widget>[
                      if (groups.isEmpty) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0x08FFFFFF),
                            border: Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          child: const Column(
                            children: <Widget>[
                              Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFFDDF730),
                                size: 40,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No slots added yet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap "Add Duration" below to configure your first duration of slot.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0x99FFFFFF),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...<Widget>[
                        ...groups.asMap().entries.map((
                          MapEntry<int, _DurationGroup> entry,
                        ) {
                          final int i = entry.key;
                          final _DurationGroup group = entry.value;
                          final String from = _fmt(group.fromIso);
                          final String to = _fmt(group.toIso);
                          final String firstTime = group.slots.isEmpty
                              ? ''
                              : '${group.slots.first['startTime']} - ${group.slots.first['endTime']}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0x08FFFFFF),
                                border: Border.all(
                                  color: const Color(0x1AFFFFFF),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFDDF730),
                                      ),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFFDDF730),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          group.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '$from -> $to',
                                          style: const TextStyle(
                                            color: Color(0x99FFFFFF),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${group.slots.length} slots${firstTime.isEmpty ? '' : ' • $firstTime'}',
                                          style: const TextStyle(
                                            color: Color(0x99FFFFFF),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.controller != null) {
                                        widget
                                                .controller!
                                                .data
                                                .selectedDurationName =
                                            group.label;
                                        widget
                                                .controller!
                                                .data
                                                .selectedDurationFrom =
                                            group.fromIso;
                                        widget
                                                .controller!
                                                .data
                                                .selectedDurationTo =
                                            group.toIso;
                                        widget.controller!.jumpToStep(10);
                                      }
                                    },
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      color: Color(0xFFDDF730),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      widget.data.customSlotDrafts.removeWhere((
                                        Map<String, dynamic> item,
                                      ) {
                                        final String fromIso =
                                            item['dateFrom']?.toString() ?? '';
                                        final String toIso =
                                            item['dateTo']?.toString() ?? '';
                                        return fromIso == group.fromIso &&
                                            toIso == group.toIso;
                                      });
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0x99FFFFFF),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                      GestureDetector(
                        onTap: () => widget.controller?.jumpToStep(9),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDF730)),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(
                                  0xFFDDF730,
                                ).withValues(alpha: 0.18),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: Color(0xFFDDF730),
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Add Duration',
                                style: TextStyle(
                                  color: Color(0xFFDDF730),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isGenerating
                      ? null
                      : (groups.isEmpty ? null : _generate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDF730),
                    foregroundColor: const Color(0xFF1D1D1D),
                    disabledBackgroundColor: const Color(0x33DDF730),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF1D1D1D),
                          ),
                        )
                      : const Text(
                          'Generate Slots',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationGroup {
  _DurationGroup({
    required this.fromIso,
    required this.toIso,
    required this.label,
  });

  final String fromIso;
  final String toIso;
  final String label;
  final List<int> indexes = <int>[];
  final List<Map<String, dynamic>> slots = <Map<String, dynamic>>[];
}
