import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/widgets/module_bottom_nav.dart';

import 'academy_communication_settings_screen.dart';
import 'academy_announcement_screen.dart';
import 'academy_change_password_screen.dart';
import 'academy_batch_timings_screen.dart';
import 'academy_dashboard_screen.dart';
import 'academy_contact_support_screen.dart';
import 'academy_edit_academy_info_screen.dart';
import 'academy_edit_profile_screen.dart';
import 'academy_fee_structure_screen.dart';
import 'academy_help_faq_screen.dart';
import 'academy_language_screen.dart';
import 'academy_legal_screen.dart';
import 'academy_notification_settings_screen.dart';
import 'academy_payment_methods_screen.dart';
import '../../sports_neo/home/sports_neo_onboarding_flow.dart';

class AcademyProfileScreen extends StatefulWidget {
  const AcademyProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<AcademyProfileScreen> createState() => _AcademyProfileScreenState();
}

class _AcademyProfileScreenState extends State<AcademyProfileScreen> {
  bool _isLoadingAcademyInfo = true;
  String _academyName = 'Omninos Academy';
  String _academyAddress = 'Sector 118, Mohali near flower shop, airport road';
  String _academyPhone = '011-23456789';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadAcademyInfo();
  }

  Future<void> _loadAcademyInfo() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoadingAcademyInfo = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> profile = await GroundWaleApi.instance
          .getOwnerProfile(ownerId);
      if (!mounted) {
        return;
      }

      final String academyName =
          profile['academyName']?.toString().trim().isNotEmpty == true
          ? profile['academyName'].toString().trim()
          : profile['ownerName']?.toString().trim().isNotEmpty == true
          ? profile['ownerName'].toString().trim()
          : _academyName;

      final String academyAddress =
          profile['address']?.toString().trim().isNotEmpty == true
          ? profile['address'].toString().trim()
          : _academyAddress;

      final String academyPhone =
          profile['contactNumber']?.toString().trim().isNotEmpty == true
          ? profile['contactNumber'].toString().trim()
          : profile['phone']?.toString().trim().isNotEmpty == true
          ? profile['phone'].toString().trim()
          : _academyPhone;

      setState(() {
        _academyName = academyName;
        _academyAddress = academyAddress;
        _academyPhone = academyPhone;
        _isLoadingAcademyInfo = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAcademyInfo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Center(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: Color(0xFFE6F7F4),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Center(child: _ProfileHeaderCard()),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Academy Info',
                      trailing: GestureDetector(
                        onTap: () async {
                          final bool? changed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (_) =>
                                      const AcademyEditAcademyInfoScreen(),
                                ),
                              );
                          if (changed == true) {
                            await _loadAcademyInfo();
                          }
                        },
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Color(0xFF00C9A7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      child: _InfoPanel(
                        academyName: _academyName,
                        address: _academyAddress,
                        phone: _academyPhone,
                        isLoading: _isLoadingAcademyInfo,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Account Settings',
                      child: _ListPanel(
                        items: <_SettingItemData>[
                          _SettingItemData(
                            title: 'Edit Profile',
                            icon: Icons.person_outline_rounded,
                            iconBg: Color(0x1F00C9A7),
                            iconColor: Color(0xFF00C9A7),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyEditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingItemData(
                            title: 'Change Password',
                            icon: Icons.lock_outline_rounded,
                            iconBg: Color(0x1F00C9A7),
                            iconColor: Color(0xFF00C9A7),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingItemData(
                            title: 'Notification Settings',
                            icon: Icons.notifications_none_rounded,
                            iconBg: Color(0x1F00C9A7),
                            iconColor: Color(0xFF00C9A7),
                            showDivider: false,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyNotificationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Business Settings',
                      child: _ListPanel(
                        items: <_SettingItemData>[
                          _SettingItemData(
                            title: 'Fees Structure',
                            icon: Icons.currency_rupee_rounded,
                            iconBg: Color(0x267EE7B6),
                            iconColor: Color(0xFF052017),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyFeeStructureScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingItemData(
                            title: 'Batch Timings',
                            icon: Icons.schedule_rounded,
                            iconBg: Color(0x267EE7B6),
                            iconColor: Color(0xFF052017),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyBatchTimingsScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingItemData(
                            title: 'Payment Methods',
                            icon: Icons.credit_card_rounded,
                            iconBg: Color(0x267EE7B6),
                            iconColor: Color(0xFF052017),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyPaymentMethodsScreen(),
                                ),
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'App Settings',
                      child: _ListPanel(
                        items: <_SettingItemData>[
                          _SettingItemData(
                            title: 'Dark Mode',
                            icon: Icons.dark_mode_outlined,
                            iconBg: Color(0x8012252B),
                            iconColor: Color(0xFFE6F7F4),
                            trailingKind: _TrailingKind.switchOn,
                          ),
                          _SettingItemData(
                            title: 'Language',
                            icon: Icons.public_rounded,
                            iconBg: Color(0x8012252B),
                            iconColor: Color(0xFFE6F7F4),
                            trailingKind: _TrailingKind.textChevron,
                            trailingText: 'English',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AcademyLanguageScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingItemData(
                            title: 'WhatsApp & SMS Prefs',
                            icon: Icons.chat_bubble_outline_rounded,
                            iconBg: Color(0x8012252B),
                            iconColor: Color(0xFFE6F7F4),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyCommunicationSettingsScreen(),
                                ),
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Support & Help',
                      child: _ListPanel(
                        items: <_SettingItemData>[
                          _SettingItemData(
                            title: 'Help / FAQ',
                            icon: Icons.help_outline_rounded,
                            iconBg: Color(0xCC203A43),
                            iconColor: Color(0xFFDFF7F0),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AcademyHelpFaqScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingItemData(
                            title: 'Contact Support',
                            icon: Icons.support_agent_rounded,
                            iconBg: Color(0xCC203A43),
                            iconColor: Color(0xFFDFF7F0),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyContactSupportScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingItemData(
                            title: 'Terms & Privacy Policy',
                            icon: Icons.verified_user_outlined,
                            iconBg: Color(0xCC203A43),
                            iconColor: Color(0xFFDFF7F0),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AcademyLegalScreen(),
                                ),
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LogoutButton(onTap: () => _showLogoutDialog(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? ModuleBottomNav(
        currentIndex: 2,
        activeColor: const Color(0xFF00C9A7),
        inactiveColor: const Color(0xFF9FB9B3),
        backgroundColor: const Color(0x0FFFFFFF),
        borderColor: const Color(0x1FFFFFFF),
        horizontalPadding: 22,
        bottomPadding: 20,
        items: <ModuleBottomNavItem>[
          ModuleBottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () => Navigator.of(context).pop(),
          ),
          ModuleBottomNavItem(
            icon: Icons.campaign_outlined,
            label: 'Announcement',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AcademyAnnouncementScreen(
                    onHomeTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const AcademyDashboardScreen(),
                        ),
                        (Route<dynamic> route) => route.isFirst,
                      );
                    },
                    onProfileTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              );
            },
          ),
          ModuleBottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () {},
          ),
        ],
      )
          : null,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x99242424),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: 358,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0x1FDE501C),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDE501C),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0A2E4E),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to logout',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4F5D73),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDD3D21)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text(
                          'No',
                          style: TextStyle(
                            color: Color(0xFFDD3D21),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoggingOut
                            ? null
                            : () async {
                                Navigator.of(dialogContext).pop();
                                await _logout();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF08B36A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(44),
                          elevation: 0,
                        ),
                        child: _isLoggingOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Yes',
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await GroundWaleApi.instance.logout();
    } catch (_) {
      // Continue with local logout even if remote logout fails.
    }

    ApiSession.instance.clear();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const SportsNeoWelcomeScreen(),
      ),
      (Route<dynamic> route) => false,
    );

    if (mounted) {
      setState(() => _isLoggingOut = false);
    }
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x0FFFFFFF), width: 3),
                color: const Color(0xFF203A43),
              ),
              alignment: Alignment.center,
              child: const Text(
                'AK',
                style: TextStyle(
                  color: Color(0xFFE6F7F4),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9A7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0F2027), width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Akash',
          style: TextStyle(
            color: Color(0xFFE6F7F4),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x2600C9A7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Coach / Admin',
            style: TextStyle(
              color: Color(0xFF00C9A7),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '+91 98765 43210  •  akash@cricketturf.com',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9FB9B3),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE6F7F4),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.academyName,
    required this.address,
    required this.phone,
    required this.isLoading,
  });

  final String academyName;
  final String address;
  final String phone;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x267EE7B6),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF052017),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  academyName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE6F7F4),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00C9A7),
                  ),
                ),
              ),
            ),
          _InfoRow(icon: Icons.location_on_outlined, text: address),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.call_outlined, text: phone),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: const Color(0xFF9FB9B3), size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF9FB9B3),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

