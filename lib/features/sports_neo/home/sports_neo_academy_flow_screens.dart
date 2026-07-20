import 'package:flutter/material.dart';

import 'sports_neo_payment_screen.dart';

class SportsNeoAcademyDetailScreen extends StatelessWidget {
  const SportsNeoAcademyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _academyHeader(context, 'Academy Detail'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: <Widget>[
                    _academyHero(),
                    const SizedBox(height: 24),
                    _academyCard(
                      title: 'Membership Overview',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF2563EB),
                        ),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: const <Widget>[
                              Expanded(child: _AcademyInfoItem('SPORT TYPE', 'Cricket')),
                              SizedBox(width: 18),
                              Expanded(child: _AcademyInfoItem('COACH', 'Rahul S.')),
                              SizedBox(width: 18),
                              Expanded(child: _AcademyInfoItem('JOINED on', '12 Mar 2025', alignEnd: true)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: const <Widget>[
                              Expanded(child: _AcademyInfoItem('BATCH', 'Morning 6-7 AM')),
                              SizedBox(width: 18),
                              Expanded(child: _AcademyInfoItem('HOME GROUND', 'Green Valley')),
                              SizedBox(width: 18),
                              Expanded(child: _AcademyInfoItem('BATCH SIZE', '20 Players', alignEnd: true)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _academyCard(
                      title: 'Fees & Payments',
                      trailing: const Icon(Icons.credit_card_outlined, color: Color(0xFF2563EB), size: 24),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: const <Widget>[
                              Expanded(child: _AcademyMetricCard('Total Paid', '3000', Color(0x1408B36A))),
                              SizedBox(width: 12),
                              Expanded(child: _AcademyMetricCard('Pending', '₹2000', Color(0x14EB8B34), valueColor: Color(0xFFFFFFFF))),
                              SizedBox(width: 12),
                              Expanded(child: _AcademyMetricCard('Total Paid', '₹5000', Color(0x14E3220D))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const SportsNeoPaymentScreen(amount: 2000),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const SportsNeoAcademyPaymentHistoryScreen(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0x14FFFFFF),
                                    ),
                                    child: const Text('View History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _academyCard(
                      title: 'Schedule',
                      trailing: const Text('Weekly View', style: TextStyle(color: Color(0xFF4F81F0), fontSize: 14, fontWeight: FontWeight.w500)),
                      child: Column(
                        children: const <Widget>[
                          _AcademyScheduleRow('Today', '6:00 - 7:00 AM', 'Completed', Color(0x1408B36A), Color(0xFF08B36A)),
                          Divider(color: Color(0x33FFFFFF)),
                          _AcademyScheduleRow('Tomorrow', '6:00 - 7:00 AM', 'Upcoming', Color(0x14F59E0B), Color(0xFFF59E0B)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _academyCard(
                      title: 'Coach & Support',
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const CircleAvatar(radius: 27, backgroundColor: Color(0xFF2563EB), child: Text('R', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const <Widget>[
                                  Text('Coach Rahul', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text('Experience: 8 years', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
                                  Text('Specialty: Batting', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(child: _ghostButton('Chat')),
                              const SizedBox(width: 12),
                              Expanded(child: _ghostButton('Call')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _academyCard(
                      title: 'Recent Attendance',
                      trailing: const Text('View All', style: TextStyle(color: Color(0xFF4F81F0), fontSize: 14, fontWeight: FontWeight.w500)),
                      child: Column(
                        children: const <Widget>[
                          _AttendanceRow('Apr 18', 'Present', Color(0x1408B36A), Color(0xFF08B36A)),
                          Divider(color: Color(0x33FFFFFF)),
                          _AttendanceRow('Apr 17', 'Absent', Color(0x14E3220D), Color(0xFFE3220D)),
                          Divider(color: Color(0x33FFFFFF)),
                          _AttendanceRow('Apr 16', 'Present', Color(0x1408B36A), Color(0xFF08B36A)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ghostOutlinedButton('Pause Membership', const Color(0xFF2563EB), onTap: () {}),
                    const SizedBox(height: 12),
                    _dangerButton(
                      'Leave Academy',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SportsNeoAcademyLeaveSuccessScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SportsNeoAcademyPaymentHistoryScreen extends StatelessWidget {
  const SportsNeoAcademyPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _academyHeader(context, 'Payment History'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: <Widget>[
                    _academyCard(
                      title: 'Fee Summary',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0x142563EB)),
                        child: const Text('April 2025', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: const <Widget>[
                              Expanded(child: _AcademyMetricCard('Total Paid', '3000', Color(0x1408B36A))),
                              SizedBox(width: 12),
                              Expanded(child: _AcademyMetricCard('Pending', '₹2000', Color(0x14EB8B34))),
                              SizedBox(width: 12),
                              Expanded(child: _AcademyMetricCard('Total Paid', '₹5000', Color(0x14E3220D))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _filterStrip(const <String>['This month', 'Last month', 'All Time'], 0),
                    const SizedBox(height: 12),
                    _filterStrip(const <String>['All Status', 'Paid', 'Pending', 'Failed'], 0),
                    const SizedBox(height: 16),
                    _academyCard(
                      title: 'Transactions',
                      trailing: const Text('4 entries', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14, fontWeight: FontWeight.w500)),
                      child: Column(
                        children: <Widget>[
                          _transactionItem(
                            iconBg: const Color(0x1408B36A),
                            icon: Icons.check_circle_outline,
                            iconColor: const Color(0xFF08B36A),
                            title: 'Monthly Academy Fee',
                            amount: '₹1000',
                            timestamp: '10 April 2025 - 10:30 AM',
                            status: 'Paid',
                            statusBg: const Color(0x1408B36A),
                            statusColor: const Color(0xFF08B36A),
                            method: 'UPI',
                            txnId: 'TXN12345ABCFEE',
                            actionText: 'Download Receipt',
                            primaryAction: false,
                          ),
                          const SizedBox(height: 16),
                          _transactionItem(
                            iconBg: const Color(0x14F59E0B),
                            icon: Icons.schedule,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Tournament Entry Fee',
                            amount: '₹1000',
                            timestamp: '14 April 2025 - 8:15 PM',
                            status: 'Pending',
                            statusBg: const Color(0x14F59E0B),
                            statusColor: const Color(0xFFF59E0B),
                            method: 'Card',
                            txnId: 'TXN12345ABCFEE',
                            actionText: 'Pay Pending Amount',
                            primaryAction: true,
                          ),
                          const SizedBox(height: 16),
                          _transactionItem(
                            iconBg: const Color(0x14E3220D),
                            icon: Icons.cancel_outlined,
                            iconColor: const Color(0xFFE3220D),
                            title: 'Coacing Renewal',
                            amount: '₹1000',
                            timestamp: '03 April 2025 - 7:45 AM',
                            status: 'Failed',
                            statusBg: const Color(0x14F59E0B),
                            statusColor: const Color(0xFFF59E0B),
                            method: 'Card',
                            txnId: 'TXN12345ABCFEE',
                            actionText: 'Retry Payment',
                            primaryAction: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SportsNeoAcademyLeaveSuccessScreen extends StatelessWidget {
  const SportsNeoAcademyLeaveSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101E),
      body: Center(
        child: Container(
          width: 358,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0x14FFFFFF),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.check_circle, color: Color(0xFF08B36A), size: 74),
              const SizedBox(height: 26),
              const Text(
                'You have left\nthe academy\nsuccessfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your membership for ABC cricket Academy has been cancelled. We’re sorry to see you go!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 173,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _academyHeader(BuildContext context, String title) {
  return Container(
    height: 128,
    width: double.infinity,
    decoration: const BoxDecoration(
      color: Color(0xFF121C3E),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
    child: Row(
      children: <Widget>[
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(22),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

Widget _academyHero() {
  return Container(
    width: double.infinity,
    height: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFF1A234A), Color(0xFF09082F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0x33044AE5),
              border: Border.all(color: const Color(0x33044AE5)),
            ),
            child: const Text('ELITE ACADEMY', style: TextStyle(color: Color(0xFF829BFF), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          const Text('ABC\nCricket', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 0.95)),
          const SizedBox(height: 8),
          const Text('Mohali, Punjab', style: TextStyle(color: Color(0xCCDBD9FF), fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

Widget _academyCard({required String title, required Widget child, Widget? trailing}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0x0AFFFFFF),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            if (trailing case final Widget trailingWidget) trailingWidget,
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _AcademyInfoItem extends StatelessWidget {
  const _AcademyInfoItem(this.label, this.value, {this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, textAlign: alignEnd ? TextAlign.end : TextAlign.start, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _AcademyMetricCard extends StatelessWidget {
  const _AcademyMetricCard(this.label, this.value, this.bg, {this.valueColor = Colors.white});

  final String label;
  final String value;
  final Color bg;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: bg, border: Border.all(color: bg)),
      child: Column(
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AcademyScheduleRow extends StatelessWidget {
  const _AcademyScheduleRow(this.day, this.time, this.status, this.bg, this.fg);

  final String day;
  final String time;
  final String status;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(day, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(time, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: bg),
          child: Text(status, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

Widget _ghostButton(String label) {
  return Container(
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0x14FFFFFF)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  );
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow(this.day, this.status, this.bg, this.fg);

  final String day;
  final String status;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(day, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: bg),
          child: Text(status, style: TextStyle(color: fg, fontSize: 14)),
        ),
      ],
    );
  }
}

Widget _ghostOutlinedButton(String label, Color color, {required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

Widget _dangerButton(String label, {required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0x14E3220D)),
      child: Text(label, style: const TextStyle(color: Color(0xFFE3220D), fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

Widget _filterStrip(List<String> labels, int activeIndex) {
  return SizedBox(
    height: 37,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, int index) {
        final bool active = index == activeIndex;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
          ),
          child: Text(labels[index], style: const TextStyle(color: Colors.white, fontSize: 14)),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemCount: labels.length,
    ),
  );
}

Widget _transactionItem({
  required Color iconBg,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String amount,
  required String timestamp,
  required String status,
  required Color statusBg,
  required Color statusColor,
  required String method,
  required String txnId,
  required String actionText,
  required bool primaryAction,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0x0AFFFFFF)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: iconBg),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                      Text(amount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(timestamp, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Text('Status', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: statusBg),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Text('Method', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
              const SizedBox(height: 8),
              Text(method, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(width: 24),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                const Text('Transaction ID', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
                const SizedBox(height: 8),
                Text(txnId, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: primaryAction ? const Color(0xFF2563EB) : const Color(0x14FFFFFF),
          ),
          child: Text(actionText, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}