import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_booking_flow_models.dart';
import 'box_cricket_dashboard_screen.dart';

class BoxCricketPaymentScreen extends StatefulWidget {
  const BoxCricketPaymentScreen({super.key, required this.draft});

  final BoxCricketBookingDraft draft;

  @override
  State<BoxCricketPaymentScreen> createState() => _BoxCricketPaymentScreenState();
}

class _BoxCricketPaymentScreenState extends State<BoxCricketPaymentScreen> {
  bool _submitting = false;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.draft.paymentMethod;
  }

  Future<void> _confirmBooking() async {
    final String? groundId = ApiSession.instance.groundId;
    if (groundId == null || groundId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ground id is missing.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final BoxCricketBookingDraft ready = widget.draft.copyWith(
        paymentMethod: _paymentMethod,
      );
      final Map<String, dynamic> booking = await GroundWaleApi.instance
          .createBooking(groundId, ready.toPayload());
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BoxCricketPaymentSuccessScreen(booking: booking),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1F1B),
        elevation: 0,
        title: const Text('Continue'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Booking Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _row('Team', widget.draft.teamName),
                _row('Captain', widget.draft.captainName),
                _row('Time', '${widget.draft.startTime} - ${widget.draft.endTime}'),
                _row('Date', widget.draft.date),
                _row('Players', '${widget.draft.playerCount}'),
                const Divider(color: Color(0x33FFFFFF), height: 22),
                _row(
                  'Total Amount',
                  'Rs ${widget.draft.amount}',
                  valueColor: const Color(0xFF08B36A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <String>['upi', 'cod', 'cash', 'netbanking'].map((String method) {
                    final bool selected = _paymentMethod == method;
                    return GestureDetector(
                      onTap: () => setState(() => _paymentMethod = method),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: selected
                              ? const Color(0xFF08B36A)
                              : const Color(0x0DFFFFFF),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                        ),
                        child: Text(
                          method.toUpperCase(),
                          style: TextStyle(
                            color: selected ? const Color(0xFF1C333B) : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08B36A),
                foregroundColor: const Color(0xFF1C333B),
              ),
              child: Text(_submitting ? 'Processing...' : 'Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Color(0xCCFFFFFF))),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0x0AFFFFFF),
      border: Border.all(color: const Color(0x1FFFFFFF)),
    );
  }
}

class BoxCricketPaymentSuccessScreen extends StatelessWidget {
  const BoxCricketPaymentSuccessScreen({super.key, required this.booking});

  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0x0AFFFFFF),
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF08B36A),
                    size: 78,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Confirmed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking ${booking['bookingCode'] ?? ''} is confirmed.',
                    style: const TextStyle(color: Color(0xCCFFFFFF)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${booking['startTime'] ?? '--'} - ${booking['endTime'] ?? '--'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${(booking['amount'] as num?)?.round() ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFF08B36A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const BoxCricketDashboardScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08B36A),
                        foregroundColor: const Color(0xFF1C333B),
                      ),
                      child: const Text('Back To Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
