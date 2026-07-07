import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/widgets/module_bottom_nav.dart';
import '../slots/manage_slot_turf_screen.dart';
import '../profile/profile_turf_screen.dart';
import '../bookings/bookings_turf_screen.dart';

class DashboardTurfScreen extends StatefulWidget {
  const DashboardTurfScreen({super.key});

  @override
  State<DashboardTurfScreen> createState() => _DashboardTurfScreenState();
}

class _DashboardTurfScreenState extends State<DashboardTurfScreen> {
  int _currentIndex = 0;
  final GroundWaleApi _api = GroundWaleApi.instance;
  late final Future<void> _bootstrapFuture = _bootstrap();

  Future<void> _bootstrap() async {
    final ApiSession session = ApiSession.instance;
    if (!session.isAuthenticated || session.hasGround) {
      return;
    }

    final String? groundId = await _api.ensureGroundIdForOwner(session.ownerId!);
    session.setGroundId(groundId);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      _HomeTab(bootstrapFuture: _bootstrapFuture),
      const BookingsTurfScreen(showBackButton: false),
      const ManageSlotTurfScreen(showBackButton: false),
      const ProfileTurfScreen(showBottomNav: false),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: ModuleBottomNav(
        currentIndex: _currentIndex,
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
            onTap: () => setState(() => _currentIndex = 0),
          ),
          ModuleBottomNavItem(
            icon: Icons.confirmation_num_outlined,
            label: 'Bookings',
            onTap: () => setState(() => _currentIndex = 1),
          ),
          ModuleBottomNavItem(
            icon: Icons.schedule_outlined,
            label: 'Slots',
            onTap: () => setState(() => _currentIndex = 2),
          ),
          ModuleBottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () => setState(() => _currentIndex = 3),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.bootstrapFuture});

  final Future<void> bootstrapFuture;

  Future<Map<String, dynamic>> _loadDashboard(ApiSession session) async {
    await bootstrapFuture;
    if (!session.isAuthenticated) {
      return <String, dynamic>{};
    }
    return GroundWaleApi.instance.getDashboard(session.ownerId!);
  }

  @override
  Widget build(BuildContext context) {
    final ApiSession session = ApiSession.instance;

    Widget statCard(String label, Object value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x10FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x30FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    if (!session.isAuthenticated) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B1F1B),
        body: SafeArea(child: _EmptyDashboard(message: 'Login first to load dashboard data.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadDashboard(session),
          builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFDDF730)));
            }

            if (snapshot.hasError) {
              return _EmptyDashboard(message: snapshot.error.toString().replaceFirst('Exception: ', ''));
            }

            final Map<String, dynamic> dashboard = snapshot.data ?? <String, dynamic>{};
            final Map<String, dynamic> reviewBreakdown = Map<String, dynamic>.from(
              dashboard['reviewBreakdown'] as Map? ?? <String, dynamic>{},
            );

            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text(
                  'Welcome ${session.ownerName ?? 'Ground Owner'}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Live data from your Express API', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    statCard('Grounds', dashboard['groundsRegistered'] ?? 0),
                    const SizedBox(width: 12),
                    statCard('Slots', dashboard['slotsCreated'] ?? 0),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    statCard('Bookings', dashboard['liveBookings'] ?? 0),
                    const SizedBox(width: 12),
                    statCard('Earnings', '₹${dashboard['totalEarnings'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0x10FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x30FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Review Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Text('Draft: ${reviewBreakdown['draft'] ?? 0}'),
                      Text('Under review: ${reviewBreakdown['underReview'] ?? 0}'),
                      Text('Approved: ${reviewBreakdown['approved'] ?? 0}'),
                      Text('Rejected: ${reviewBreakdown['rejected'] ?? 0}'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0x10FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x30FFFFFF)),
        ),
        child: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ),
    );
  }
}

