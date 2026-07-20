import 'package:flutter/material.dart';

import 'sports_neo_ledger_repository.dart';

enum SportsNeoLedgerMode { home, pending, advance, sarpanch }

class SportsNeoLedgerPaymentsScreen extends StatefulWidget {
  const SportsNeoLedgerPaymentsScreen({
    super.key,
    this.mode = SportsNeoLedgerMode.home,
  });

  final SportsNeoLedgerMode mode;

  @override
  State<SportsNeoLedgerPaymentsScreen> createState() =>
      _SportsNeoLedgerPaymentsScreenState();
}

class _SportsNeoLedgerPaymentsScreenState
    extends State<SportsNeoLedgerPaymentsScreen> {
  final SportsNeoLedgerRepository _repo = SportsNeoLedgerRepository.create();

  bool _loading = true;
  String? _groundId;
  SportsNeoLedgerHomeData? _home;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? groundId = await resolveGroundIdForLedger();
    if (groundId == null || groundId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ground not found for ledger flow.')),
      );
      return;
    }

    try {
      late SportsNeoLedgerHomeData data;
      switch (widget.mode) {
        case SportsNeoLedgerMode.pending:
          data = await _repo.loadPendingLedger(groundId);
        case SportsNeoLedgerMode.advance:
          data = await _repo.loadAdvanceLedger(groundId);
        case SportsNeoLedgerMode.sarpanch:
          final SportsNeoMatchLedgerData sarpanch =
              await _repo.loadSarpanchLedger(groundId);
          data = SportsNeoLedgerHomeData(
            title: sarpanch.matchTitle,
            netBalance: sarpanch.netBalance,
            netPositive: sarpanch.netPositive,
            addReceiptLabel: 'Add Money',
            addPaymentLabel: 'Add Dues',
            entries: sarpanch.transactions,
            balanceLabel: 'Net Balance',
            statChips: sarpanch.paymentLines,
            sectionTitle: sarpanch.bookingTitle,
            showShareInSection: true,
          );
        case SportsNeoLedgerMode.home:
          data = await _repo.loadLedgerHome(groundId);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _groundId = groundId;
        _home = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  bool get _showBellIcon {
    return widget.mode == SportsNeoLedgerMode.pending;
  }

  String get _footerButton {
    switch (widget.mode) {
      case SportsNeoLedgerMode.pending:
        return 'Send Payment Reminder';
      case SportsNeoLedgerMode.advance:
        return 'Send Payment Update';
      case SportsNeoLedgerMode.sarpanch:
        return 'View all Payment history';
      case SportsNeoLedgerMode.home:
        return '';
    }
  }

  Color get _footerColor {
    if (widget.mode == SportsNeoLedgerMode.pending) {
      return const Color(0xFFF59E0B);
    }
    if (widget.mode == SportsNeoLedgerMode.advance) {
      return const Color(0xFF2563EB);
    }
    return const Color(0xFF0A0F1E);
  }

  Future<void> _openAddMoney(String kind) async {
    if (_groundId == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SportsNeoAddMoneyScreen(
          title: kind == 'receipt' ? 'Add Receipt' : 'Add Payment',
          kind: kind,
          repository: _repo,
          groundId: _groundId!,
        ),
      ),
    );
  }

  Future<void> _openMatch() async {
    if (_groundId == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SportsNeoMatchLedgerScreen(
          repository: _repo,
          groundId: _groundId!,
          matchId: 'match-1',
        ),
      ),
    );
  }

  Future<void> _onFooterTap() async {
    if (_groundId == null) {
      return;
    }
    if (widget.mode == SportsNeoLedgerMode.pending) {
      _showNotifySheet(
        title: 'Send Payment Reminder',
        subtitle: 'A pending payment message will be shared with all players.',
        messagePreview: 'Please clear your pending payment for next matches',
        onSend: () => _repo.sendPendingReminder(_groundId!),
      );
      return;
    }
    if (widget.mode == SportsNeoLedgerMode.advance) {
      _showNotifySheet(
        title: 'Send Payment Update',
        subtitle: 'A payment update will be shared with all players.',
        messagePreview:
            'Your advance payment has been successfully received for the upcoming match.',
        onSend: () => _repo.sendAdvanceUpdate(_groundId!),
      );
      return;
    }
  }

  void _showNotifySheet({
    required String title,
    required String subtitle,
    required String messagePreview,
    required Future<void> Function() onSend,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              colors: <Color>[Color(0xFF112A46), Color(0xFF0E2238)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                  color: const Color(0x08FFFFFF),
                ),
                child: Text(
                  messagePreview,
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final NavigatorState navigator = Navigator.of(context);
                    await onSend();
                    if (!mounted) {
                      return;
                    }
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Shared on WhatsApp')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08B36A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Send via WhatsApp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onEntryTap(SportsNeoLedgerEntry entry) {
    if (widget.mode == SportsNeoLedgerMode.home && entry.index == 1) {
      _openMatch();
      return;
    }
    if (entry.title.toLowerCase().contains('sarpanch')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SportsNeoLedgerPaymentsScreen(mode: SportsNeoLedgerMode.sarpanch),
        ),
      );
      return;
    }
    if (entry.subtitle.toLowerCase().contains('pending')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SportsNeoLedgerPaymentsScreen(mode: SportsNeoLedgerMode.pending),
        ),
      );
      return;
    }
    if (entry.subtitle.toLowerCase().contains('advance')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SportsNeoLedgerPaymentsScreen(mode: SportsNeoLedgerMode.advance),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SportsNeoLedgerHomeData? home = _home;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
            : home == null
                ? const Center(
                    child: Text(
                      'Failed to load ledger data',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: <Widget>[
                      _SportsNeoHeader(
                        title: home.title,
                        showBell: _showBellIcon,
                        onBellTap: _onFooterTap,
                      ),
                      const SizedBox(height: 16),
                      _BalanceCard(
                        amount: home.netBalance,
                        positive: home.netPositive,
                        actionPrimaryText: home.addReceiptLabel,
                        actionSecondaryText: home.addPaymentLabel,
                        balanceLabel: home.balanceLabel,
                        mode: widget.mode,
                        onBellTap: _onFooterTap,
                        onPrimaryTap: () => _openAddMoney('receipt'),
                        onSecondaryTap: () => _openAddMoney('payment'),
                      ),
                      // Stat chips row (sarpanch: Total Paid / Total Expense / Matches Played)
                      if (home.statChips.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Row(
                          children: home.statChips.map((SportsNeoSummaryLine chip) {
                            final Color chipBorder = chip.label == 'Total Paid'
                                ? const Color(0x3D08B36A)
                                : chip.label == 'Total Expense'
                                    ? const Color(0x3DE3220D)
                                    : const Color(0x3DEB8B34);
                            final Color chipBg = chip.label == 'Total Paid'
                                ? const Color(0x0F08B36A)
                                : chip.label == 'Total Expense'
                                    ? const Color(0x1FE3220D)
                                    : const Color(0x1FEB8B34);
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: chip == home.statChips.last ? 0 : 8,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: chipBorder),
                                  color: chipBg,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      chip.label == 'Matches Played'
                                          ? '${chip.amount}'
                                          : '₹${chip.amount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      chip.label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                          color: const Color(0x14FFFFFF),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  home.sectionTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (home.showShareInSection)
                                  InkWell(
                                    onTap: () {},
                                    child: const Row(
                                      children: <Widget>[
                                        Text(
                                          'Share',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.share_outlined,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (widget.mode == SportsNeoLedgerMode.sarpanch)
                              ...home.entries.map(
                                (SportsNeoLedgerEntry item) => _SarpanchTxRow(entry: item),
                              )
                            else
                              ...home.entries.map(
                                (SportsNeoLedgerEntry item) => _LedgerRow(
                                  entry: item,
                                  onTap: () => _onEntryTap(item),
                                ),
                              ),
                            if (widget.mode != SportsNeoLedgerMode.home) ...<Widget>[
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 44),
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  widget.mode == SportsNeoLedgerMode.sarpanch
                                      ? 'View all Payment history'
                                      : 'View full player ledger',
                                  style: const TextStyle(color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_footerButton.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _onFooterTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _footerColor,
                              foregroundColor: widget.mode == SportsNeoLedgerMode.pending
                                  ? const Color(0xFF242424)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _footerButton,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class SportsNeoMatchLedgerScreen extends StatefulWidget {
  const SportsNeoMatchLedgerScreen({
    super.key,
    required this.repository,
    required this.groundId,
    required this.matchId,
  });

  final SportsNeoLedgerRepository repository;
  final String groundId;
  final String matchId;

  @override
  State<SportsNeoMatchLedgerScreen> createState() => _SportsNeoMatchLedgerScreenState();
}

class _SportsNeoMatchLedgerScreenState extends State<SportsNeoMatchLedgerScreen> {
  SportsNeoMatchLedgerData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SportsNeoMatchLedgerData data = await widget.repository
        .loadMatchLedger(widget.groundId, widget.matchId);
    if (!mounted) {
      return;
    }
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SportsNeoMatchLedgerData? data = _data;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
            : data == null
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: <Widget>[
                      _SportsNeoHeader(title: data.matchTitle),
                      const SizedBox(height: 16),
                      _BalanceCard(
                        amount: data.netBalance,
                        positive: data.netPositive,
                        actionPrimaryText: 'Add Receipt',
                        actionSecondaryText: 'Add Payment',
                        onPrimaryTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SportsNeoAddMoneyScreen(
                                title: 'Add Receipt',
                                subtitle: data?.matchTitle,
                                kind: 'receipt',
                                repository: widget.repository,
                                groundId: widget.groundId,
                              ),
                            ),
                          );
                        },
                        onSecondaryTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SportsNeoAddMoneyScreen(
                                title: 'Add Payment',
                                subtitle: data?.matchTitle,
                                kind: 'payment',
                                repository: widget.repository,
                                groundId: widget.groundId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _BookingCard(data: data),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                          color: const Color(0x14FFFFFF),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Transactions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SportsNeoReplacePlayerScreen(
                                      repository: widget.repository,
                                      groundId: widget.groundId,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Replace Player',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...data.transactions.map(
                              (SportsNeoLedgerEntry item) => _LedgerRow(
                                entry: item,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class SportsNeoAddMoneyScreen extends StatefulWidget {
  const SportsNeoAddMoneyScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.kind,
    required this.repository,
    required this.groundId,
  });

  final String title;
  final String? subtitle;
  final String kind;
  final SportsNeoLedgerRepository repository;
  final String groundId;

  @override
  State<SportsNeoAddMoneyScreen> createState() => _SportsNeoAddMoneyScreenState();
}

class _SportsNeoAddMoneyScreenState extends State<SportsNeoAddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedPlayer = 'Rakesh Sharma';
  String _method = 'UPI';
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final int amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _saving = true);
    await widget.repository.addMoney(
      widget.groundId,
      SportsNeoAddMoneyPayload(
        amount: amount,
        playerId: _selectedPlayer,
        note: _noteController.text.trim(),
        method: _method.toLowerCase(),
        kind: widget.kind,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.title} saved')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            _SportsNeoHeader(title: widget.title, subtitle: widget.subtitle),
            const SizedBox(height: 24),
            const _InputLabel('Enter Amount'),
            const SizedBox(height: 8),
            _AmountField(controller: _amountController),
            const SizedBox(height: 14),
            _InputLabel(widget.kind == 'receipt' ? 'Received by' : 'Paid by'),
            const SizedBox(height: 8),
            _DropdownField<String>(
              value: _selectedPlayer,
              options: const <String>[
                'Rakesh Sharma',
                'Lekhi Raja',
                'Pritam Sarpanch',
                'Manu XI',
              ],
              onChanged: (String value) => setState(() => _selectedPlayer = value),
            ),
            const SizedBox(height: 14),
            const _InputLabel('Description / Note '),
            const SizedBox(height: 8),
            _TextAreaField(
              controller: _noteController,
              hintText: widget.kind == 'receipt'
                  ? 'e.g. Winning Amount, Donation etc'
                  : 'e.g. Refreshment expense, tent expense',
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              selected: _method == 'UPI',
              title: 'UPI',
              subtitle: 'GPay / PhonePe / Paytm',
              icon: Icons.payment_outlined,
              onTap: () => setState(() => _method = 'UPI'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              selected: _method == 'Card',
              title: 'Card',
              subtitle: 'Debit / Credit Card',
              icon: Icons.credit_card_outlined,
              onTap: () => setState(() => _method = 'Card'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              selected: _method == 'Cash',
              title: 'Cash',
              subtitle: 'In hand payment',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => setState(() => _method = 'Cash'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _saving ? 'Saving...' : (widget.kind == 'receipt' ? 'Save Receipt' : 'Save Payment'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SportsNeoReplacePlayerScreen extends StatefulWidget {
  const SportsNeoReplacePlayerScreen({
    super.key,
    required this.repository,
    required this.groundId,
  });

  final SportsNeoLedgerRepository repository;
  final String groundId;

  @override
  State<SportsNeoReplacePlayerScreen> createState() => _SportsNeoReplacePlayerScreenState();
}

class _SportsNeoReplacePlayerScreenState extends State<SportsNeoReplacePlayerScreen> {
  String _from = 'Rakesh Sharma';
  String _to = 'Gagi Jassal';
  String _mode = 'transfer';
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.repository.replacePlayer(widget.groundId, _from, _to, _mode);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Player replacement updated')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            const _SportsNeoHeader(title: 'Replace Player'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x1FFFFFFF)),
                color: const Color(0x14FFFFFF),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Match',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '12 Feb',
                    style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Sector 22 Turf',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Replace',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  _DropdownField<String>(
                    value: _from,
                    options: const <String>[
                      'Rakesh Sharma',
                      'Lekhi Raja',
                      'Pritam Sarpanch',
                    ],
                    onChanged: (String value) => setState(() => _from = value),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Icon(Icons.swap_vert, color: Colors.white70, size: 26),
                  ),
                  const SizedBox(height: 8),
                  _DropdownField<String>(
                    value: _to,
                    options: const <String>['Gagi Jassal', 'Manu XI', 'Rajkamal'],
                    onChanged: (String value) => setState(() => _to = value),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Payment Handling',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _PaymentHandlingChoice(
                    selected: _mode == 'transfer',
                    title: 'Transfer Payment',
                    subtitle: 'The new player will assume pending amount for this match.',
                    onTap: () => setState(() => _mode = 'transfer'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentHandlingChoice(
                    selected: _mode == 'resplit',
                    title: 'Re-split Among Players',
                    subtitle: 'Cost will be divided equally among remaining players.',
                    onTap: () => setState(() => _mode = 'resplit'),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x1FDF781B)),
                      color: const Color(0x0FDF781B),
                    ),
                    child: const Text(
                      'This updates payment for this match only.',
                      style: TextStyle(color: Color(0xFFD87A25), fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _saving ? 'Confirming...' : 'Confirm Replace',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportsNeoHeader extends StatelessWidget {
  const _SportsNeoHeader({
    required this.title,
    this.subtitle,
    this.showBell = false,
    this.onBellTap,
  });

  final String title;
  final String? subtitle;
  final bool showBell;
  final VoidCallback? onBellTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(22),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: subtitle != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        if (showBell)
          InkWell(
            onTap: onBellTap,
            borderRadius: BorderRadius.circular(20),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.notifications_none_rounded, color: Color(0xFF2563EB)),
            ),
          ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.amount,
    required this.positive,
    required this.actionPrimaryText,
    required this.actionSecondaryText,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    this.balanceLabel = 'Net Balance',
    this.mode = SportsNeoLedgerMode.home,
    this.onBellTap,
  });

  final int amount;
  final bool positive;
  final String actionPrimaryText;
  final String actionSecondaryText;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;
  final String balanceLabel;
  final SportsNeoLedgerMode mode;
  final VoidCallback? onBellTap;

  @override
  Widget build(BuildContext context) {
    final bool isPending = mode == SportsNeoLedgerMode.pending;
    final bool isAdvance = mode == SportsNeoLedgerMode.advance;
    final bool isShareMode = isPending || isAdvance;

    final Color amountColor = isPending
        ? const Color(0xFFF59E0B)
        : positive
            ? const Color(0xFF08B36A)
            : const Color(0xFFE03624);
    final String amountText = '${positive ? '+' : '-'}₹${amount.abs()}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x14EDFFF7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                balanceLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isAdvance && onBellTap != null)
                InkWell(
                  onTap: onBellTap,
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amountText,
            style: TextStyle(
              color: amountColor,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (isShareMode)
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrimaryTap,
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFF08B36A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.whatsapp,
                          color: Color(0xFF08B36A),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const <Widget>[
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                color: Color(0xFF08B36A),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              'Send to all',
                              style: TextStyle(
                                color: Color(0xFF08B36A),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: _MiniActionButton(
                    text: actionPrimaryText,
                    icon: actionPrimaryText == 'Add Money'
                        ? Icons.arrow_upward_rounded
                        : null,
                    color: const Color(0xFF08B36A),
                    border: const Color(0xFFA5FDD7),
                    onTap: onPrimaryTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniActionButton(
                    text: actionSecondaryText,
                    icon: actionSecondaryText == 'Add Dues'
                        ? Icons.arrow_downward_rounded
                        : null,
                    color: const Color(0xFFF59E0B),
                    border: const Color(0xFFFFEBC9),
                    onTap: onSecondaryTap,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.text,
    required this.color,
    required this.border,
    required this.onTap,
    this.icon,
  });

  final String text;
  final Color color;
  final Color border;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color,
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.onTap});

  final SportsNeoLedgerEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color amountColor = entry.isCredit ? const Color(0xFF08B36A) : const Color(0xFFDE7818);
    final String amountText = '${entry.isCredit ? '+' : ''}₹${entry.amount.abs()}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x14FFFFFF),
              ),
              child: Text(
                '${entry.index}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (entry.subtitle.isNotEmpty)
                    Text(
                      entry.subtitle,
                      style: TextStyle(
                        color: entry.subtitle.toLowerCase().contains('pending')
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF08B36A),
                        fontSize: 12,
                      ),
                    ),
                  if (entry.phone.isNotEmpty)
                    Text(
                      entry.phone,
                      style: TextStyle(
                        color: entry.isCredit ? const Color(0xFF08B36A) : const Color(0xFFF59E0B),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountText,
              style: TextStyle(color: amountColor, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (entry.hasWhatsapp) ...<Widget>[
              const SizedBox(width: 10),
              const Icon(Icons.chat_outlined, color: Color(0xFF08B36A), size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.data});

  final SportsNeoMatchLedgerData data;

  @override
  Widget build(BuildContext context) {
    final int total = data.paymentLines.fold<int>(data.matchAmount, (int acc, SportsNeoSummaryLine line) {
      if (line.label.toLowerCase().contains('discount')) {
        return acc - line.amount;
      }
      if (line.label.toLowerCase().contains('ground fee')) {
        return acc;
      }
      return acc + line.amount;
    });
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            data.bookingTitle,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x3D2563EB)),
              color: const Color(0x142563EB),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.bookingGround,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  data.bookingDate,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  data.bookingTime,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Payment Summary',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ...data.paymentLines.map(
                  (SportsNeoSummaryLine line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          line.label,
                          style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                        ),
                        Text(
                          '${line.label.toLowerCase().contains('discount') ? '-' : ''}₹${line.amount}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Color(0x33FFFFFF), height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Total Amount',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '₹$total',
                      style: const TextStyle(color: Color(0xFF2563EB), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x08FFFFFF),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            '₹',
            style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAreaField extends StatelessWidget {
  const _TextAreaField({required this.controller, this.hintText});

  final TextEditingController controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          hintText: hintText ?? 'e.g. Refreshment expense, tent expense',
          hintStyle: const TextStyle(color: Color(0x99FFFFFF)),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF111827),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: options
              .map(
                (T item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: (T? value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _PaymentMethodItem extends StatelessWidget {
  const _PaymentMethodItem({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF2563EB) : Colors.white38,
              size: 24,
            ),
            const SizedBox(width: 12),
            if (icon != null) ...<Widget>[
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SarpanchTxRow extends StatelessWidget {
  const _SarpanchTxRow({required this.entry});

  final SportsNeoLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool isDue = entry.title.toLowerCase().contains('dues');
    final Color titleColor = isDue ? const Color(0xFFF59E0B) : Colors.white;
    final Color amountColor = entry.isCredit ? Colors.white : const Color(0xFFE3220D);
    final String amountText =
        '${entry.isCredit ? '' : '-'}\u20b9${entry.amount}';

    final bool hasRunning = entry.runningBalance != null;
    final Color runningColor =
        entry.isRunning ? const Color(0xFF08B36A) : const Color(0xFFF59E0B);
    final Color runningBg =
        entry.isRunning ? const Color(0x1F08B36A) : const Color(0x1FF59E0B);
    final Color runningBorder =
        entry.isRunning ? const Color(0x0808B36A) : const Color(0x08F59E0B);
    final String runningLabel =
        entry.isRunning ? 'Running Balance' : 'Pending Balance';
    final String runningText =
        '${entry.isRunning ? '+' : '-'}\u20b9${entry.runningBalance?.abs() ?? 0}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x0AFFFFFF),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        entry.title,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (entry.date.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            entry.date,
                            style: const TextStyle(
                              color: Color(0xFF667084),
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (entry.paymentMethod.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0x0AFFFFFF)),
                          color: const Color(0x0A10B981),
                        ),
                        child: Text(
                          entry.paymentMethod,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (entry.paymentMethod.isNotEmpty)
                      const SizedBox(height: 4),
                    Text(
                      entry.amount == 0 && entry.isCredit
                          ? '\u20b90'
                          : amountText,
                      style: TextStyle(
                        color: entry.amount == 0
                            ? Colors.white54
                            : amountColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (hasRunning) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: runningBorder),
                      color: runningBg,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          runningText,
                          style: TextStyle(
                            color: runningColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          runningLabel,
                          style: TextStyle(
                            color: runningColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.hasEdit || entry.hasDelete)
                    Row(
                      children: <Widget>[
                        if (entry.hasEdit)
                          const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        if (entry.hasEdit && entry.hasDelete)
                          const SizedBox(width: 16),
                        if (entry.hasDelete)
                          const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFE3220D),
                            size: 22,
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentHandlingChoice extends StatelessWidget {
  const _PaymentHandlingChoice({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
          ),
          color: const Color(0x08FFFFFF),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? const Color(0xFF2563EB) : Colors.white54,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
