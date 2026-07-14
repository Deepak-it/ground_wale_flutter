import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_edit_bank_account_screen.dart';

class BoxCricketBankAccountScreen extends StatefulWidget {
  const BoxCricketBankAccountScreen({super.key});

  @override
  State<BoxCricketBankAccountScreen> createState() =>
      _BoxCricketBankAccountScreenState();
}

class _BoxCricketBankAccountScreenState extends State<BoxCricketBankAccountScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _bank = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> response = await GroundWaleApi.instance
          .getBankAccount(ownerId);
      final Map<String, dynamic> bank = Map<String, dynamic>.from(
        response['bankAccount'] as Map? ?? response,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bank = bank;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  String _maskedAccount(String accountNumber) {
    if (accountNumber.isEmpty) {
      return '';
    }
    if (accountNumber.length <= 4) {
      return accountNumber;
    }
    return '............................${accountNumber.substring(accountNumber.length - 4)}';
  }

  Future<void> _openEdit() async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const BoxCricketEditBankAccountScreen(),
      ),
    );
    if (updated == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String account = _bank['accountNumber']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
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
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x3DFFFFFF)),
                      color: const Color(0x08FFFFFF),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x17000000),
                          blurRadius: 12,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
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
                                  const Text(
                                    'Bank Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _bank['bankName']?.toString().isNotEmpty ==
                                            true
                                        ? '${_bank['bankName']} .....${account.length >= 4 ? account.substring(account.length - 4) : account} Linked'
                                        : 'No bank linked',
                                    style: const TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _openEdit,
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFF08B36A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _field(
                          'Account Number',
                          _maskedAccount(account),
                          mutedLabel: true,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          'IFSC Code',
                          _bank['ifscCode']?.toString() ?? '',
                          mutedLabel: true,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          'Account Holder Name',
                          _bank['accountHolderName']?.toString() ?? '',
                          mutedLabel: true,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          'Branch',
                          _bank['branch']?.toString() ?? '',
                          mutedLabel: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _field(String label, String value, {bool mutedLabel = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: mutedLabel ? const Color(0x99FFFFFF) : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            color: const Color(0x0FFFFFFF),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
