import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_bank_account_screen.dart';

class BoxCricketEarningScreen extends StatefulWidget {
  const BoxCricketEarningScreen({super.key});

  @override
  State<BoxCricketEarningScreen> createState() =>
      _BoxCricketEarningScreenState();
}

class _BoxCricketEarningScreenState extends State<BoxCricketEarningScreen> {
  bool _isLoading = true;
  bool _isWithdrawing = false;
  int _walletTabIndex = 0;
  String? _groundId;
  Map<String, dynamic> _wallet = <String, dynamic>{};
  Map<String, dynamic> _bankAccount = <String, dynamic>{};
  List<Map<String, dynamic>> _transactions = <Map<String, dynamic>>[];
  int _earningsToday = 0;
  int _earningsWeek = 0;
  int _earningsMonth = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

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

    final String? ownerId = ApiSession.instance.ownerId;

    final DateTime now = DateTime.now();
    final String todayStr = _formatDate(now);
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final String weekStartStr = _formatDate(startOfWeek);
    final String monthStartStr =
        _formatDate(DateTime(now.year, now.month, 1));
    final String monthEndStr =
        _formatDate(DateTime(now.year, now.month + 1, 0));

    try {
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        GroundWaleApi.instance.getWallet(groundId),
        GroundWaleApi.instance.getTransactions(groundId),
        if (ownerId != null && ownerId.isNotEmpty)
          GroundWaleApi.instance.getBankAccount(ownerId)
        else
          Future<Map<String, dynamic>>.value(<String, dynamic>{}),
        GroundWaleApi.instance.getEarningsReport(
          groundId,
          from: todayStr,
          to: todayStr,
        ),
        GroundWaleApi.instance.getEarningsReport(
          groundId,
          from: weekStartStr,
          to: todayStr,
        ),
        GroundWaleApi.instance.getEarningsReport(
          groundId,
          from: monthStartStr,
          to: monthEndStr,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final Map<String, dynamic> bankResp =
          results[2] as Map<String, dynamic>;
      final Map<String, dynamic> bank = Map<String, dynamic>.from(
        bankResp['bankAccount'] as Map? ?? bankResp,
      );

      final Map<String, dynamic> todayReport =
          results[3] as Map<String, dynamic>;
      final Map<String, dynamic> weekReport =
          results[4] as Map<String, dynamic>;
      final Map<String, dynamic> monthReport =
          results[5] as Map<String, dynamic>;

      setState(() {
        _groundId = groundId;
        _wallet = results[0] as Map<String, dynamic>;
        _transactions = (results[1] as List<dynamic>)
            .map((dynamic item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _bankAccount = bank;
        _earningsToday = _toInt(todayReport['grossRevenue']);
        _earningsWeek = _toInt(weekReport['grossRevenue']);
        _earningsMonth = _toInt(monthReport['grossRevenue']);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onWithdraw(int availableBalance) async {
    if (availableBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available balance to withdraw.')),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Confirm Withdrawal',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Withdraw Rs $availableBalance to your linked bank account?',
          style: const TextStyle(color: Color(0xCCFFFFFF)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0x99FFFFFF)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Withdraw',
              style: TextStyle(color: Color(0xFF08B36A)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final String? groundId = _groundId ?? ApiSession.instance.groundId;
    if (groundId == null || groundId.isEmpty) {
      return;
    }

    setState(() => _isWithdrawing = true);
    try {
      await GroundWaleApi.instance.withdraw(
        groundId,
        availableBalance.toDouble(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted successfully.'),
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isWithdrawing = false);
      }
    }
  }

  Future<void> _openBankAccount() async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const BoxCricketBankAccountScreen(),
      ),
    );
    if (updated == true && mounted) {
      await _load();
    }
  }

  bool get _hasBankAccount {
    final String account =
        _bankAccount['accountNumber']?.toString() ?? '';
    return account.isNotEmpty;
  }

  String _maskedAccount(String accountNumber) {
    if (accountNumber.isEmpty) {
      return 'Linked';
    }
    if (accountNumber.length <= 4) {
      return accountNumber;
    }
    final String bankName = _bankAccount['bankName']?.toString() ?? '';
    final String suffix = accountNumber.substring(accountNumber.length - 4);
    return bankName.isNotEmpty
        ? '$bankName .....${suffix} Linked'
        : '.....${suffix} Linked';
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
    final int totalBalance = _toInt(_wallet['totalBalance']);
    final int pendingBalance = _toInt(_wallet['pendingBalance']);
    final int availableBalance = _toInt(_wallet['availableBalance']);

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
                  if (_hasBankAccount)
                    GestureDetector(
                      onTap: _openBankAccount,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardBorder(),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.account_balance_outlined,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _bankAccount['bankName']?.toString().isNotEmpty == true
                                        ? _bankAccount['bankName'].toString()
                                        : 'Bank Account',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _maskedAccount(
                                      _bankAccount['accountNumber']?.toString() ?? '',
                                    ),
                                    style: const TextStyle(
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
                    ),
                  if (_hasBankAccount) const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _openBankAccount,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF08B36A),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _hasBankAccount ? 'Manage Bank Account' : 'Add Bank Account',
                          style: const TextStyle(
                            color: Color(0xFF08B36A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                      Expanded(
                        child: _summaryCard('Today', 'Rs $_earningsToday'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard('This Week', 'Rs $_earningsWeek'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard('This Month', 'Rs $_earningsMonth'),
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
                      onPressed: _isWithdrawing
                          ? null
                          : () => _onWithdraw(availableBalance),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08B36A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF08B36A).withValues(alpha: 0.5),
                        elevation: 0,
                      ),
                      child: _isWithdrawing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
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
    final String amountText = isCredit ? '+Rs $amount' : '-Rs $amount';
    final String status = item['status']?.toString() ?? 'success';
    final String title = item['title']?.toString() ?? 'Transaction';
    final String subtitle = item['subtitle']?.toString() ?? '';

    // Parse occurredAt / createdAt for the date label
    final String rawDate =
        item['occurredAt']?.toString() ??
        item['createdAt']?.toString() ??
        '';
    String dateText = '';
    if (rawDate.isNotEmpty) {
      final DateTime? dt = DateTime.tryParse(rawDate);
      if (dt != null) {
        final DateTime local = dt.toLocal();
        const List<String> months = <String>[
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        dateText = '${local.day} ${months[local.month - 1]} ${local.year}';
      }
    }

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
                  color: status == 'failed'
                      ? const Color(0x26E3220D)
                      : status == 'pending'
                          ? const Color(0x26F59E0B)
                          : const Color(0x2608B36A),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: status == 'failed'
                        ? const Color(0xFFE3220D)
                        : status == 'pending'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF08B36A),
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
