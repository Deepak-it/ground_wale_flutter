// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../academy/home/academy_dashboard_screen.dart';
import '../../box_cricket/home/box_cricket_dashboard_screen.dart';
import '../../ground/dashboard/dashboard_turf_screen.dart';
import '../../ground/flow/controllers/ground_flow_controller.dart';
import '../../ground/flow/models/ground_registration_data.dart';
import '../../ground/flow/screens/register_ground_flow_screen.dart';
import 'sports_neo_dashboard_screen.dart';

Map<String, dynamic> _extractUser(Map<String, dynamic> response) {
  final dynamic direct = response['user'];
  if (direct is Map) {
    return Map<String, dynamic>.from(direct);
  }

  final dynamic data = response['data'];
  if (data is Map && data['user'] is Map) {
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  return <String, dynamic>{};
}

String? _extractOtpValue(Map<String, dynamic> response) {
  String? readFromMap(Map<String, dynamic> map) {
    for (final String key in <String>['otp', 'code', 'verificationCode']) {
      final dynamic value = map[key];
      if (value == null) {
        continue;
      }
      final String text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  final String? direct = readFromMap(response);
  if (direct != null) {
    return direct;
  }

  final dynamic data = response['data'];
  if (data is Map) {
    return readFromMap(Map<String, dynamic>.from(data));
  }

  return null;
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

bool _isAcademyOwnerRole(String role) {
  return role == 'academy_owner';
}

bool _isBoxCricketOwnerRole(String role) {
  return role == 'box_cricket_owner';
}

bool _isGroundOwnerRole(String role) {
  return role == 'ground_owner';
}

bool _isSportsPlayerRole(String role) {
  return role == 'player';
}

bool _isSportsNeoPlayerRole(dynamic raw) {
  if (raw == null) {
    return false;
  }
  final String role = raw.toString().toLowerCase().trim();
  return role == 'player' || role == 'captain';
}

Future<bool> _routeExistingUserToDashboard(
  BuildContext context,
  GroundWaleApi api,
) async {
  final String? ownerId = ApiSession.instance.ownerId;
  if (ownerId == null || ownerId.isEmpty) {
    return false;
  }

  String role = _normalizeRole(ApiSession.instance.role);
  bool sportsNeoPlayer = false;
  try {
    final Map<String, dynamic> profile = await api.getOwnerProfile(ownerId);
    ApiSession.instance.updateFromAuth(profile);
    sportsNeoPlayer =
        _isSportsNeoPlayerRole(profile['sportsNeoRole']) ||
        _isSportsNeoPlayerRole(profile['playerRole']);
    final String profileRole = _normalizeRole(profile['role']);
    if (profileRole.isNotEmpty) {
      role = profileRole;
    }
  } catch (_) {
    // Fall back to role from login payload/session.
  }

  if (!context.mounted || role.isEmpty) {
    return false;
  }

  if (sportsNeoPlayer) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SportsNeoDashboardScreen()),
      (Route<dynamic> route) => false,
    );
    return true;
  }

  if (_isAcademyOwnerRole(role)) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AcademyDashboardScreen()),
      (Route<dynamic> route) => false,
    );
    return true;
  }
  if (_isBoxCricketOwnerRole(role)) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const BoxCricketDashboardScreen(),
      ),
      (Route<dynamic> route) => false,
    );
    return true;
  }
  if (_isGroundOwnerRole(role)) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DashboardTurfScreen()),
      (Route<dynamic> route) => false,
    );
    return true;
  }
  if (_isSportsPlayerRole(role)) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SportsNeoDashboardScreen()),
      (Route<dynamic> route) => false,
    );
    return true;
  }

  return false;
}

String _maskEmail(String email) {
  final String trimmed = email.trim();
  final int atIndex = trimmed.indexOf('@');
  if (atIndex <= 1) {
    return trimmed;
  }
  final String prefix = trimmed.substring(0, atIndex);
  final String domain = trimmed.substring(atIndex);
  if (prefix.length <= 4) {
    return '${prefix[0]}****$domain';
  }
  return '${prefix.substring(0, 4)}*****$domain';
}

class SportsNeoWelcomeScreen extends StatelessWidget {
  const SportsNeoWelcomeScreen({super.key});

