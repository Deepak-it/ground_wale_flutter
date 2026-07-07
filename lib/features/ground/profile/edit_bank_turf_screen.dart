import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'profile_turf_ui.dart';

class EditBankTurfScreen extends StatefulWidget {
  const EditBankTurfScreen({super.key});

  @override
  State<EditBankTurfScreen> createState() => _EditBankTurfScreenState();
}

class _EditBankTurfScreenState extends State<EditBankTurfScreen> {
  final TextEditingController holderController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController branchController = TextEditingController();
  bool _isSaving = false;

  Future<void> _loadBank() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      return;
    }

    final Map<String, dynamic> response = await GroundWaleApi.instance.getBankAccount(session.ownerId!);
    final Map<String, dynamic> bank = Map<String, dynamic>.from(response['bankAccount'] as Map? ?? <String, dynamic>{});
    holderController.text = bank['accountHolderName']?.toString() ?? '';
    accountController.text = bank['accountNumber']?.toString() ?? '';
    ifscController.text = bank['ifscCode']?.toString() ?? '';
    bankNameController.text = bank['bankName']?.toString() ?? '';
    branchController.text = bank['branch']?.toString() ?? '';
  }

  Future<void> _saveBank() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await GroundWaleApi.instance.updateBankAccount(
        session.ownerId!,
        <String, dynamic>{
          'accountHolderName': holderController.text.trim(),
          'accountNumber': accountController.text.trim(),
          'ifscCode': ifscController.text.trim(),
          'bankName': bankNameController.text.trim(),
          'branch': branchController.text.trim(),
        },
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    holderController.dispose();
    accountController.dispose();
    ifscController.dispose();
    bankNameController.dispose();
    branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String label, TextEditingController controller) {
      return TurfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(color: Colors.white70)),
            AppTextField(controller: controller, decoration: const InputDecoration(border: InputBorder.none)),
          ],
        ),
      );
    }

    return TurfPageScaffold(
      title: 'Tap on Edit Bank Text Button',
      child: FutureBuilder<void>(
        future: _loadBank(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
          }

          return ListView(
            children: <Widget>[
              field('Bank Name', bankNameController),
              field('Account Holder', holderController),
              field('Account Number', accountController),
              field('IFSC', ifscController),
              field('Branch', branchController),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _isSaving ? null : _saveBank, child: const Text('Save Bank Details')),
            ],
          );
        },
      ),
    );
  }
}


