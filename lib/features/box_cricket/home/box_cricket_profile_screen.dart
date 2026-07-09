import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../sports_neo/home/sports_neo_onboarding_flow.dart';
import 'box_cricket_bank_account_screen.dart';
import 'box_cricket_bottom_nav.dart';
import 'box_cricket_dashboard_screen.dart';
import 'box_cricket_earning_screen.dart';
import 'box_cricket_edit_ground_screen.dart';
import 'box_cricket_help_support_screen.dart';
import 'box_cricket_edit_profile_screen.dart';
import 'box_cricket_manage_slots_screen.dart';
import 'box_cricket_notification_screen.dart';
import 'box_cricket_payment_settings_screen.dart';
import 'box_cricket_pricing_charges_screen.dart';
import 'box_cricket_reports_earnings_screen.dart';
import 'box_cricket_terms_policy_screen.dart';
import 'box_cricket_upcoming_bookings_screen.dart';

class BoxCricketProfileScreen extends StatefulWidget {
  const BoxCricketProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<BoxCricketProfileScreen> createState() =>
      _BoxCricketProfileScreenState();
}

class _BoxCricketProfileScreenState extends State<BoxCricketProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profile = <String, dynamic>{};
  Map<String, dynamic> _ground = <String, dynamic>{};
  Map<String, dynamic> _bankAccount = <String, dynamic>{};

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
    final ApiSession session = ApiSession.instance;
    final String? ownerId = session.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> profile = await GroundWaleApi.instance
          .getOwnerProfile(ownerId);
      final String? groundId = await _resolveGroundId();

      Map<String, dynamic> ground = <String, dynamic>{};
      if (groundId != null && groundId.isNotEmpty) {
        try {
          ground = await GroundWaleApi.instance.getGround(groundId);
        } catch (_) {
          ground = <String, dynamic>{};
        }
      }

      Map<String, dynamic> bankAccount = <String, dynamic>{};
      try {
        final Map<String, dynamic> bankResponse = await GroundWaleApi.instance
            .getBankAccount(ownerId);
        bankAccount = Map<String, dynamic>.from(
          bankResponse['bankAccount'] as Map? ?? bankResponse,
        );
      } catch (_) {
        bankAccount = <String, dynamic>{};
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
        _ground = ground;
        _bankAccount = bankAccount;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String _bankSubtitle() {
    final String bankName = _bankAccount['bankName']?.toString().trim() ?? '';
    final String account =
        _bankAccount['accountNumber']?.toString().trim() ?? '';
    String suffix = '';
    if (account.isNotEmpty) {
      suffix = account.length >= 4
          ? account.substring(account.length - 4)
          : account;
    }
    if (bankName.isNotEmpty && suffix.isNotEmpty) {
      return '$bankName....$suffix linked';
    }
    if (bankName.isNotEmpty) {
      return '$bankName linked';
    }
    return 'No bank account linked';
  }

  Future<void> _openEditProfile() async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const BoxCricketEditProfileScreen(),
      ),
    );
    if (updated == true) {
      await _load();
    }
  }

  Future<void> _openEditGround() async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const BoxCricketEditGroundScreen(),
      ),
    );
    if (updated == true) {
      await _load();
    }
  }

  Future<void> _performLogout() async {
    try {
      await GroundWaleApi.instance.logout();
    } catch (_) {
      // Continue with local session clear even when API logout fails.
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
  }

  Future<void> _showLogoutConfirmDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 358,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0x1FDE501C),
                    shape: BoxShape.circle,
                  ),
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
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to logout',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4F5D73),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
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
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _performLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF08B36A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final String ownerName =
        _profile['ownerName']?.toString().trim().isNotEmpty == true
        ? _profile['ownerName'].toString().trim()
        : (ApiSession.instance.ownerName ?? 'Owner');
    final String contact =
        _profile['contactNumber']?.toString() ??
        ApiSession.instance.contactNumber ??
        '';

    final String groundName =
        _ground['groundName']?.toString().trim().isNotEmpty == true
        ? _ground['groundName'].toString().trim()
        : 'Box Cricket Arena';
    final String groundSubtitle =
        _ground['location']?.toString().trim().isNotEmpty == true
        ? _ground['location'].toString().trim()
        : (_ground['address']?.toString() ?? 'No location added');

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF08B36A),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: <Widget>[
                    _HeaderCard(
                      ownerName: ownerName,
                      contactNumber: contact,
                      onEditTap: _openEditProfile,
                    ),
                    const SizedBox(height: 16),
                    _GroundCard(
                      groundName: groundName,
                      subtitle: groundSubtitle,
                      onEditTap: _openEditGround,
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(text: 'Earning & Payout'),
                    _GroupCard(
                      outlined: false,
                      children: <Widget>[
                        _IconMenuTile(
                          title: 'Wallet / Earnings',
                          subtitle: 'Check balance, payouts and transactions',
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const BoxCricketEarningScreen(),
                              ),
                            );
                          },
                        ),
                        _line(),
                        _IconMenuTile(
                          title: 'Bank Account',
                          subtitle: _bankSubtitle(),
                          icon: Icons.account_balance_outlined,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketBankAccountScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(text: 'Settings'),
                    _GroupCard(
                      outlined: true,
                      children: <Widget>[
                        _MenuTile(
                          title: 'Manage Slots',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketManageSlotsScreen(),
                              ),
                            );
                          },
                        ),
                        _line(),
                        _MenuTile(
                          title: 'Pricing & Charges',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketPricingChargesScreen(),
                              ),
                            );
                          },
                        ),
                        _line(),
                        _MenuTile(
                          title: 'Payment Settings',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketPaymentSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _line(),
                        _MenuTile(
                          title: 'Notification',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketNotificationScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(text: 'Reports'),
                    _GroupCard(
                      outlined: true,
                      children: <Widget>[
                        _MenuTile(
                          title: 'Reports & Earnings',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketReportsEarningsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(text: 'Support & Help'),
                    _GroupCard(
                      outlined: true,
                      children: <Widget>[
                        _MenuTile(
                          title: 'Help & Support',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketHelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                        _line(),
                        _MenuTile(
                          title: 'Terms & Policies',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const BoxCricketTermsPolicyScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showLogoutConfirmDialog,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDB1F1F)),
                          color: const Color(0x08DB1F1F),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFDB1F1F),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Color(0xFFDB1F1F),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BoxCricketBottomNav(
        currentIndex: 3,
        onHome: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketDashboardScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        },
        onAnnouncement: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketUpcomingBookingsScreen(),
            ),
          );
        },
        onSlots: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoxCricketManageSlotsScreen(),
            ),
          );
        },
        onProfile: () {},
      )
          : null,
    );
  }

  Widget _line() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      height: 1,
      color: const Color(0x33FFFFFF),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.ownerName,
    required this.contactNumber,
    required this.onEditTap,
  });

  final String ownerName;
  final String contactNumber;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 194,
      decoration: const BoxDecoration(
        color: Color(0x08FFFFFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -30,
            top: 14,
            child: Container(
              width: 191,
              height: 191,
              decoration: const BoxDecoration(
                color: Color(0x0AFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 44,
            top: 88,
            child: Container(
              width: 126,
              height: 126,
              decoration: const BoxDecoration(
                color: Color(0x0AFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 58, 16, 16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0x2208B36A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF08B36A),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        ownerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contactNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onEditTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0x3DFFFFFF),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundCard extends StatelessWidget {
  const _GroundCard({
    required this.groundName,
    required this.subtitle,
    required this.onEditTap,
  });

  final String groundName;
  final String subtitle;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1F08B36A)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 12,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    groundName,
                    style: const TextStyle(
                      color: Color(0xFF242424),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF242424),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onEditTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0x1F08B36A),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF08B36A),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children, required this.outlined});

  final List<Widget> children;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outlined ? const Color(0x1FFFFFFF) : Colors.transparent,
        ),
        color: const Color(0x08FFFFFF),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 12,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _IconMenuTile extends StatelessWidget {
  const _IconMenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x1F08B36A),
              ),
              child: Icon(icon, color: const Color(0xFF08B36A), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