  void _openGoogleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return const _SportsNeoGoogleSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 382,
                    child: Image.network(
                      'https://api.builder.io/api/v1/image/assets/TEMP/0ac36a8f6291a9c3de9235e028c629d439fba3bd?width=716',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              color: const Color(0xFF141B33),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white70,
                                size: 40,
                              ),
                            );
                          },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.05,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: 'Welcome to\n'),
                      TextSpan(
                        text: 'SportsNeo',
                        style: TextStyle(color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Book Grounds, manage teams and\nplay smarter',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                _PrimaryActionButton(
                  icon: Icons.phone_iphone_outlined,
                  text: 'Continue with Phone Number',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SportsNeoPhoneScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _OutlineActionButton(
                  icon: Icons.g_mobiledata_rounded,
                  text: 'Continue with Google',
                  onPressed: () => _openGoogleSheet(context),
                ),
                const SizedBox(height: 16),
                _OutlineActionButton(
                  icon: null,
                  text: 'Continue as Guest',
                  textColor: const Color(0xFF2563EB),
                  borderColor: const Color(0xFF2563EB),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const SportsNeoDashboardScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SportsNeoPhoneScreen extends StatefulWidget {
  const SportsNeoPhoneScreen({super.key});

  @override
  State<SportsNeoPhoneScreen> createState() => _SportsNeoPhoneScreenState();
}

class _SportsNeoPhoneScreenState extends State<SportsNeoPhoneScreen> {
  bool _acceptedTerms = false;
  final TextEditingController _phoneController = TextEditingController();
  final GroundWaleApi _api = GroundWaleApi.instance;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms and conditions')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final String contactNumber = _phoneController.text.trim();
      bool isExistingUser = true;
      Map<String, dynamic> otpResponse;
      try {
        otpResponse = await _api.sendLoginOtp(contactNumber: contactNumber);
      } catch (_) {
        isExistingUser = false;
        otpResponse = await _api.sendRegisterOtp(
          contactNumber: contactNumber,
          ownerName: 'Sports Neo User',
          role: 'player',
        );
      }
      final String? apiOtp = _extractOtpValue(otpResponse);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SportsNeoOtpScreen(
            contactNumber: contactNumber,
            isExistingUser: isExistingUser,
            apiOtp: apiOtp,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _BackSquareButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 58),
              const _SportsNeoWordmark(large: true),
              const SizedBox(height: 50),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter your phone number',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'We\'ll send you a verification code on the same number.',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Text('🇦🇫', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text(
                          '+93',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: AppTextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        minLines: 1,
                        maxLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your phone number',
                          hintStyle: TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() => _acceptedTerms = !_acceptedTerms);
                    },
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white),
                        color: _acceptedTerms
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                      ),
                      child: _acceptedTerms
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: 'If you continue, you are accepting ',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text:
                                'SportsNeo Terms & Conditions and Prvacy Policy.',
                            style: TextStyle(color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _PrimaryActionButton(
                icon: null,
                text: 'Next',
                onPressed: _isSubmitting ? () {} : _sendOtp,
                loading: _isSubmitting,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext sheetContext) {
                      return const _SportsNeoGoogleSheet();
                    },
                  );
                },
                child: const Text(
                  'Login with Google',
                  style: TextStyle(
                    color: Color(0xFF6593F9),
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SportsNeoOtpScreen extends StatefulWidget {
  const SportsNeoOtpScreen({
    super.key,
    required this.contactNumber,
    this.isExistingUser = true,
    this.apiOtp,
  });

  final String contactNumber;
  final bool isExistingUser;
  final String? apiOtp;

  @override
  State<SportsNeoOtpScreen> createState() => _SportsNeoOtpScreenState();
}

class _SportsNeoOtpScreenState extends State<SportsNeoOtpScreen> {
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  final GroundWaleApi _api = GroundWaleApi.instance;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _otpControllers = List<TextEditingController>.generate(
      4,
      (_) => TextEditingController(),
    );
    _otpFocusNodes = List<FocusNode>.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _otpControllers) {
      controller.dispose();
    }
    for (final FocusNode node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpValue => _otpControllers
      .map((TextEditingController controller) => controller.text)
      .join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _BackSquareButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 58),
              const _SportsNeoWordmark(large: true),
              const SizedBox(height: 44),
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'ve sent a verification code to',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (widget.apiOtp != null && widget.apiOtp!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'OTP: ${widget.apiOtp}',
                  style: const TextStyle(
                    color: Color(0xFF6593F9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(4, (int index) {
                  return Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white),
                    ),
                    child: AppTextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.26,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                      ),
                      maxLength: 1,
                      onChanged: (String value) {
                        if (value.isNotEmpty && index < 3) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _otpFocusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              _PrimaryActionButton(
                icon: null,
                text: 'Verify & Continue',
                loading: _isVerifying,
                onPressed: _isVerifying
                    ? () {}
                    : () async {
                        if (_otpValue.length != 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter 4 digit OTP'),
                            ),
                          );
                          return;
                        }

                        setState(() => _isVerifying = true);
                        try {
                          final Map<String, dynamic> response = await _api
                              .verifyOtp(
                                contactNumber: widget.contactNumber,
                                otp: _otpValue,
                              );
                          final Map<String, dynamic> user = _extractUser(
                            response,
                          );
                          ApiSession.instance.updateFromAuth(user);
                          final bool routed = widget.isExistingUser
                              ? await _routeExistingUserToDashboard(
                                  context,
                                  _api,
                                )
                              : false;
                          if (routed || !context.mounted) {
                            return;
                          }
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SportsNeoCompleteProfileScreen(
                                prefillEmail: user['email']?.toString(),
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isVerifying = false);
                          }
                        }
                      },
              ),
              const SizedBox(height: 20),
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  children: <InlineSpan>[
                    TextSpan(text: 'Didn\'t receive code? '),
                    TextSpan(
                      text: 'Resend',
                      style: TextStyle(color: Color(0xFF6593F9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  children: <InlineSpan>[
                    TextSpan(text: 'Code expires in '),
                    TextSpan(
                      text: '03:00',
                      style: TextStyle(color: Color(0xFF6593F9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SportsNeoCompleteProfileScreen extends StatefulWidget {
  const SportsNeoCompleteProfileScreen({super.key, this.prefillEmail});

  final String? prefillEmail;

  @override
  State<SportsNeoCompleteProfileScreen> createState() =>
      _SportsNeoCompleteProfileScreenState();
}

class _SportsNeoCompleteProfileScreenState
    extends State<SportsNeoCompleteProfileScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _sportsController = TextEditingController(
    text: 'Cricket',
  );
  final TextEditingController _cityController = TextEditingController();
  String _selectedRole = 'Player';
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _sportsController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _BackSquareButton(onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  const Text(
                    'Step 2/2',
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: <Widget>[
                    Text(
                      'Profile Photo (Optional)',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),
                    _AddPhotoCircle(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Who are you?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.18,
                children: <Widget>[
                  _RoleCard(
                    emoji: '🏏',
                    title: 'Player',
                    subtitle: 'Join matches & book\ngrounds',
                    selected: _selectedRole == 'Player',
                    onTap: () => setState(() => _selectedRole = 'Player'),
                  ),
                  _RoleCard(
                    emoji: '👨‍✈️',
                    title: 'Captain',
                    subtitle: 'Manage teams &\nschedules',
                    selected: _selectedRole == 'Captain',
                    onTap: () => setState(() => _selectedRole = 'Captain'),
                  ),
                  _RoleCard(
                    emoji: '🎓',
                    title: 'Academy',
                    subtitle: 'Track attendance &\ntraining',
                    selected: _selectedRole == 'Academy',
                    onTap: () => setState(() => _selectedRole = 'Academy'),
                  ),
                  _RoleCard(
                    emoji: '🏟️',
                    title: 'Owner',
                    subtitle: 'Manage slots &\nbookings',
                    selected: _selectedRole == 'Owner',
                    onTap: () => setState(() => _selectedRole = 'Owner'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Full Name'),
              const SizedBox(height: 8),
              _InputLikeField(
                'Enter your full name',
                controller: _fullNameController,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Date of Birth'),
              const SizedBox(height: 8),
              _InputLikeField(
                'Enter your DOB',
                controller: _dobController,
                trailing: Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0x99FFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Choose Your Sports'),
              const SizedBox(height: 8),
              _InputLikeField(
                'Cricket',
                controller: _sportsController,
                trailing: Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0x99FFFFFF),
                  size: 24,
                ),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('City'),
              const SizedBox(height: 8),
              _InputLikeField(
                'Search your city',
                controller: _cityController,
                trailing: Icon(
                  Icons.location_on_outlined,
                  color: Color(0x66FFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(height: 24),
              _PrimaryActionButton(
                icon: null,
                text: 'Continue',
                loading: _isSaving,
                onPressed: _isSaving
                    ? () {}
                    : () async {
                        if (_fullNameController.text.trim().isEmpty ||
                            _dobController.text.trim().isEmpty ||
                            _cityController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                            ),
                          );
                          return;
                        }

                        if (ApiSession.instance.ownerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Session expired. Please login again.',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => _isSaving = true);
                        try {
                          final bool isPlayerLike =
                              _selectedRole == 'Player' ||
                              _selectedRole == 'Captain';
                          final Map<String, dynamic> payload = <String, dynamic>{
                            'ownerName': _fullNameController.text.trim(),
                            'email': widget.prefillEmail,
                            'address': _cityController.text.trim(),
                            'sports': _sportsController.text.trim(),
                            'dob': _dobController.text.trim(),
                            'sportsNeoRole': _selectedRole.toLowerCase(),
                            if (isPlayerLike) 'role': 'player',
                            if (isPlayerLike)
                              'isCaptain': _selectedRole == 'Captain',
                          };
                          await _api.updateOwnerProfile(
                            ApiSession.instance.ownerId!,
                            payload,
                          );
                          if (!context.mounted) {
                            return;
                          }

                          if (isPlayerLike) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SportsNeoLocationScreen(),
                              ),
                            );
                            return;
                          }

                          final GroundFlowController flowController =
                              GroundFlowController();
                          flowController.data.ownerName = _fullNameController
                              .text
                              .trim();
                          flowController.data.contactNumber =
                              ApiSession.instance.contactNumber ?? '';
                          flowController.data.email =
                              widget.prefillEmail?.trim() ?? '';
                          flowController.data.address = _cityController.text
                              .trim();
                          flowController.data.city = _cityController.text
                              .trim();
                          flowController.data.role = UserRole.owner;
                          flowController.data.otpVerified = true;

                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RegisterGroundFlowScreen(
                                initialController: flowController,
                                initialStep: 2,
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isSaving = false);
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportsNeoWordmark extends StatelessWidget {
  const _SportsNeoWordmark({this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    if (large) {
      return SizedBox(
        width: 281,
        height: 250,
        child: Column(
          children: <Widget>[
            Image.asset(
              'assets/images/sport-neo-logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return const Icon(
                      Icons.sports,
                      color: Colors.white,
                      size: 126,
                    );
                  },
            ),
          ],
        ),
      );
    }

    return Image.asset(
      'assets/images/sport-neo-logo.png',
      width: 80,
      height: 71,
      fit: BoxFit.contain,
    );
  }
}

class _BackSquareButton extends StatelessWidget {
  const _BackSquareButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x0AFFFFFF),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (loading) ...<Widget>[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
            ],
            if (icon != null) ...<Widget>[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.textColor = Colors.white,
    this.borderColor = const Color(0xFF2563EB),
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : const Color(0x1AFFFFFF),
          ),
          color: selected ? const Color(0x143B82F6) : const Color(0x0AFFFFFF),
          boxShadow: selected
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x263B82F6),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
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
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            if (selected)
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xCCFFFFFF),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _InputLikeField extends StatelessWidget {
  const _InputLikeField(this.text, {this.trailing, this.controller});

  final String text;
  final Widget? trailing;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        color: const Color(0x0AFFFFFF),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: AppTextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: text,
                hintStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _AddPhotoCircle extends StatelessWidget {
  const _AddPhotoCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: const Color(0x33FFFFFF),
          width: 2,
          style: BorderStyle.solid,
        ),
        color: const Color(0x05FFFFFF),
      ),
      child: const Icon(Icons.add, color: Color(0x66FFFFFF), size: 24),
    );
  }
}

class SportsNeoEmailLoginScreen extends StatefulWidget {
  const SportsNeoEmailLoginScreen({super.key});

  @override
  State<SportsNeoEmailLoginScreen> createState() =>
      _SportsNeoEmailLoginScreenState();
}

class _SportsNeoEmailLoginScreenState extends State<SportsNeoEmailLoginScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _BackSquareButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 58),
              const _SportsNeoWordmark(large: true),
              const SizedBox(height: 42),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter your Email to login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 52,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x3DFFFFFF)),
                ),
                child: AppTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your email id',
                    hintStyle: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'If you are a new user please choose any other login option from previous page.',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _PrimaryActionButton(
                icon: null,
                text: 'Next',
                loading: _isLoading,
                onPressed: _isLoading
                    ? () {}
                    : () async {
                        if (_emailController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your email'),
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        try {
                          await _api.loginWithEmail(
                            email: _emailController.text.trim(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SportsNeoPasswordScreen(
                                email: _emailController.text.trim(),
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Text(
                  'Login with Phone',
                  style: TextStyle(
                    color: Color(0xFF6593F9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Need help?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SportsNeoPasswordScreen extends StatefulWidget {
  const SportsNeoPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<SportsNeoPasswordScreen> createState() =>
      _SportsNeoPasswordScreenState();
}

class _SportsNeoPasswordScreenState extends State<SportsNeoPasswordScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _BackSquareButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 58),
              const _SportsNeoWordmark(large: true),
              const SizedBox(height: 42),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter your password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xCCFFFFFF),
                    ),
                    children: <InlineSpan>[
                      const TextSpan(text: 'Welcome back '),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 52,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x3DFFFFFF)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: Color(0xB3FFFFFF)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'If you are a new user please choose any other login option from previous page.',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PrimaryActionButton(
                icon: null,
                text: 'Next',
                loading: _isLoading,
                onPressed: _isLoading
                    ? () {}
                    : () async {
                        if (_passwordController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter password'),
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        try {
                          final Map<String, dynamic> response = await _api
                              .loginWithPassword(
                                email: widget.email,
                                password: _passwordController.text,
                              );
                          final Map<String, dynamic> user = _extractUser(
                            response,
                          );
                          ApiSession.instance.updateFromAuth(user);
                          final bool routed =
                              await _routeExistingUserToDashboard(
                                context,
                                _api,
                              );
                          if (routed || !context.mounted) {
                            return;
                          }
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SportsNeoCompleteProfileScreen(
                                prefillEmail: widget.email,
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext sheetContext) {
                      return _SportsNeoForgotPasswordSheet(email: widget.email);
                    },
                  );
                },
                child: const Text(
                  'Forget password',
                  style: TextStyle(
                    color: Color(0xFF6593F9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportsNeoGoogleSheet extends StatefulWidget {
  const _SportsNeoGoogleSheet();

  @override
  State<_SportsNeoGoogleSheet> createState() => _SportsNeoGoogleSheetState();
}

class _SportsNeoGoogleSheetState extends State<_SportsNeoGoogleSheet> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  bool _isLoading = false;

  Future<void> _continueWithGoogle(String email) async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> response = await _api.googleLogin(
        email: email,
      );
      final Map<String, dynamic> user = _extractUser(response);
      ApiSession.instance.updateFromAuth(user);
      final bool routed = await _routeExistingUserToDashboard(context, _api);
      if (routed || !context.mounted) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SportsNeoCompleteProfileScreen(prefillEmail: email),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Continue with',
            style: TextStyle(color: Color(0xFF242424), fontSize: 16),
          ),
          const SizedBox(height: 12),
          _GoogleAccountTile(
            email: 'omninos@gmail.com',
            onTap: _isLoading
                ? null
                : () => _continueWithGoogle('omninos@gmail.com'),
          ),
          const SizedBox(height: 10),
          _GoogleAccountTile(
            email: 'omninos12@gmail.com',
            onTap: _isLoading
                ? null
                : () => _continueWithGoogle('omninos12@gmail.com'),
          ),
          const SizedBox(height: 10),
          _GoogleAccountTile(
            email: 'Use another account',
            leadingPlus: true,
            onTap: _isLoading
                ? null
                : () => _continueWithGoogle('newuser@sportsneo.app'),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SportsNeoEmailLoginScreen(),
                ),
              );
            },
            child: const Text(
              'None of the above',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleAccountTile extends StatelessWidget {
  const _GoogleAccountTile({
    required this.email,
    required this.onTap,
    this.leadingPlus = false,
  });

  final String email;
  final VoidCallback? onTap;
  final bool leadingPlus;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1F121212)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: leadingPlus
                    ? const Color(0xFFEE7520)
                    : const Color(0xFFE8EAED),
              ),
              alignment: Alignment.center,
              child: leadingPlus
                  ? const Icon(Icons.add, size: 14, color: Colors.white)
                  : const Icon(
                      Icons.person,
                      size: 14,
                      color: Color(0xFF5F6368),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                email,
                style: const TextStyle(
                  color: Color(0xB3242424),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
          ],
        ),
      ),
    );
  }
}

class _SportsNeoForgotPasswordSheet extends StatefulWidget {
  const _SportsNeoForgotPasswordSheet({required this.email});

  final String email;

  @override
  State<_SportsNeoForgotPasswordSheet> createState() =>
      _SportsNeoForgotPasswordSheetState();
}

class _SportsNeoForgotPasswordSheetState
    extends State<_SportsNeoForgotPasswordSheet> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  late final TextEditingController _emailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = _emailController.text.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Forget Password',
            style: TextStyle(
              color: Color(0xFF242424),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please enter your email to reset the password',
            style: TextStyle(
              color: Color(0x99242424),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Email',
              style: TextStyle(
                color: Color(0xFF242424),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x1F242424)),
            ),
            child: AppTextField(
              controller: _emailController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Enter email',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled
                    ? const Color(0xFF2563EB)
                    : const Color(0x802563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: !enabled || _isSubmitting
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      try {
                        await _api.requestPasswordReset(
                          email: _emailController.text.trim(),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        final NavigatorState navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute<void>(
                            builder: (_) => SportsNeoResetPasswordOtpScreen(
                              email: _emailController.text.trim(),
                            ),
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isSubmitting = false);
                        }
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Reset password',
                      style: TextStyle(
                        color: enabled ? Colors.white : const Color(0x80FFFFFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class SportsNeoResetPasswordOtpScreen extends StatefulWidget {
  const SportsNeoResetPasswordOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<SportsNeoResetPasswordOtpScreen> createState() =>
      _SportsNeoResetPasswordOtpScreenState();
}

class _SportsNeoResetPasswordOtpScreenState
    extends State<SportsNeoResetPasswordOtpScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  bool _isSubmitting = false;

  String get _otpValue => _otpControllers
      .map((TextEditingController controller) => controller.text)
      .join();

  @override
  void initState() {
    super.initState();
    _otpControllers = List<TextEditingController>.generate(
      4,
      (_) => TextEditingController(),
    );
    _otpFocusNodes = List<FocusNode>.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _otpControllers) {
      controller.dispose();
    }
    for (final FocusNode node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmOtp() async {
    if (_otpValue.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter 4 digit OTP')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.verifyPasswordResetOtp(email: widget.email, otp: _otpValue);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SportsNeoSetNewPasswordScreen(email: widget.email),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            _PasswordBackdrop(email: widget.email),
            Container(color: Colors.black.withValues(alpha: 0.5)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 540),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  border: Border(top: BorderSide(color: Color(0xFF242424))),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _BackSquareButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please enter the OTP sent to your email ${_maskEmail(widget.email)}',
                        style: const TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(4, (int index) {
                          return Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF242424),
                              ),
                            ),
                            child: AppTextField(
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                color: Color(0xFF242424),
                                fontFamily: 'Lato',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.26,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                isDense: true,
                              ),
                              onChanged: (String value) {
                                if (value.isNotEmpty && index < 3) {
                                  _otpFocusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _otpFocusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          '00:28 seconds remaining',
                          style: TextStyle(
                            color: Color(0xFFEB3239),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Having trouble in receiving your OTP',
                        style: TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0x192563EB),
                        ),
                        child: const Text(
                          'Please check your cellular network. OTP will not be received if you face network connectivity issue.',
                          style: TextStyle(
                            color: Color(0x80242424),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _confirmOtp,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Confirm OTP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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

class SportsNeoSetNewPasswordScreen extends StatefulWidget {
  const SportsNeoSetNewPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<SportsNeoSetNewPasswordScreen> createState() =>
      _SportsNeoSetNewPasswordScreenState();
}

class _SportsNeoSetNewPasswordScreenState
    extends State<SportsNeoSetNewPasswordScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.updatePasswordWithOtp(
        email: widget.email,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return _SportsNeoPasswordUpdatedDialog(
            onLoginNow: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const SportsNeoEmailLoginScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            },
          );
        },
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF242424),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1F121212)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: AppTextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(
                    color: Color(0xFF242424),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0x66242424),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            _PasswordBackdrop(email: widget.email),
            Container(color: Colors.black.withValues(alpha: 0.5)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 440),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  border: Border(top: BorderSide(color: Color(0xFF242424))),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _BackSquareButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Set a new password',
                        style: TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create a strong password to protect your wealth.',
                        style: TextStyle(
                          color: Color(0x99242424),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _passwordField(
                        label: 'Password',
                        controller: _passwordController,
                        obscure: _hidePassword,
                        onToggle: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Must include A-Z, 0-9, and Special Characters.',
                        style: TextStyle(
                          color: Color(0x99242424),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        obscure: _hideConfirmPassword,
                        onToggle: () => setState(
                          () => _hideConfirmPassword = !_hideConfirmPassword,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _updatePassword,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Update Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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

class _SportsNeoPasswordUpdatedDialog extends StatelessWidget {
  const _SportsNeoPasswordUpdatedDialog({required this.onLoginNow});

  final VoidCallback onLoginNow;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 358,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF2563EB),
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Password Updated Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF242424),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your password has been changed. You can now log in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0x80242424),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onLoginNow,
                child: const Text(
                  'Login Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class _PasswordBackdrop extends StatelessWidget {
  const _PasswordBackdrop({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _BackSquareButton(onTap: () => Navigator.of(context).maybePop()),
            ],
          ),
          const SizedBox(height: 58),
          const _SportsNeoWordmark(large: true),
          const SizedBox(height: 42),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enter your password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF)),
                children: <InlineSpan>[
                  const TextSpan(text: 'Welcome back '),
                  TextSpan(
                    text: email,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x3DFFFFFF)),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'If you are a new user please choose any other login option from previous page.',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SportsNeoLocationScreen extends StatefulWidget {
  const SportsNeoLocationScreen({super.key});

  @override
  State<SportsNeoLocationScreen> createState() =>
      _SportsNeoLocationScreenState();
}

class _SportsNeoLocationScreenState extends State<SportsNeoLocationScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  bool _showPermissionSheet = false;
  bool _isSaving = false;

  Future<void> _saveLocation(String value) async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _api.updateOwnerProfile(ownerId, <String, dynamic>{
        'mapLocation': value,
        'role': 'player',
      });
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const SportsNeoDashboardScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!context.mounted) {
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

  Widget _locationGlyph() {
    return SizedBox(
      width: 122,
      height: 122,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 122,
            height: 122,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1F2563EB),
            ),
          ),
          Container(
            width: 93,
            height: 93,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x522563EB),
            ),
          ),
          const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 42),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 162),
                  const _SportsNeoWordmark(large: true),
                  const SizedBox(height: 32),
                  _locationGlyph(),
                  const SizedBox(height: 24),
                  const Text(
                    'Where is your location?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enjoy a personalized selling and buying experience by telling us your location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PrimaryActionButton(
                    icon: null,
                    text: 'Find My Location',
                    loading: _isSaving,
                    onPressed: _isSaving
                        ? () {}
                        : () => setState(() => _showPermissionSheet = true),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isSaving ? null : () => _saveLocation('other'),
                    child: const Text(
                      'Other location',
                      style: TextStyle(
                        color: Color(0xFF6593F9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showPermissionSheet) ...<Widget>[
              Container(color: Colors.black.withValues(alpha: 0.5)),
              Center(
                child: Container(
                  width: 358,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      top: BorderSide(color: Color(0xFF242424)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _locationGlyph(),
                      const SizedBox(height: 16),
                      const Text(
                        'Allow Afghan Deals to access this device\'s location',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This app will be able to access your device location for security and personalized services.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xCC242424),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(() => _showPermissionSheet = false);
                                  _saveLocation('device_location');
                                },
                          child: const Text(
                            'Allow',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x3D242424)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isSaving
                              ? null
                              : () => setState(
                                  () => _showPermissionSheet = false,
                                ),
                          child: const Text(
                            'Deny',
                            style: TextStyle(
                              color: Color(0xCC242424),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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


