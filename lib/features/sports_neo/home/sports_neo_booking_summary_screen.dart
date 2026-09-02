import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/payments/cashfree_checkout.dart';
import 'sports_neo_booking_cart_store.dart';
import 'sports_neo_match_details_screen.dart';

class SportsNeoBookingSummaryScreen extends StatefulWidget {
  const SportsNeoBookingSummaryScreen({
    super.key,
    required this.groundName,
    required this.location,
    this.groundId = '',
    this.slotId = '',
    this.date = '',
    this.startTime = '',
    this.endTime = '',
    this.amount = 0,
  });

  final String groundName;
  final String location;
  final String groundId;
  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  final int amount;

  @override
  State<SportsNeoBookingSummaryScreen> createState() =>
      _SportsNeoBookingSummaryScreenState();
}

class _SportsNeoBookingSummaryScreenState
    extends State<SportsNeoBookingSummaryScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  final SportsNeoBookingCartStore _cartStore =
      SportsNeoBookingCartStore.instance;

  bool _isSubmitting = false;
  String _paymentMethod = 'CASHFREE';

  static const List<String> _paymentMethods = <String>['CASHFREE', 'COD'];

  String _formatDate(String isoDate) {
    try {
      final DateTime d = DateTime.parse(isoDate);
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
      const List<String> weekdays = <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];
      return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _submitBookingRequest(int totalAmount) async {
    if (_isSubmitting) {
      return;
    }

    if (widget.groundId.trim().isEmpty || widget.slotId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ground or slot details are missing.')),
      );
      return;
    }

    final String playerName =
        (ApiSession.instance.ownerName ?? '').trim().isEmpty
        ? 'Sports Neo Player'
        : ApiSession.instance.ownerName!.trim();
    final String playerPhone = (ApiSession.instance.contactNumber ?? '').trim();

    setState(() => _isSubmitting = true);
    try {
      if (_paymentMethod == 'CASHFREE' && totalAmount > 0) {
        if (playerPhone.isEmpty) {
          throw Exception('Contact number is missing for Cashfree payment');
        }

        final Map<String, dynamic>
        token = await _api.createCashfreeToken(widget.groundId, <
          String,
          dynamic
        >{
          'orderAmount': totalAmount,
          'orderCurrency': 'INR',
          'customerPhone': playerPhone,
          'customerName': playerName,
          'orderNote':
              'Ground booking ${widget.date} ${widget.startTime}-${widget.endTime}',
        });

        await CashfreeCheckout.payWithToken(
          token,
          fallbackPhone: playerPhone,
          fallbackName: playerName,
          fallbackOrderNote: 'Ground booking payment',
          color1: '#2563EB',
          color2: '#0A0F1E',
        );
      }

      await _api.createBooking(widget.groundId, <String, dynamic>{
        'slotId': widget.slotId,
        'teamName': playerName,
        'captainName': playerName,
        'captainPhone': playerPhone,
        'date': widget.date,
        'startTime': widget.startTime,
        'endTime': widget.endTime,
        'amount': totalAmount,
        'paymentMethod': _paymentMethod == 'CASHFREE' ? 'cashfree' : 'cod',
        'notes': 'User booking request',
        'playerCount': 0,
        'source': 'player',
        'requestedByUserId': ApiSession.instance.ownerId,
      });

      // If this slot already exists in cart from an earlier add action,
      // remove it after successful direct booking.
      final String slotKey = '${widget.slotId}|${widget.date}';
      if (widget.groundId.trim().isNotEmpty && slotKey.trim().isNotEmpty) {
        try {
          await _cartStore.removeSlot(widget.groundId, slotKey);
        } catch (_) {
          // Booking is already successful; ignore cart cleanup failures.
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SportsNeoMatchDetailsScreen(
            amount: totalAmount,
            groundName: widget.groundName,
            location: widget.location,
            date: widget.date,
            startTime: widget.startTime,
            endTime: widget.endTime,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int groundFee = widget.amount > 0 ? widget.amount : 0;
    final int total = groundFee;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopHeader(
              title: 'Booking Summary',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.groundName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0x99FFFFFF),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'Selected Slots',
                      child: Column(
                        children: <Widget>[
                          _slotRow(
                            _formatDate(widget.date),
                            widget.startTime.isNotEmpty &&
                                    widget.endTime.isNotEmpty
                                ? '${widget.startTime} - ${widget.endTime}'
                                : '—',
                            widget.amount > 0 ? '₹${widget.amount}' : '—',
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(height: 16),
                    // _Card(
                    //   title: 'Paid add-ons',
                    //   child: Column(
                    //     children: <Widget>[
                    //       Row(
                    //         children: <Widget>[
                    //           Expanded(
                    //             child: _AddonItem(
                    //               title: 'Balls',
                    //               count: _balls,
                    //               active: true,
                    //               onMinus: () {
                    //                 if (_balls > 0) {
                    //                   setState(() => _balls -= 1);
                    //                 }
                    //               },
                    //               onPlus: () => setState(() => _balls += 1),
                    //             ),
                    //           ),
                    //           const SizedBox(width: 12),
                    //           Expanded(
                    //             child: _AddonItem(
                    //               title: 'Umpires',
                    //               count: _umpires,
                    //               active: false,
                    //               onMinus: () {
                    //                 if (_umpires > 0) {
                    //                   setState(() => _umpires -= 1);
                    //                 }
                    //               },
                    //               onPlus: () => setState(() => _umpires += 1),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'Payment Method',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _paymentMethods.map((String method) {
                          final bool selected = _paymentMethod == method;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _paymentMethod = method),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: selected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0x0DFFFFFF),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0x1FFFFFFF),
                                ),
                              ),
                              child: Text(
                                method,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xCCFFFFFF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'Payment Summary',
                      child: Column(
                        children: <Widget>[
                          _payRow(
                            'Ground Fee',
                            groundFee > 0 ? '₹$groundFee' : '—',
                          ),
                          _payRow('Discount', '-₹0'),
                          const SizedBox(height: 8),
                          Container(height: 1, color: const Color(0x33FFFFFF)),
                          const SizedBox(height: 8),
                          _payRow('Total Amount', '₹$total', strong: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Apply Offer Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x1FFFFFFF),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Enter offer code',
                              style: TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(84, 48),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          _submitBookingRequest(total);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0x662563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Request Booking',
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

  Widget _slotRow(String date, String time, String price) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x0AF4F7FF),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.calendar_month_outlined,
            color: Color(0xFF2563EB),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _payRow(String left, String right, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            left,
            style: TextStyle(
              color: strong ? Colors.white : const Color(0x99FFFFFF),
              fontSize: strong ? 16 : 14,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              color: strong ? const Color(0xFF2563EB) : Colors.white,
              fontSize: strong ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const _RoundIcon(icon: Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          const _RoundIcon(icon: Icons.shopping_cart_outlined),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0x26FFFFFF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
