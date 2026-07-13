import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/ist_greeting.dart';
import '../../academy/home/academy_announcement_screen.dart';
import '../../academy/home/academy_dashboard_screen.dart';
import '../../academy/home/academy_profile_screen.dart';
import '../../box_cricket/home/box_cricket_dashboard_screen.dart';
import '../../box_cricket/home/box_cricket_manage_slots_screen.dart';
import '../../box_cricket/home/box_cricket_profile_screen.dart';
import '../../box_cricket/home/box_cricket_upcoming_bookings_screen.dart';
import '../../ground/flow/controllers/ground_flow_controller.dart';
import '../../ground/flow/models/ground_registration_data.dart';
import '../../ground/flow/screens/register_ground_flow_screen.dart';

class GroundCourtOwnerShellScreen extends StatefulWidget {
  const GroundCourtOwnerShellScreen({super.key});

  @override
  State<GroundCourtOwnerShellScreen> createState() =>
      _GroundCourtOwnerShellScreenState();
}

class _GroundCourtOwnerShellScreenState extends State<GroundCourtOwnerShellScreen> {
  final GlobalKey<NavigatorState> _groundNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _academyNavigatorKey =
      GlobalKey<NavigatorState>();
  int _topTabIndex = 0;
  int _groundNavIndex = 0;
  int _academyNavIndex = 0;
  bool _isLoadingCounts = true;
  int _groundCount = 0;
  int _academyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOwnerEntities();
  }

  Future<void> _loadOwnerEntities() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingCounts = false;
          _groundCount = 0;
          _academyCount = 0;
        });
      }
      return;
    }

    setState(() => _isLoadingCounts = true);
    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        GroundWaleApi.instance.listGrounds(ownerId: ownerId),
        GroundWaleApi.instance.listAcademies(ownerId),
      ]);

      final List<Map<String, dynamic>> grounds =
          results[0] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> academies =
          results[1] as List<Map<String, dynamic>>;

      if (!mounted) {
        return;
      }
      setState(() {
        _groundCount = grounds.length;
        _academyCount = academies.length;
        _isLoadingCounts = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingCounts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _addAcademy() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    final GroundFlowController flowController = GroundFlowController();
    flowController.data.offerType = OfferType.academyCoaching;
    flowController.data.ownerName = ApiSession.instance.ownerName ?? '';
    flowController.data.contactNumber = ApiSession.instance.contactNumber ?? '';
    flowController.data.otpVerified = true;
    flowController.skipOwnershipVerification = true;

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterGroundFlowScreen(
          initialController: flowController,
          initialStep: 13,
          onFinish: () {
            Navigator.of(context).pop();
            _loadOwnerEntities();
            if (!mounted) {
              return;
            }
            setState(() {
              _topTabIndex = 1;
              _academyNavIndex = 0;
            });
          },
        ),
      ),
    );

    if (mounted) {
      await _loadOwnerEntities();
      setState(() {
        _topTabIndex = 1;
      });
    }
  }

  Future<void> _addGround() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    final GroundFlowController flowController = GroundFlowController();
    flowController.data.ownerName = ApiSession.instance.ownerName ?? '';
    flowController.data.contactNumber = ApiSession.instance.contactNumber ?? '';
    flowController.data.otpVerified = true;
    flowController.skipOwnershipVerification = true;

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterGroundFlowScreen(
          initialController: flowController,
          initialStep: 3,
          skipUnderReview: true,
          forceCreateGround: true,
          onFinish: () {
            Navigator.of(context).pop();
            _loadOwnerEntities();
            if (!mounted) {
              return;
            }
            setState(() {
              _topTabIndex = 0;
              _groundNavIndex = 0;
            });
          },
        ),
      ),
    );

    if (mounted) {
      await _loadOwnerEntities();
      setState(() {
        _topTabIndex = 0;
      });
    }
  }

  Widget _emptyCta({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.inbox_outlined,
              color: Color(0x99FFFFFF),
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  foregroundColor: const Color(0xFF06271F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groundBody() {
    return Navigator(
      key: _groundNavigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          builder: (_) {
            return IndexedStack(
              index: _groundNavIndex,
              children: <Widget>[
                BoxCricketDashboardScreen(
                  showBottomNav: false,
                  onOpenBookings: () => setState(() => _groundNavIndex = 1),
                  onOpenSlots: () => setState(() => _groundNavIndex = 2),
                  onOpenProfile: () => setState(() => _groundNavIndex = 3),
                ),
                BoxCricketUpcomingBookingsScreen(showBottomNav: false),
                BoxCricketManageSlotsScreen(showBottomNav: false),
                BoxCricketProfileScreen(showBottomNav: false),
              ],
            );
          },
        );
      },
    );
  }

  Widget _academyBody() {
    return Navigator(
      key: _academyNavigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          builder: (_) {
            return IndexedStack(
              index: _academyNavIndex,
              children: const <Widget>[
                AcademyDashboardScreen(showBottomNav: false),
                AcademyAnnouncementScreen(showBottomNav: false),
                AcademyProfileScreen(showBottomNav: false),
              ],
            );
          },
        );
      },
    );
  }

  Widget _topTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? const Color(0xFF00C9A7) : const Color(0x0FFFFFFF),
            border: Border.all(
              color: selected ? const Color(0xFF00C9A7) : const Color(0x26FFFFFF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF06271F) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: selected ? const Color(0xFF00C9A7) : const Color(0xFF9FB9B3),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF00C9A7) : const Color(0xFF9FB9B3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groundNav() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1F1B),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(
        children: <Widget>[
          _bottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: _groundNavIndex == 0,
            onTap: () => setState(() => _groundNavIndex = 0),
          ),
          _bottomNavItem(
            icon: Icons.confirmation_num_outlined,
            label: 'Bookings',
            selected: _groundNavIndex == 1,
            onTap: () => setState(() => _groundNavIndex = 1),
          ),
          _bottomNavItem(
            icon: Icons.schedule_outlined,
            label: 'Slots',
            selected: _groundNavIndex == 2,
            onTap: () => setState(() => _groundNavIndex = 2),
          ),
          _bottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: _groundNavIndex == 3,
            onTap: () => setState(() => _groundNavIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _academyNav() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF0F2027),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(
        children: <Widget>[
          _bottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: _academyNavIndex == 0,
            onTap: () => setState(() => _academyNavIndex = 0),
          ),
          _bottomNavItem(
            icon: Icons.campaign_outlined,
            label: 'Announcement',
            selected: _academyNavIndex == 1,
            onTap: () => setState(() => _academyNavIndex = 1),
          ),
          _bottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: _academyNavIndex == 2,
            onTap: () => setState(() => _academyNavIndex = 2),
          ),
        ],
      ),
    );
  }

  Widget _headerIconChip(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Icon(icon, color: const Color(0xFFDDF730), size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String ownerName =
        ApiSession.instance.ownerName?.trim().isNotEmpty == true
        ? ApiSession.instance.ownerName!.trim()
        : 'Owner';
    final String greetingMessage = istGreetingMessage(ownerName);

    return Scaffold(
      backgroundColor: _topTabIndex == 0 ? const Color(0xFF1B1F1B) : const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x14FFFFFF)),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFFDDF730),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        greetingMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      _headerIconChip(Icons.campaign_outlined),
                      const SizedBox(width: 10),
                      _headerIconChip(Icons.notifications_none_rounded),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: <Widget>[
                  _topTab(
                    label: 'Grounds/Courts',
                    selected: _topTabIndex == 0,
                    onTap: () => setState(() => _topTabIndex = 0),
                  ),
                  const SizedBox(width: 10),
                  _topTab(
                    label: 'Academies',
                    selected: _topTabIndex == 1,
                    onTap: () => setState(() => _topTabIndex = 1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingCounts
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
                    )
                  : _topTabIndex == 0
                  ? (_groundCount == 0
                        ? _emptyCta(
                            title: 'No Grounds/Courts Yet',
                            subtitle:
                                'Create your first ground or court to start managing bookings and slots.',
                            buttonLabel: 'Add Ground/Court',
                            onTap: _addGround,
                          )
                        : _groundBody())
                  : (_academyCount == 0
                        ? _emptyCta(
                            title: 'No Academies Yet',
                            subtitle:
                                'Create your first academy to manage students, batches, and attendance.',
                            buttonLabel: 'Add Academy',
                            onTap: _addAcademy,
                          )
                        : _academyBody()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _topTabIndex == 0 ? _groundNav() : _academyNav(),
    );
  }
}
