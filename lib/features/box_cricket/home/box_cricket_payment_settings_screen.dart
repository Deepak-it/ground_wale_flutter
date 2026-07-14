import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_edit_bank_account_screen.dart';

class BoxCricketPaymentSettingsScreen extends StatefulWidget {
  const BoxCricketPaymentSettingsScreen({super.key});

  @override
  State<BoxCricketPaymentSettingsScreen> createState() =>
      _BoxCricketPaymentSettingsScreenState();
}

class _BoxCricketPaymentSettingsScreenState
    extends State<BoxCricketPaymentSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  bool _acceptCash = true;
  bool _acceptUpi = true;
  bool _acceptOnline = true;

  Map<String, dynamic> _bank = <String, dynamic>{};
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _settlementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _resolveGroundId() async {
    final ApiSession session = ApiSession.instance;
    if (session.hasGround) {
      return session.groundId;
    }

    final String? ownerId = session.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final String? resolved = await GroundWaleApi.instance
        .ensureGroundIdForOwner(ownerId);
    if (resolved != null && resolved.isNotEmpty) {
      session.setGroundId(resolved);
    }
    return resolved;
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    final String? groundId = await _resolveGroundId();

    if (ownerId == null ||
        ownerId.isEmpty ||
        groundId == null ||
        groundId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
            GroundWaleApi.instance.getGround(groundId),
            GroundWaleApi.instance.getBankAccount(ownerId),
          ]);

      final Map<String, dynamic> ground = Map<String, dynamic>.from(
        results[0] as Map,
      );
      final Map<String, dynamic> bankResponse = Map<String, dynamic>.from(
        results[1] as Map,
      );
      final Map<String, dynamic> bank = Map<String, dynamic>.from(
        bankResponse['bankAccount'] as Map? ?? bankResponse,
      );

      final Map<String, dynamic> paymentSettings = Map<String, dynamic>.from(
        ground['paymentSettings'] as Map? ?? <String, dynamic>{},
      );

      _acceptCash =
          paymentSettings['acceptCash'] as bool? ??
          ground['acceptCash'] as bool? ??
          true;
      _acceptUpi =
          paymentSettings['acceptUpi'] as bool? ??
          ground['acceptUpi'] as bool? ??
          true;
      _acceptOnline =
          paymentSettings['acceptOnline'] as bool? ??
          ground['acceptOnline'] as bool? ??
          true;
      _upiController.text =
          paymentSettings['upiId']?.toString() ??
          ground['upiId']?.toString() ??
          '';
      _settlementController.text =
          paymentSettings['settlementInfo']?.toString() ??
          ground['settlementInfo']?.toString() ??
          'Settlements are processed within 24 hours';

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

  Future<void> _openEditBank() async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const BoxCricketEditBankAccountScreen(),
      ),
    );
    if (updated == true) {
      await _load();
    }
  }

  Future<void> _save() async {
    final String? groundId = await _resolveGroundId();
    if (groundId == null || groundId.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await GroundWaleApi.instance.updateGround(groundId, <String, dynamic>{
        'acceptCash': _acceptCash,
        'acceptUpi': _acceptUpi,
        'acceptOnline': _acceptOnline,
        'upiId': _upiController.text.trim(),
        'settlementInfo': _settlementController.text.trim(),
        'paymentSettings': <String, dynamic>{
          'acceptCash': _acceptCash,
          'acceptUpi': _acceptUpi,
          'acceptOnline': _acceptOnline,
          'upiId': _upiController.text.trim(),
          'settlementInfo': _settlementController.text.trim(),
        },
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment settings updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _bankTitle() {
    final String bankName = _bank['bankName']?.toString().trim() ?? '';
    final String account = _bank['accountNumber']?.toString().trim() ?? '';
    if (bankName.isEmpty || account.isEmpty) {
      return 'No bank linked';
    }
    final String suffix = account.length >= 4
        ? account.substring(account.length - 4)
        : account;
    return '$bankName .....$suffix linked';
  }

  @override
  void dispose() {
    _upiController.dispose();
    _settlementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      const Expanded(
                        child: Text(
                          'Payment Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Payment Methods',
                    children: <Widget>[
                      _toggleTile(
                        title: 'Cash Payments',
                        subtitle: 'Allow players to pay at the ground',
                        value: _acceptCash,
                        onChanged: (bool value) {
                          setState(() => _acceptCash = value);
                        },
                      ),
                      _divider(),
                      _toggleTile(
                        title: 'UPI Payments',
                        subtitle: 'Enable direct UPI transfer option',
                        value: _acceptUpi,
                        onChanged: (bool value) {
                          setState(() => _acceptUpi = value);
                        },
                      ),
                      _divider(),
                      _toggleTile(
                        title: 'Online Payment Gateway',
                        subtitle: 'Allow prepaid online bookings',
                        value: _acceptOnline,
                        onChanged: (bool value) {
                          setState(() => _acceptOnline = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Bank Account',
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.account_balance_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _bankTitle(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openEditBank,
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Color(0xFF08B36A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _openEditBank,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF08B36A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Add Bank Account',
                            style: TextStyle(
                              color: Color(0xFF08B36A),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'UPI & Settlement',
                    children: <Widget>[
                      _field(
                        label: 'UPI ID',
                        controller: _upiController,
                        hint: 'example@upi',
                      ),
                      const SizedBox(height: 12),
                      _field(
                        label: 'Settlement Info',
                        controller: _settlementController,
                        hint: 'Settlements are processed within 24 hours',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08B36A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Settings',
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

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: const Color(0x1FFFFFFF),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF08B36A),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0x80FFFFFF),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: controller,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
            filled: true,
            fillColor: const Color(0x0FFFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF08B36A)),
            ),
          ),
        ),
      ],
    );
  }
}


