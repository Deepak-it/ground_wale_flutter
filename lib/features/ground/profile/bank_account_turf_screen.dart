import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'edit_bank_turf_screen.dart';
import 'profile_turf_ui.dart';

class BankAccountTurfScreen extends StatelessWidget {
  const BankAccountTurfScreen({super.key});

  Future<Map<String, dynamic>> _loadBank() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      return <String, dynamic>{};
    }
    return GroundWaleApi.instance.getBankAccount(session.ownerId!);
  }

  @override
  Widget build(BuildContext context) {
    Widget readonlyField(String label, String value, {String? hint}) {
      return TurfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x30FFFFFF)),
                color: const Color(0x10FFFFFF),
              ),
              child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            if (hint != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(hint, style: const TextStyle(color: Colors.white60, fontSize: 14)),
            ],
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Wallet',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadBank(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }

          final Map<String, dynamic> response = snapshot.data ?? <String, dynamic>{};
          final Map<String, dynamic> bank = Map<String, dynamic>.from(response['bankAccount'] as Map? ?? <String, dynamic>{});
          final String accountNumber = bank['accountNumber']?.toString() ?? '';
          final String maskedAccount = accountNumber.length > 4 ? '............................${accountNumber.substring(accountNumber.length - 4)}' : accountNumber;

          return ListView(
            children: <Widget>[
              TurfCard(
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.account_balance_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Bank Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text('${bank['bankName'] ?? 'No bank linked'}', style: const TextStyle(color: Colors.white60)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditBankTurfScreen())),
                      child: const Text('Edit', style: TextStyle(color: Color(0xFF08B36A))),
                    ),
                  ],
                ),
              ),
              readonlyField('Account Number', maskedAccount),
              readonlyField('IFSC Code', bank['ifscCode']?.toString() ?? ''),
              readonlyField('Account Holder Name', bank['accountHolderName']?.toString() ?? ''),
              readonlyField('Branch', bank['branch']?.toString() ?? ''),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDF730),
                    foregroundColor: const Color(0xFF242424),
                  ),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditBankTurfScreen())),
                  child: const Text('Tap on Edit Bank Text Button'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
