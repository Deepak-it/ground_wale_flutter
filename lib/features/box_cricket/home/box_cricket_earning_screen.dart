import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class BoxCricketEarningScreen extends StatefulWidget {
  const BoxCricketEarningScreen({super.key});

  @override
  State<BoxCricketEarningScreen> createState() =>
      _BoxCricketEarningScreenState();
}

class _BoxCricketEarningScreenState extends State<BoxCricketEarningScreen> {
  bool _isLoading = true;
  int _walletTabIndex = 0;
  Map<String, dynamic> _wallet = <String, dynamic>{};
  List<Map<String, dynamic>> _transactions = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _resolveGroundId() async {
    final String? currentGroundId = ApiSession.instance.groundId;
    if (currentGroundId != null && currentGroundId.isNotEmpty) {
      return currentGroundId;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final String? resolved = await GroundWaleApi.instance
        .ensureGroundIdForOwner(ownerId);
    if (resolved != null && resolved.isNotEmpty) {
      ApiSession.instance.setGroundId(resolved);
    }
    return resolved;
  }

  Future<void> _load() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No grounds found for this owner.')),
        );
      }
      return;
    }

    try {
      final Map<String, dynamic> wallet = await GroundWaleApi.instance
          .getWallet(groundId);
      final List<Map<String, dynamic>> transactions = await GroundWaleApi
          .instance
          .getTransactions(groundId);
      if (!mounted) {
        return;
      }
      setState(() {
        _wallet = wallet;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  List<Map<String, dynamic>> _filteredTransactions() {
    if (_transactions.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    switch (_walletTabIndex) {
      case 1:
        return _transactions
            .where((Map<String, dynamic> item) => item['type'] == 'credit')
            .toList();
      case 2:
        return _transactions
            .where((Map<String, dynamic> item) => item['type'] == 'withdrawal')
            .toList();
      default:
        return _transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalBalance = _toInt(_wallet['balance']);
    final int pendingBalance = _toInt(_wallet['pendingBalance']);
    final int availableBalance = (totalBalance - pendingBalance).clamp(
      0,
      999999999,
    );

    final List<Map<String, dynamic>> items = _filteredTransactions();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).maybePop();
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Rs $totalBalance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _walletValue(
                                'Available',
                                'Rs $availableBalance',
                              ),
                            ),
                            Expanded(
                              child: _walletValue(
                                'Pending',
                                'Rs $pendingBalance',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0x1AFFFFFF),
                          ),
                          child: const Text(
                            'Pending will be settled in 24 hrs',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardBorder(),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.account_balance_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Bank Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'HDFC Bank .....2048 Linked',
                                style: TextStyle(
                                  color: Color(0x99FFFFFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Edit',
                          style: TextStyle(
                            color: Color(0xFFDDF730),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF08B36A),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Add Bank Account',
                        style: TextStyle(
                          color: Color(0xFF08B36A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Earning Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(child: _summaryCard('Today', 'Rs 12,500')),
                      const SizedBox(width: 12),
                      Expanded(child: _summaryCard('This Week', 'Rs 48,000')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard('This Month', 'Rs 1,80,000'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(child: _walletTab('All', 0)),
                      const SizedBox(width: 12),
                      Expanded(child: _walletTab('Credit', 1)),
                      const SizedBox(width: 12),
                      Expanded(child: _walletTab('Withdrawals', 2)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0x08FFFFFF),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: const Text(
                        'No transactions found.',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...items.map((Map<String, dynamic> item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _transactionCard(item),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08B36A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text(
                        'Withdraw Money',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _walletValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletTab(String label, int index) {
    final bool selected = _walletTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _walletTabIndex = index);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: selected ? const Color(0x14FFFFFF) : const Color(0x0AFFFFFF),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0x99FFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _transactionCard(Map<String, dynamic> item) {
    final bool isCredit =
        (item['type']?.toString() ?? '').toLowerCase() == 'credit';
    final int amount = _toInt(item['amount']);
    final String amountText = isCredit ? '+$amount' : '-Rs $amount';
    final String status = item['status']?.toString() ?? 'success';
    final String title = item['title']?.toString() ?? 'Transaction';
    final String subtitle = item['subtitle']?.toString() ?? '';
    final String dateText = item['dateText']?.toString() ?? '12 Oct';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x08FFFFFF),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x33000000), blurRadius: 4),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  amountText,
                  style: TextStyle(
                    color: isCredit
                        ? const Color(0xFF08B36A)
                        : const Color(0xFFE3220D),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0x2608B36A),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: const TextStyle(
                    color: Color(0xFF08B36A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                dateText,
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardBorder() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x1FFFFFFF)),
      color: const Color(0x08FFFFFF),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x0F000000), blurRadius: 12),
      ],
    );
  }
}
