import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class ViewDetailsTurfScreen extends StatelessWidget {
  const ViewDetailsTurfScreen({super.key});

  Future<List<Map<String, dynamic>>> _loadTransactions() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround && session.isAuthenticated) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    if (!session.hasGround) {
      return <Map<String, dynamic>>[];
    }
    return GroundWaleApi.instance.getTransactions(session.groundId!);
  }

  @override
  Widget build(BuildContext context) {
    Widget tx(Map<String, dynamic> item) {
      final double amount = (item['amount'] as num?)?.toDouble() ?? 0;
      return TurfCard(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(item['occurredAt']?.toString().split('T').first ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Text('${amount >= 0 ? '+' : '-'}₹${amount.abs().toStringAsFixed(0)}', style: TextStyle(color: amount >= 0 ? const Color(0xFF08B36A) : const Color(0xFFE3220D), fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Tap on View Details',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadTransactions(),
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }
          final List<Map<String, dynamic>> items = snapshot.data ?? <Map<String, dynamic>>[];
          return ListView(children: items.map(tx).toList());
        },
      ),
    );
  }
}
