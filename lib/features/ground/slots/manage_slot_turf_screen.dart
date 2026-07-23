import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'add_slot_turf_screen.dart';
import 'block_slot_turf_screen.dart';
import 'delete_slot_turf_screen.dart';
import 'edit_slot_turf_screen.dart';

class ManageSlotTurfScreen extends StatefulWidget {
  const ManageSlotTurfScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<ManageSlotTurfScreen> createState() => _ManageSlotTurfScreenState();
}

class _ManageSlotTurfScreenState extends State<ManageSlotTurfScreen> {
  String dayFilter = 'Today';
  String statusFilter = 'All';
  final GroundWaleApi _api = GroundWaleApi.instance;
  late Future<List<Map<String, dynamic>>> _slotsFuture = _loadSlots();
DateTime _selectedDate = DateTime.now();

String get _selectedDateString {
  return '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';
}
  String _slotId(Map<String, dynamic> slot) {
    return slot['_id']?.toString() ?? slot['id']?.toString() ?? '';
  }

  Future<String?> _resolveGroundId() async {
    final ApiSession session = ApiSession.instance;
    if (session.hasGround) {
      return session.groundId;
    }
    if (!session.isAuthenticated) {
      return null;
    }

    final String? groundId = await _api.ensureGroundIdForOwner(session.ownerId!);
    session.setGroundId(groundId);
    return groundId;
  }

  Future<List<Map<String, dynamic>>> _loadSlots() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null) {
      return <Map<String, dynamic>>[];
    }
