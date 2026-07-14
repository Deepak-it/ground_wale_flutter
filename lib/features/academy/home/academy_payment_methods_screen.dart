import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyPaymentMethodsScreen extends StatefulWidget {
  const AcademyPaymentMethodsScreen({super.key});

  @override
  State<AcademyPaymentMethodsScreen> createState() =>
      _AcademyPaymentMethodsScreenState();
}

class _AcademyPaymentMethodsScreenState
    extends State<AcademyPaymentMethodsScreen> {
  bool _upiEnabled = true;
  bool _cashEnabled = true;
  bool _bankTransferEnabled = false;
  bool _isLoading = true;
  String _upiId = '';

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
      final Map<String, dynamic> profile = await GroundWaleApi.instance
          .getOwnerProfile(ownerId);
      final Map<String, dynamic> methods = Map<String, dynamic>.from(
        profile['paymentMethods'] as Map? ?? <String, dynamic>{},
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _upiEnabled = methods['upiEnabled'] != false;
        _cashEnabled = methods['cashEnabled'] != false;
        _bankTransferEnabled = methods['bankTransferEnabled'] == true;
        _upiId = methods['upiId']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }
    try {
      await GroundWaleApi.instance.updateOwnerProfile(
        ownerId,
        <String, dynamic>{
          'paymentMethods': <String, dynamic>{
            'upiEnabled': _upiEnabled,
            'cashEnabled': _cashEnabled,
            'bankTransferEnabled': _bankTransferEnabled,
            'upiId': _upiId,
          },
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Payment Methods',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PaymentMethodTile(
                      title: 'UPI',
                      subtitle: 'Google Pay, PhonePe, Paytm',
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFF9C1FD5),
                      iconBackground: const Color(0x0FFFFFFF),
                      value: _upiEnabled,
                      onChanged: (bool value) {
                        setState(() => _upiEnabled = value);
                        _save();
                      },
                      child: _DetailField(
                        label: 'UPI ID',
                        value: _upiId.trim().isEmpty ? '-' : _upiId,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PaymentMethodTile(
                      title: 'Cash',
                      subtitle: 'Accept cash payment',
                      icon: Icons.payments_outlined,
                      iconColor: const Color(0xFF08B36A),
                      iconBackground: const Color(0x0FFFFFFF),
                      value: _cashEnabled,
                      onChanged: (bool value) {
                        setState(() => _cashEnabled = value);
                        _save();
                      },
                    ),
                    const SizedBox(height: 16),
                    _PaymentMethodTile(
                      title: 'Bank Transfer',
                      subtitle: 'Direct bank account transfer',
                      icon: Icons.account_balance_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBackground: const Color(0x0FFFFFFF),
                      value: _bankTransferEnabled,
                      onChanged: (bool value) {
                        setState(() => _bankTransferEnabled = value);
                        _save();
                      },
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: null,
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.onChanged,
    this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF00C9A7),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0x80FFFFFF),
                ),
              ),
            ],
          ),
          if (child != null) ...<Widget>[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1FFFFFFF)),
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
