import 'package:flutter/material.dart';

import 'sports_neo_payment_screen.dart';

class SportsNeoBookingSummaryScreen extends StatefulWidget {
  const SportsNeoBookingSummaryScreen({
    super.key,
    required this.groundName,
    required this.location,
  });

  final String groundName;
  final String location;

  @override
  State<SportsNeoBookingSummaryScreen> createState() =>
      _SportsNeoBookingSummaryScreenState();
}

class _SportsNeoBookingSummaryScreenState
    extends State<SportsNeoBookingSummaryScreen> {
  int _balls = 1;
  int _umpires = 0;

  @override
  Widget build(BuildContext context) {
    final int groundFee = 5000;
    final int ballCost = _balls * 150;
    final int total = groundFee + ballCost;

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
                          _slotRow('Wed, Apr 8', '6:00 AM - 8:00 AM', '₹2500'),
                          const SizedBox(height: 10),
                          _slotRow(
                            'Wed, Apr 8',
                            '10:00 AM - 12:00 AM',
                            '₹2500',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'Paid add-ons',
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _AddonItem(
                                  title: 'Balls',
                                  count: _balls,
                                  active: true,
                                  onMinus: () {
                                    if (_balls > 0) {
                                      setState(() => _balls -= 1);
                                    }
                                  },
                                  onPlus: () => setState(() => _balls += 1),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AddonItem(
                                  title: 'Umpires',
                                  count: _umpires,
                                  active: false,
                                  onMinus: () {
                                    if (_umpires > 0) {
                                      setState(() => _umpires -= 1);
                                    }
                                  },
                                  onPlus: () => setState(() => _umpires += 1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'Payment Summary',
                      child: Column(
                        children: <Widget>[
                          _payRow('Ground Fee', '₹$groundFee'),
                          _payRow('Red ball ($_balls)', '₹$ballCost'),
                          _payRow('Discount', '-₹0'),
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color: const Color(0x33FFFFFF),
                          ),
                          const SizedBox(height: 8),
                          _payRow(
                            'Total Amount',
                            '₹$total',
                            strong: true,
                          ),
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
                              border: Border.all(color: const Color(0x1FFFFFFF)),
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SportsNeoPaymentScreen(amount: total),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Proceed to Pay',
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

class _AddonItem extends StatelessWidget {
  const _AddonItem({
    required this.title,
    required this.count,
    required this.active,
    required this.onMinus,
    required this.onPlus,
  });

  final String title;
  final int count;
  final bool active;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
        ),
        color: active ? null : const Color(0x99FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: active ? 1 : 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0x0AF4F7FF),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                InkWell(
                  onTap: onMinus,
                  child: const Icon(Icons.remove, color: Colors.white, size: 22),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: onPlus,
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
