import 'package:flutter/material.dart';

import '../../../core/api/ground_wale_api.dart';

class SportsNeoBookingCartScreen extends StatefulWidget {
  const SportsNeoBookingCartScreen({super.key});

  @override
  State<SportsNeoBookingCartScreen> createState() =>
      _SportsNeoBookingCartScreenState();
}

class _SportsNeoBookingCartScreenState extends State<SportsNeoBookingCartScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  bool _isLoading = true;
  final List<_CartGroundItem> _items = <_CartGroundItem>[];

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    try {
      final List<Map<String, dynamic>> grounds = await _api.listGrounds();
      final List<_CartGroundItem> mapped = <_CartGroundItem>[];

      for (final Map<String, dynamic> ground in grounds.take(2)) {
        final String? groundId =
            ground['_id']?.toString() ?? ground['id']?.toString();
        List<Map<String, dynamic>> slots = <Map<String, dynamic>>[];
        if (groundId != null && groundId.isNotEmpty) {
          try {
            slots = await _api.listSlots(groundId);
          } catch (_) {}
        }
        mapped.add(_CartGroundItem.fromApi(ground, slots));
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(mapped.isEmpty ? _fallbackCartItems : mapped);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(_fallbackCartItems);
        _isLoading = false;
      });
    }
  }

  double get _subtotal =>
      _items.fold<double>(0, (sum, item) => sum + item.totalPrice);

  double get _discount => _items.isEmpty ? 0 : 100;

  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  void _removeGround(_CartGroundItem item) {
    setState(() => _items.remove(item));
  }

  void _removeSlot(_CartGroundItem item, String slot) {
    setState(() {
      final int index = _items.indexOf(item);
      if (index == -1) {
        return;
      }
      final List<String> updatedSlots = List<String>.from(item.selectedSlots)
        ..remove(slot);
      if (updatedSlots.isEmpty) {
        _items.removeAt(index);
        return;
      }
      _items[index] = item.copyWith(selectedSlots: updatedSlots);
    });
  }

  void _addSlot(_CartGroundItem item) {
    setState(() {
      final int index = _items.indexOf(item);
      if (index == -1) {
        return;
      }
      final List<String> updated = List<String>.from(item.selectedSlots)
        ..add(item.suggestedNextSlot);
      _items[index] = item.copyWith(selectedSlots: updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _CartHeader(count: _items.length),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Column(
                        children: <Widget>[
                          ..._items.map(
                            (_CartGroundItem item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CartGroundCard(
                                item: item,
                                onRemoveGround: () => _removeGround(item),
                                onRemoveSlot: (String slot) =>
                                    _removeSlot(item, slot),
                                onAddSlot: () => _addSlot(item),
                              ),
                            ),
                          ),
                          _DashedActionRow(
                            label: 'Apply Coupon',
                            icon: Icons.confirmation_num_outlined,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coupon flow is not available yet'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _PriceSummaryCard(
                            subtotal: _subtotal,
                            discount: _discount,
                            total: _total,
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _items.isEmpty
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking submission flow will be connected next'),
                            ),
                          );
                        },
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Booking Cart ($count)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartGroundCard extends StatelessWidget {
  const _CartGroundCard({
    required this.item,
    required this.onRemoveGround,
    required this.onRemoveSlot,
    required this.onAddSlot,
  });

  final _CartGroundItem item;
  final VoidCallback onRemoveGround;
  final ValueChanged<String> onRemoveSlot;
  final VoidCallback onAddSlot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0AFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              const Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                item.location,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'SELECTED SLOTS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: <Widget>[
              ...item.selectedSlots.map(
                (String slot) => _SlotChip(
                  label: slot,
                  onRemove: () => onRemoveSlot(slot),
                ),
              ),
              _AddSlotChip(onTap: onAddSlot),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'FACILITIES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.facilities
                .map(
                  (String facility) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: Text(
                      facility,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '₹${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                InkWell(
                  onTap: onRemoveGround,
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Remove Ground',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x0AE6F7F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

class _AddSlotChip extends StatelessWidget {
  const _AddSlotChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.add, color: Color(0xFF0EA5A4), size: 16),
            SizedBox(width: 4),
            Text(
              'Add Slot',
              style: TextStyle(
                color: Color(0xFF0EA5A4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedActionRow extends StatelessWidget {
  const _DashedActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF0EA5A4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: const Color(0xFF0EA5A4), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0EA5A4),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF0EA5A4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummaryCard extends StatelessWidget {
  const _PriceSummaryCard({
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final double subtotal;
  final double discount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0AFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Price Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Subtotal', value: '₹${subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Discount',
            value: '-₹${discount.toStringAsFixed(0)}',
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Total',
            value: '₹${total.toStringAsFixed(0)}',
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.color = Colors.white,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final FontWeight weight = isBold ? FontWeight.w700 : FontWeight.w400;
    final double size = isBold ? 16 : 14;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(color: color, fontSize: size, fontWeight: weight),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: size, fontWeight: weight),
        ),
      ],
    );
  }
}

class _CartGroundItem {
  const _CartGroundItem({
    required this.name,
    required this.location,
    required this.selectedSlots,
    required this.facilities,
    required this.pricePerSlot,
    required this.suggestedNextSlot,
  });

  factory _CartGroundItem.fromApi(
    Map<String, dynamic> ground,
    List<Map<String, dynamic>> slots,
  ) {
    final List<String> selectedSlots = slots
        .take(2)
        .map((Map<String, dynamic> slot) => _slotLabel(slot))
        .where((String text) => text.isNotEmpty)
        .toList();

    final List<String> facilities = ((ground['facilities'] as List?) ?? <dynamic>[])
        .take(3)
        .map((dynamic item) => item.toString())
        .toList();

    final double price = _groundPrice(ground) ?? 400;

    return _CartGroundItem(
      name: ground['groundName']?.toString() ?? ground['name']?.toString() ?? 'Ground',
      location: ground['city']?.toString() ?? ground['location']?.toString() ?? 'Mohali',
      selectedSlots: selectedSlots.isEmpty
          ? <String>['5:00 - 6:00 PM', '6:00 - 7:00 PM']
          : selectedSlots,
      facilities: facilities.isEmpty
          ? <String>['Floodlights', 'Parking', 'Washroom']
          : facilities,
      pricePerSlot: price,
      suggestedNextSlot: slots.length > 2
          ? _slotLabel(slots[2])
          : '7:00 - 8:00 PM',
    );
  }

  final String name;
  final String location;
  final List<String> selectedSlots;
  final List<String> facilities;
  final double pricePerSlot;
  final String suggestedNextSlot;

  double get totalPrice => selectedSlots.length * pricePerSlot;

  _CartGroundItem copyWith({List<String>? selectedSlots}) {
    return _CartGroundItem(
      name: name,
      location: location,
      selectedSlots: selectedSlots ?? this.selectedSlots,
      facilities: facilities,
      pricePerSlot: pricePerSlot,
      suggestedNextSlot: suggestedNextSlot,
    );
  }

  static double? _groundPrice(Map<String, dynamic> ground) {
    final dynamic raw = ground['hourlyPrice'] ??
        ground['pricePerHour'] ??
        ground['hourlyRate'];
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    return null;
  }

  static String _slotLabel(Map<String, dynamic> slot) {
    final String start = slot['startTime']?.toString() ?? '';
    final String end = slot['endTime']?.toString() ?? '';
    if (start.isEmpty && end.isEmpty) {
      return '';
    }
    return end.isEmpty ? start : '$start - $end';
  }
}

final List<_CartGroundItem> _fallbackCartItems = <_CartGroundItem>[
  const _CartGroundItem(
    name: 'Green Turf Arena',
    location: 'Mohali',
    selectedSlots: <String>['5:00 - 6:00 PM', '6:00 - 7:00 PM'],
    facilities: <String>['Floodlights', 'Parking', 'Washroom'],
    pricePerSlot: 400,
    suggestedNextSlot: '7:00 - 8:00 PM',
  ),
  const _CartGroundItem(
    name: 'Champions Box Cricket',
    location: 'Sector 62',
    selectedSlots: <String>['7:00 - 8:00 PM'],
    facilities: <String>['Parking', 'Washroom'],
    pricePerSlot: 500,
    suggestedNextSlot: '8:00 - 9:00 PM',
  ),
];