import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/labeled_text_field.dart';
import '../../../../core/widgets/neon_button.dart';
import '../controllers/ground_flow_controller.dart';

class BasicDetailsScreen extends StatefulWidget {
  const BasicDetailsScreen({super.key, required this.controller});

  final GroundFlowController controller;

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  late final TextEditingController ownerController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;
  String? _apiOtpPreview;

  @override
  void initState() {
    super.initState();
    ownerController = TextEditingController(
      text: widget.controller.data.ownerName,
    );
    phoneController = TextEditingController(
      text: widget.controller.data.contactNumber,
    );
    emailController = TextEditingController(text: widget.controller.data.email);
    addressController = TextEditingController(
      text: widget.controller.data.address,
    );
  }

  @override
  void dispose() {
    ownerController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _showOtpDialog() async {
    final TextEditingController otpController = TextEditingController();

    _sync();
    if (widget.controller.data.contactNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a contact number first')),
      );
      otpController.dispose();
      return;
    }

    try {
      final Map<String, dynamic> response = await _api.sendRegisterOtp(
        contactNumber: widget.controller.data.contactNumber,
        ownerName: widget.controller.data.ownerName.isEmpty
            ? 'Ground Owner'
            : widget.controller.data.ownerName,
        email: widget.controller.data.email,
        role: 'ground_owner',
      );
      final String? otp = _extractOtp(response);
      if (mounted) {
        setState(() {
          _apiOtpPreview = otp;
        });
      }
      ApiSession.instance.setContactNumber(
        widget.controller.data.contactNumber,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      otpController.dispose();
      return;
    }

    if (!mounted) {
      otpController.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222826),
          title: const Text('Enter Your OTP'),
          content: AppTextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(hintText: '4 digit OTP'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (otpController.text.trim().length != 4) {
                  return;
                }

                try {
                  final Map<String, dynamic> response = await _api.verifyOtp(
                    contactNumber: widget.controller.data.contactNumber,
                    otp: otpController.text.trim(),
                  );
                  final Map<String, dynamic> user = Map<String, dynamic>.from(
                    response['user'] as Map,
                  );
                  ApiSession.instance.updateFromAuth(user);
                  widget.controller.data.otpVerified = true;
                  widget.controller.update();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    otpController.dispose();
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

  void _sync() {
    widget.controller.data.ownerName = ownerController.text.trim();
    widget.controller.data.contactNumber = phoneController.text.trim();
    widget.controller.data.email = emailController.text.trim();
    widget.controller.data.address = addressController.text.trim();
    widget.controller.update();
  }

  @override
  Widget build(BuildContext context) {
    final GroundFlowController controller = widget.controller;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Fill Basic Details',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text('Step 1 of 5', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: <Widget>[
                LabeledTextField(
                  label: 'Owner Name',
                  controller: ownerController,
                  hint: 'Enter Owner Name',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Contact Number',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  hint: 'Enter Phone Number',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Email Address (Optional)',
                  controller: emailController,
                  hint: 'Enter Email (Optional)',
                  onChanged: (_) => _sync(),
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Address',
                  controller: addressController,
                  hint: 'Enter your address',
                  onChanged: (_) => _sync(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (controller.data.otpVerified)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'OTP verified',
                style: TextStyle(color: Color(0xFFDDF730)),
              ),
            ),
          if (_apiOtpPreview != null && _apiOtpPreview!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'OTP from API: $_apiOtpPreview',
                style: const TextStyle(
                  color: Color(0xFFDDF730),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          NeonButton(label: 'Generate OTP', onPressed: _showOtpDialog),
          const SizedBox(height: 12),
          NeonButton(
            label: 'Next',
            onPressed: controller.canContinueStep0 ? controller.nextStep : null,
          ),
        ],
      ),
    );
  }
}


