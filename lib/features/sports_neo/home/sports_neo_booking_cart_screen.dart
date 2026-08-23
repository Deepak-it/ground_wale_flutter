import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'sports_neo_booking_cart_store.dart';
import 'sports_neo_booking_history_screen.dart';

class SportsNeoBookingCartScreen extends StatefulWidget {
  const SportsNeoBookingCartScreen({super.key});

  @override
  State<SportsNeoBookingCartScreen> createState() =>
      _SportsNeoBookingCartScreenState();
}

class _SportsNeoBookingCartScreenState
    extends State<SportsNeoBookingCartScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  final SportsNeoBookingCartStore _cartStore =
      SportsNeoBookingCartStore.instance;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _syncCart();
  }

  Future<void> _syncCart() async {
    try {
      await _cartStore.refreshFromServer();
    } catch (_) {
      // Keep current state if cart sync fails.
    }
  }

  int _bookingTotal(List<SportsNeoBookingCartGround> items) {
    return items.fold<int>(0, (int sum, SportsNeoBookingCartGround item) {
      return sum + item.totalAmount;
    });
  }

  Future<void> _submitCart(List<SportsNeoBookingCartGround> items) async {
    if (_isSubmitting || items.isEmpty) {
      return;
    }

    final String playerName =
        (ApiSession.instance.ownerName ?? '').trim().isEmpty
        ? 'Sports Neo Player'
        : ApiSession.instance.ownerName!.trim();
    final String playerPhone = (ApiSession.instance.contactNumber ?? '').trim();

    setState(() => _isSubmitting = true);

    final Set<String> successKeys = <String>{};
    int successCount = 0;
    int failedCount = 0;
    String? firstError;

    try {
      for (final SportsNeoBookingCartGround item in items) {
        for (final SportsNeoBookingCartSlot slot in item.slots) {
          try {
            await _api.createBooking(item.groundId, <String, dynamic>{
              'slotId': slot.slotId,
              'teamName': playerName,
              'captainName': playerName,
              'captainPhone': playerPhone,
              'date': slot.date,
              'startTime': slot.startTime,
              'endTime': slot.endTime,
              'amount': slot.amount,
              'paymentMethod': 'cod',
              'notes': 'User booking request from cart',
              'playerCount': 0,
              'source': 'player',
              'requestedByUserId': ApiSession.instance.ownerId,
            });
            successKeys.add('${item.groundId}|${slot.key}');
            successCount += 1;
          } catch (error) {
            failedCount += 1;
            firstError ??= error.toString().replaceFirst('Exception: ', '');
          }
        }
      }

      for (final SportsNeoBookingCartGround item in items) {
        for (final SportsNeoBookingCartSlot slot in item.slots) {
          final String key = '${item.groundId}|${slot.key}';
          if (successKeys.contains(key)) {
            await _cartStore.removeSlot(item.groundId, slot.key);
          }
        }
      }

      if (failedCount == 0) {
        await _cartStore.clear();
      }

      if (!mounted) {
        return;
      }

      final String message;
      if (failedCount == 0) {
        message = 'Booked $successCount slot(s) successfully.';
      } else {
        message =
            'Booked $successCount slot(s). Failed $failedCount slot(s)${firstError == null ? '' : ': $firstError'}';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      if (failedCount == 0) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const SportsNeoBookingHistoryScreen(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: ValueListenableBuilder<List<SportsNeoBookingCartGround>>(
          valueListenable: _cartStore.notifier,
          builder:
              (
                BuildContext context,
                List<SportsNeoBookingCartGround> items,
                _,
              ) {
                final int subtotal = _bookingTotal(items);

                return Column(
                  children: <Widget>[
                    _CartHeader(count: items.length),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        child: Column(
                          children: <Widget>[
                            if (items.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0x1FFFFFFF),
                                  ),
                                  color: const Color(0x0AFFFFFF),
                                ),
                                child: const Text(
                                  'Your cart is empty. Add slots from ground details.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              ...items.map(
                                (SportsNeoBookingCartGround item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _CartGroundCard(
                                    item: item,
                                    onRemoveGround: () async {
                                      await _cartStore.removeGround(
                                        item.groundId,
                                      );
                                    },
                                    onRemoveSlot: (String slotKey) {
                                      _cartStore.removeSlot(
                                        item.groundId,
                                        slotKey,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            _PriceSummaryCard(
                              subtotal: subtotal.toDouble(),
                              discount: 0,
                              total: subtotal.toDouble(),
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
                          onPressed: items.isEmpty || _isSubmitting
                              ? null
                              : () => _submitCart(items),
                          child: Text(
                            _isSubmitting ? 'Booking...' : 'Book Now',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
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
  });

  final SportsNeoBookingCartGround item;
  final VoidCallback onRemoveGround;
  final ValueChanged<String> onRemoveSlot;

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
            item.groundName,
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
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 14,
              ),
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
              ...item.slots.map((SportsNeoBookingCartSlot slot) {
                final String label =
                    '${slot.startTime} - ${slot.endTime} (${slot.date})';
                return _SlotChip(
                  label: label,
                  onRemove: () => onRemoveSlot(slot.key),
                );
              }),
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
                  '₹${item.totalAmount}',
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
                      Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
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
          _SummaryRow(
            label: 'Subtotal',
            value: '₹${subtotal.toStringAsFixed(0)}',
          ),
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