enum _TrailingKind { chevron, textChevron, switchOn }

class _SettingItemData {
  const _SettingItemData({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.trailingKind = _TrailingKind.chevron,
    this.trailingText,
    this.showDivider = true,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final _TrailingKind trailingKind;
  final String? trailingText;
  final bool showDivider;
  final VoidCallback? onTap;
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.items});

  final List<_SettingItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: items.map((item) => _SettingListItem(data: item)).toList(),
      ),
    );
  }
}

class _SettingListItem extends StatelessWidget {
  const _SettingListItem({required this.data});

  final _SettingItemData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: data.showDivider
            ? const Border(bottom: BorderSide(color: Color(0x0A000000)))
            : null,
      ),
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(data.icon, color: data.iconColor, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFFE6F7F4),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _TrailingWidget(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailingWidget extends StatelessWidget {
  const _TrailingWidget({required this.data});

  final _SettingItemData data;

  @override
  Widget build(BuildContext context) {
    switch (data.trailingKind) {
      case _TrailingKind.switchOn:
        return Container(
          width: 44,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF00C9A7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case _TrailingKind.textChevron:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              data.trailingText ?? '',
              style: const TextStyle(
                color: Color(0xFF9FB9B3),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9FB9B3),
              size: 20,
            ),
          ],
        );
      case _TrailingKind.chevron:
        return const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9FB9B3),
          size: 20,
        );
    }
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x80EF4444)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
