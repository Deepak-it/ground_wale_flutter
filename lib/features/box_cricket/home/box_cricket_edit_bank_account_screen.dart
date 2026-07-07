import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class BoxCricketEditBankAccountScreen extends StatefulWidget {
  const BoxCricketEditBankAccountScreen({super.key});

  @override
  State<BoxCricketEditBankAccountScreen> createState() =>
      _BoxCricketEditBankAccountScreenState();
}

class _BoxCricketEditBankAccountScreenState
    extends State<BoxCricketEditBankAccountScreen> {
  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

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
      _holderController.text = bank['accountHolderName']?.toString() ?? '';
      _bankNameController.text = bank['bankName']?.toString() ?? '';
      _ifscController.text = bank['ifscCode']?.toString() ?? '';
      _accountNumberController.text = bank['accountNumber']?.toString() ?? '';
      _branchController.text = bank['branch']?.toString() ?? '';
    } catch (_) {
      // Keep empty form when no existing account is available.
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await GroundWaleApi.instance.updateBankAccount(ownerId, <String, dynamic>{
        'accountHolderName': _holderController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'ifscCode': _ifscController.text.trim().toUpperCase(),
        'accountNumber': _accountNumberController.text.trim(),
        'branch': _branchController.text.trim(),
      });
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _holderController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    _accountNumberController.dispose();
    _branchController.dispose();
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
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
                    child: Row(
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
                            'Edit Bank Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      children: <Widget>[
                        _field(
                          'Account Holder Name',
                          _holderController,
                        ),
                        const SizedBox(height: 16),
                        _field('Bank Name', _bankNameController),
                        const SizedBox(height: 16),
                        _field('IFSC Code', _ifscController),
                        const SizedBox(height: 6),
                        const Text(
                          'bank name will be auto-detected from IFSC',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field('Account Number', _accountNumberController),
                        const SizedBox(height: 6),
                        const Text(
                          'Account Number Match',
                          style: TextStyle(
                            color: Color(0xFF08B36A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field('Branch', _branchController),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF08B36A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                            : const Text('Save Money'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
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
            filled: true,
            fillColor: const Color(0x08FFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
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