return _api.listSlots(
  groundId,
    date: _selectedDateString, // yyyy-MM-dd
  );
  }

  void _refresh() {
    setState(() => _slotsFuture = _loadSlots());
  }

  bool _matchesDayFilter(Map<String, dynamic> slot) {
    if (dayFilter == 'This Week') {
      return true;
    }

    final DateTime? slotDate = DateTime.tryParse(slot['date']?.toString() ?? '');
    if (slotDate == null) {
      return dayFilter == 'This Week';
    }

    final DateTime today = DateTime.now();
    final DateTime tomorrow = today.add(const Duration(days: 1));
    if (dayFilter == 'Today') {
      return slotDate.year == today.year && slotDate.month == today.month && slotDate.day == today.day;
    }
    return slotDate.year == tomorrow.year && slotDate.month == tomorrow.month && slotDate.day == tomorrow.day;
  }

  String _formatSlotDate(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    Widget dayChip(String label) {
      final bool selected = dayFilter == label;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFFDDF730),
        labelStyle: TextStyle(color: selected ? const Color(0xFF242424) : Colors.white),
        backgroundColor: const Color(0x12FFFFFF),
        side: const BorderSide(color: Color(0x30FFFFFF)),
        onSelected: (_) {
          setState(() {
            dayFilter = label;

            if (label == 'Today') {
              _selectedDate = DateTime.now();
            } else if (label == 'Tomorrow') {
              _selectedDate = DateTime.now().add(const Duration(days: 1));
            } else {
              _selectedDate = DateTime.now();
            }

            _slotsFuture = _loadSlots();
          });
        },      );
    }

    Widget statusChip(String label) {
      final bool selected = statusFilter == label;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0x22DDF730),
        labelStyle: TextStyle(color: selected ? const Color(0xFFDDF730) : Colors.white),
        backgroundColor: const Color(0x12FFFFFF),
        side: BorderSide(color: selected ? const Color(0xFFDDF730) : const Color(0x30FFFFFF)),
        onSelected: (_) => setState(() => statusFilter = label),
      );
    }

    Widget slotCard(Map<String, dynamic> slot) {
      final String status = slot['status']?.toString() ?? 'available';
      final bool isBooked = status == 'booked';
      final Color dotColor = status == 'blocked'
          ? const Color(0xFFF59E0B)
          : isBooked
              ? const Color(0xFFE3220D)
              : const Color(0xFF22C55E);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x10FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x30FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${slot['startTime'] ?? '--'} - ${slot['endTime'] ?? '--'}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            isBooked ? (slot['bookedByTeam']?.toString() ?? 'Booked') : status[0].toUpperCase() + status.substring(1),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
Text(
  _formatSlotDate(_selectedDateString),
  style: const TextStyle(
    color: Colors.white54,
    fontSize: 13,
  ),
),                    ],
                  ),
                ),
                Text('₹${slot['price'] ?? 0}', style: const TextStyle(color: Color(0xFF08B36A), fontSize: 19, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF08B36A),
                      side: const BorderSide(color: Color(0x3308B36A)),
                      backgroundColor: const Color(0x2208B36A),
                    ),
                    onPressed: () async {
                      final bool? didUpdate = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(builder: (_) => EditSlotTurfScreen(slot: slot)),
                      );
                      if (didUpdate == true) {
                        _refresh();
                      }
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0x33F59E0B)),
                    backgroundColor: const Color(0x22F59E0B),
                  ),
                  onPressed: () async {
                    final String slotId = _slotId(slot);
                    if (slotId.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to block slot: missing slot id.')),
                        );
                      }
                      return;
                    }
                    final bool? didBlock = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(builder: (_) => BlockSlotTurfScreen(slotId: slotId)),
                    );
                    if (didBlock == true) {
                      _refresh();
                    }
                  },
                  child: const Text('Block'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE3220D),
                    side: const BorderSide(color: Color(0x33E3220D)),
                    backgroundColor: const Color(0x22E3220D),
                  ),
                  onPressed: () async {
                    final String slotId = _slotId(slot);
                    if (slotId.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to delete slot: missing slot id.')),
                        );
                      }
                      return;
                    }
                    final bool? didDelete = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(builder: (_) => DeleteSlotTurfScreen(slotId: slotId)),
                    );
                    if (didDelete == true) {
                      _refresh();
                    }
                  },
                  child: Text(isBooked ? 'Booked' : 'Delete', style: TextStyle(color: isBooked ? const Color(0xFFE3220D) : const Color(0xFFE3220D))),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: <Widget>[
                  if (widget.showBackButton)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    )
                  else
                    const SizedBox(width: 48),
                  const Expanded(
                    child: Text('Manage Slots', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
                  ),
                  Container(
                    decoration: BoxDecoration(color: const Color(0x22DDF730), borderRadius: BorderRadius.circular(14)),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AddSlotTurfScreen()));
                      },
                      icon: const Icon(Icons.add, color: Color(0xFFDDF730)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _slotsFuture,
                builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                final List<Map<String, dynamic>> slots =
                    (snapshot.data ?? <Map<String, dynamic>>[])
                        .where((slot) =>
                            statusFilter == 'All' ||
                            slot['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                statusFilter.toLowerCase())
                        .toList();

                  final int bookedCount = slots.where((Map<String, dynamic> slot) => slot['status'] == 'booked').length;
                  final int earned = slots.fold<int>(0, (int total, Map<String, dynamic> slot) => total + ((slot['price'] as num?)?.toInt() ?? 0));

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: <Widget>[
                      Wrap(spacing: 10, runSpacing: 10, children: <Widget>[dayChip('Today'), dayChip('Tomorrow'), dayChip('This Week')]),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[statusChip('All'), statusChip('Available'), statusChip('Booked'), statusChip('Blocked')],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0x10FFFFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x30FFFFFF)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _Kpi(label: '${slots.length} Slots', sub: 'Current filter'),
                            _Kpi(label: '$bookedCount Booked', sub: 'Live bookings'),
                            _Kpi(label: '₹$earned', sub: 'Listed value'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)))
                      else if (snapshot.hasError)
                        Text(snapshot.error.toString().replaceFirst('Exception: ', ''), style: const TextStyle(color: Colors.redAccent))
                      else if (slots.isEmpty)
                        const Text('No slots found for the selected filters.', style: TextStyle(color: Colors.white70))
                      else
                        ...slots.map((Map<String, dynamic> slot) => Padding(padding: const EdgeInsets.only(bottom: 12), child: slotCard(slot))),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.sub});

  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ],
    );
  }
}
