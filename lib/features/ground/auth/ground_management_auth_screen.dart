import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../flow/screens/register_ground_flow_screen.dart';
import 'ground_management_otp_auth_screen.dart';

class GroundManagementAuthScreen extends StatefulWidget {
  const GroundManagementAuthScreen({super.key});

  @override
  State<GroundManagementAuthScreen> createState() =>
      _GroundManagementAuthScreenState();
}

class _GroundManagementAuthScreenState
    extends State<GroundManagementAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GroundWaleApi _api = GroundWaleApi.instance;
  bool _isLoading = false;
  String? _apiOtpPreview;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtpAndOpenVerification() async {
    final String contactNumber = _phoneController.text.trim();

    if (contactNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a contact number')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> response = await _api.sendLoginOtp(
        contactNumber: contactNumber,
      );
      final String? otp = _extractOtp(response);
      ApiSession.instance.setContactNumber(contactNumber);
      if (mounted) {
        setState(() {
          _apiOtpPreview = otp;
        });
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroundManagementOtpAuthScreen(
            contactNumber: contactNumber,
            uiOtp: otp,
          ),
        ),
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
        setState(() => _isLoading = false);
      }
    }
  }

  String? _extractOtp(Map<String, dynamic> response) {
    final dynamic directOtp = response['otp'];
    if (directOtp != null) {
      return directOtp.toString();
    }

    final dynamic data = response['data'];
    if (data is Map<String, dynamic> && data['otp'] != null) {
      return data['otp'].toString();
    }

    final dynamic payload = response['payload'];
    if (payload is Map<String, dynamic> && payload['otp'] != null) {
      return payload['otp'].toString();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Contact Number',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF242424),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF242424)),
                    ),
                    child: AppTextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Color(0xFF242424)),
                      cursorColor: const Color(0xFF242424),
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        hintStyle: const TextStyle(color: Color(0xFF242424)),
                        filled: true,
                        fillColor: const Color(0xFFFFFFFF),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C333B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : _sendOtpAndOpenVerification,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  if (_apiOtpPreview != null && _apiOtpPreview!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        'OTP from API: $_apiOtpPreview',
                        style: const TextStyle(
                          color: Color(0xFF1C333B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 26),
                  const Text(
                    'or',
                    style: TextStyle(
                      color: Color(0xFF242424),
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterGroundFlowScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Color(0xFF242424),
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


