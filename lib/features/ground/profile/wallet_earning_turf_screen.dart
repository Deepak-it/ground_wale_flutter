import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'earning_report_turf_screen.dart';
import 'profile_turf_ui.dart';
import 'view_details_turf_screen.dart';

class WalletEarningTurfScreen extends StatelessWidget {
  const WalletEarningTurfScreen({super.key});

  Future<Map<String, dynamic>> _loadWallet() async {
    final ApiSession session = ApiSession.instance;
    if (!session.hasGround && session.isAuthenticated) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    if (!session.hasGround) {
      return <String, dynamic>{'transactions': <Map<String, dynamic>>[]};
    }
    return GroundWaleApi.instance.getWallet(session.groundId!);
  }

  @override
  Widget build(BuildContext context) {
    Widget summaryTile(String label, String value) {
      return Expanded(
        child: TurfCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    Widget txnCard(Map<String, dynamic> tx) {
      final double amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      final bool credit = amount >= 0;
      final Color amountColor = credit ? const Color(0xFF08B36A) : const Color(0xFFE3220D);
      return TurfCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${credit ? '+' : '-'}₹${amount.abs().toStringAsFixed(0)}', style: TextStyle(color: amountColor, fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(tx['title']?.toString() ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(tx['subtitle']?.toString() ?? '', style: const TextStyle(color: Colors.white60, fontSize: 15)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x2608B36A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text((tx['status']?.toString() ?? 'success').toUpperCase(), style: const TextStyle(color: Color(0xFF08B36A), fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Text(tx['occurredAt']?.toString().split('T').first ?? '', style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Wallet',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadWallet(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }
          final Map<String, dynamic> wallet = snapshot.data ?? <String, dynamic>{'transactions': <dynamic>[]};
          final List<Map<String, dynamic>> transactions = (wallet['transactions'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic item) => Map<String, dynamic>.from(item as Map))
              .toList();
          return ListView(
            children: <Widget>[
              TurfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Total Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text('₹${wallet['totalBalance'] ?? 0}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Available', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('₹${wallet['availableBalance'] ?? 0}', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Pending', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('₹${wallet['pendingBalance'] ?? 0}', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Pending will be settled in 24 hrs', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
              TurfCard(
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.account_balance_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Bank Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('See linked payouts and transaction details', style: TextStyle(color: Colors.white60)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ViewDetailsTurfScreen())),
                      child: const Text('View', style: TextStyle(color: Color(0xFF08B36A))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('Earning Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  summaryTile('Total', '₹${wallet['totalBalance'] ?? 0}'),
                  const SizedBox(width: 8),
                  summaryTile('Available', '₹${wallet['availableBalance'] ?? 0}'),
                  const SizedBox(width: 8),
                  summaryTile('Pending', '₹${wallet['pendingBalance'] ?? 0}'),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...transactions.take(4).map(txnCard),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDF730),
                    foregroundColor: const Color(0xFF242424),
                  ),
                  onPressed: () async {
                    final ApiSession session = ApiSession.instance;
                    if (session.hasGround) {
                      await GroundWaleApi.instance.withdraw(session.groundId!, 1000);
                    }
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningReportTurfScreen()));
                    }
                  },
                  child: const Text('Withdraw Money'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
