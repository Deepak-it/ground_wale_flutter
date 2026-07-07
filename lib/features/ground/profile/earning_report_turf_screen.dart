import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class EarningReportTurfScreen extends StatelessWidget {
  const EarningReportTurfScreen({super.key});

  Future<Map<String, dynamic>> _loadReport() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround && session.isAuthenticated) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    if (!session.hasGround) {
      return <String, dynamic>{};
    }
    return GroundWaleApi.instance.getEarningsReport(session.groundId!);
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) {
      return TurfCard(
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
            Text(value, style: const TextStyle(color: Color(0xFF08B36A), fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Tap on Earning Report',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadReport(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          final Map<String, dynamic> report = snapshot.data ?? <String, dynamic>{};
          return ListView(
            children: <Widget>[
              row('Gross Revenue', '₹${report['grossRevenue'] ?? 0}'),
              row('Settled Credits', '₹${report['settledCredits'] ?? 0}'),
              row('Withdrawals', '₹${report['withdrawals'] ?? 0}'),
              row('Bookings', '${(report['bookings'] as List<dynamic>? ?? <dynamic>[]).length}'),
            ],
          );
        },
      ),
    );
  }
}
