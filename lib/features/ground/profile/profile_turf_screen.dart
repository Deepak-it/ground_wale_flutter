import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';
import '../../../core/widgets/module_bottom_nav.dart';
import '../slots/manage_slot_turf_screen.dart';
import '../dashboard/dashboard_turf_screen.dart';
import '../bookings/bookings_turf_screen.dart';
import 'bank_account_turf_screen.dart';
import 'earning_report_turf_screen.dart';
import 'facility_settings_edit_turf_screen.dart';
import 'facility_settings_turf_screen.dart';
import 'ground_edit_turf_screen.dart';
import 'help_support_turf_screen.dart';
import 'logout_turf_screen.dart';
import 'notification_turf_screen.dart';
import 'pricing_slot_turf_screen.dart';
import 'profile_compact_turf_screen.dart';
import 'profile_turf_ui.dart';
import 'terms_policy_turf_screen.dart';
import 'wallet_earning_turf_screen.dart';

class ProfileTurfScreen extends StatelessWidget {
  const ProfileTurfScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  Future<Map<String, dynamic>> _loadData() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated) {
      return <String, dynamic>{};
    }
    if (!session.hasGround) {
      session.setGroundId(await GroundWaleApi.instance.ensureGroundIdForOwner(session.ownerId!));
    }
    final Map<String, dynamic> profile = await GroundWaleApi.instance.getOwnerProfile(session.ownerId!);
    final Map<String, dynamic> ground = session.hasGround ? await GroundWaleApi.instance.getGround(session.groundId!) : <String, dynamic>{};
    return <String, dynamic>{'profile': profile, 'ground': ground};
  }

  @override
  Widget build(BuildContext context) {
    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      );
    }

    Widget groupedTile({
      required String title,
      String? subtitle,
      required VoidCallback onTap,
      IconData? icon,
      Color iconColor = const Color(0xFF08B36A),
      bool divider = true,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              if (icon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    if (subtitle != null)
                      Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 15)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
            ],
          ),
        ),
      );
    }

    Widget sectionCard(List<Widget> children) {
      return TurfCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: children),
      );
    }

    return TurfPageScaffold(
      title: 'Profile',
      showBackButton: showBottomNav,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          final Map<String, dynamic> profile = Map<String, dynamic>.from(snapshot.data?['profile'] as Map? ?? <String, dynamic>{});
          final Map<String, dynamic> ground = Map<String, dynamic>.from(snapshot.data?['ground'] as Map? ?? <String, dynamic>{});
          return ListView(
        children: <Widget>[
          TurfCard(
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDF730),
                    shape: BoxShape.circle,
                  ),
                  child: buildBase64OrNetworkImage(
                    value: profile['profileImage']?.toString(),
                    fit: BoxFit.cover,
                    fallback: const Icon(
                      Icons.person,
                      color: Color(0xFF242424),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(profile['ownerName']?.toString() ?? 'Owner', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(profile['contactNumber']?.toString() ?? '', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ProfileCompactTurfScreen()),
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          TurfCard(
            backgroundColor: const Color(0xFFFFFFFF),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(ground['groundName']?.toString() ?? 'No ground yet', style: const TextStyle(color: Color(0xFF242424), fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(ground['address']?.toString() ?? '', style: const TextStyle(color: Color(0xFF242424), fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x2208B36A),
                    foregroundColor: const Color(0xFF08B36A),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GroundEditTurfScreen())),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          sectionTitle('Earning & Payout'),
          sectionCard(<Widget>[
            groupedTile(
              title: 'Wallet / Earnings',
              subtitle: 'Check balance, payouts and transactions',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WalletEarningTurfScreen())),
            ),
            const Divider(color: Colors.white24, height: 1),
            groupedTile(
              title: 'Bank Account',
              subtitle: 'HDFC Bank....2048 linked',
              icon: Icons.account_balance_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BankAccountTurfScreen())),
            ),
          ]),
          sectionTitle('Settings'),
          sectionCard(<Widget>[
            groupedTile(
              title: 'Notifications',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationTurfScreen())),
            ),
            const Divider(color: Colors.white24, height: 1),
            groupedTile(
              title: 'Pricing & Slot Settings',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PricingSlotTurfScreen())),
            ),
            const Divider(color: Colors.white24, height: 1),
            groupedTile(
              title: 'Facilities Settings',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FacilitySettingsTurfScreen())),
            ),
            const Divider(color: Colors.white24, height: 1),
            groupedTile(
              title: 'Facilities Settings (Alt State)',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FacilitySettingsEditTurfScreen())),
            ),
          ]),
          sectionTitle('Reports'),
          sectionCard(<Widget>[
            groupedTile(
              title: 'Booking History',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BookingsTurfScreen())),
            ),
            const Divider(color: Colors.white24, height: 1),
            groupedTile(
              title: 'Earning Report',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningReportTurfScreen())),
            ),
          ]),
          sectionTitle('Support & Help'),
          sectionCard(<Widget>[
            groupedTile(
              title: 'Help & Support',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HelpSupportTurfScreen())),
            ),
            const Divider(color: Colors.white24, height: 1),
            groupedTile(
              title: 'Terms & Policies',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TermsPolicyTurfScreen())),
            ),
          ]),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LogoutTurfScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDB1F1F)),
                color: const Color(0x08DB1F1F),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.logout_rounded, color: Color(0xFFDB1F1F)),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Color(0xFFDB1F1F), fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          if (showBottomNav) ...<Widget>[
            const SizedBox(height: 14),
            ModuleBottomNav(
              currentIndex: 3,
              activeColor: const Color(0xFFDDF730),
              inactiveColor: const Color(0xFF7B8A97),
              backgroundColor: const Color(0xFF181914),
              borderColor: const Color(0x33000000),
              height: 76,
              horizontalPadding: 14,
              bottomPadding: 10,
              items: <ModuleBottomNavItem>[
                ModuleBottomNavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const DashboardTurfScreen()),
                      (Route<dynamic> route) => route.isFirst,
                    );
                  },
                ),
                ModuleBottomNavItem(
                  icon: Icons.confirmation_num_outlined,
                  label: 'Bookings',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const BookingsTurfScreen(showBackButton: false),
                      ),
                    );
                  },
                ),
                ModuleBottomNavItem(
                  icon: Icons.schedule_outlined,
                  label: 'Slots',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const ManageSlotTurfScreen(showBackButton: false),
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
            ),
          ],
        ],
          );
        },
      ),
    );
  }
}
