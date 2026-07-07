import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';
import 'package:flutter/services.dart';

import '../../academy/home/academy_dashboard_screen.dart';
import '../../box_cricket/home/box_cricket_dashboard_screen.dart';
import '../../sports_neo/home/sports_neo_dashboard_screen.dart';
import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../dashboard/dashboard_turf_screen.dart';

class GroundManagementOtpAuthScreen extends StatefulWidget {
  const GroundManagementOtpAuthScreen({
    super.key,
    this.contactNumber,
    this.uiOtp,
  });

  final String? contactNumber;
  final String? uiOtp;

  @override
  State<GroundManagementOtpAuthScreen> createState() =>
      _GroundManagementOtpAuthScreenState();
}

class _GroundManagementOtpAuthScreenState
    extends State<GroundManagementOtpAuthScreen> {
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  late final TextEditingController _phoneController;
  final GroundWaleApi _api = GroundWaleApi.instance;
  bool _isLoading = false;
  String? _apiOtpPreview;

  @override
  void initState() {
    super.initState();
    _otpControllers = List<TextEditingController>.generate(
      4,
      (_) => TextEditingController(),
    );
    _otpFocusNodes = List<FocusNode>.generate(4, (_) => FocusNode());
    _phoneController = TextEditingController(
      text: widget.contactNumber ?? ApiSession.instance.contactNumber ?? '',
    );
    _apiOtpPreview = widget.uiOtp;
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _otpControllers) {
      controller.dispose();
    }
    for (final FocusNode focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _phoneController.dispose();
    super.dispose();
  }

  String get _otpValue => _otpControllers
      .map((TextEditingController controller) => controller.text)
      .join();

  Future<void> _resendOtp() async {
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
      if (mounted) {
        setState(() {
          _apiOtpPreview = otp;
        });
      }
      ApiSession.instance.setContactNumber(contactNumber);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent successfully')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final String contactNumber = _phoneController.text.trim();

    if (contactNumber.isEmpty || _otpValue.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter contact number and 4 digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> response = await _api.verifyOtp(
        contactNumber: contactNumber,
        otp: _otpValue,
      );
      final Map<String, dynamic> user = _extractUser(response);
      ApiSession.instance.updateFromAuth(user);
      String role = _extractRole(response, user);

      // Prefer latest role from profile API after OTP verification.
      if (ApiSession.instance.ownerId != null) {
        try {
          final Map<String, dynamic> profile = await _api.getOwnerProfile(
            ApiSession.instance.ownerId!,
          );
          ApiSession.instance.updateFromAuth(profile);
          final String profileRole = _normalizeRole(profile['role']);
          if (profileRole.isNotEmpty) {
            role = profileRole;
          }
        } catch (_) {
          // Keep existing role value if profile lookup fails.
        }
      }

      if (!mounted) {
        return;
      }

      if (_isAcademyRole(role)) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const AcademyDashboardScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      } else if (_isSportsNeoRole(role)) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const SportsNeoDashboardScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      } else if (_isBoxCricketRole(role)) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const BoxCricketDashboardScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const DashboardTurfScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> response) {
    final dynamic direct = response['user'];
    if (direct is Map) {
      return Map<String, dynamic>.from(direct);
    }

    final dynamic data = response['data'];
    if (data is Map && data['user'] is Map) {
      return Map<String, dynamic>.from(data['user'] as Map);
    }

    final dynamic payload = response['payload'];
    if (payload is Map && payload['user'] is Map) {
      return Map<String, dynamic>.from(payload['user'] as Map);
    }

    throw Exception('Invalid verify response: missing user payload');
  }

  String _extractRole(
    Map<String, dynamic> response,
    Map<String, dynamic> user,
  ) {
    final List<dynamic> candidates = <dynamic>[
      user['role'],
      response['role'],
      (response['data'] is Map ? (response['data'] as Map)['role'] : null),
      (response['payload'] is Map
          ? (response['payload'] as Map)['role']
          : null),
    ];

    for (final dynamic candidate in candidates) {
      final String normalized = _normalizeRole(candidate);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return '';
  }

  String _normalizeRole(dynamic raw) {
    if (raw == null) {
      return '';
    }

    final String role = raw.toString().toLowerCase().trim();
    if (role.isEmpty) {
      return '';
    }

    if (role == 'box_cricket_owner' ||
        role == 'box-cricket' ||
        role == 'box cricket' ||
        role == 'box_cricket' ||
        role == 'boxcricket' ||
        role == 'box') {
      return 'box_cricket_owner';
    }

    if (role == 'academy_owner' || role == 'academy' || role == 'coach') {
      return 'academy_owner';
    }

    if (role == 'ground_owner' ||
        role == 'owner' ||
        role == 'ground' ||
        role == 'turf' ||
        role == 'turf_owner') {
      return 'ground_owner';
    }

    if (role == 'player' ||
        role == 'captain' ||
        role == 'sportsneo' ||
        role == 'sports neo' ||
        role == 'sports_neo' ||
        role == 'sports-neo') {
      return 'player';
    }

    return role;
  }

  bool _isAcademyRole(String role) {
    return role == 'academy_owner';
  }

  bool _isBoxCricketRole(String role) {
    return role == 'box_cricket_owner';
  }

  bool _isSportsNeoRole(String role) {
    return role == 'player';
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
    Widget otpBox(int index) {
      return Container(
        width: 64,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33242424)),
        ),
        child: AppTextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textInputAction: index == 3
              ? TextInputAction.done
              : TextInputAction.next,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            color: Color(0xFF313638),
            fontWeight: FontWeight.w600,
          ),
          cursorColor: const Color(0xFF313638),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            isDense: true,
          ),
          onChanged: (String value) {
            if (value.isNotEmpty && index < 3) {
              _otpFocusNodes[index + 1].requestFocus();
            }
            if (value.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0x1208B36A),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.sports_cricket_rounded,
                          size: 92,
                          color: Color(0xFF1C333B),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Contact Number',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
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
                          border: Border.all(color: const Color(0x3DDDF730)),
                        ),
                        child: AppTextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Enter phone number',
                            hintStyle: const TextStyle(
                              color: Color(0x99242424),
                            ),
                            filled: true,
                            fillColor: const Color(0x0F1C333B),
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
                          onPressed: _isLoading ? null : _resendOtp,
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
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                      const Text(
                        'Register',
                        style: TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(color: const Color(0x66000000)),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Enter Your OTP',
                              style: TextStyle(
                                color: Color(0xFF313638),
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF242424),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'OTP Sent on your register phone number & Email',
                        style: TextStyle(
                          color: Color(0x99313638),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_apiOtpPreview != null && _apiOtpPreview!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'OTP from API: $_apiOtpPreview',
                            style: const TextStyle(
                              color: Color(0xFF1C333B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const Text(
                        'Fill OTP Number',
                        style: TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          otpBox(0),
                          otpBox(1),
                          otpBox(2),
                          otpBox(3),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C333B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _verifyOtp,
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


