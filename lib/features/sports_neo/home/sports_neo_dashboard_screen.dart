import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';
import '../../../core/widgets/google_city_picker_sheet.dart';
import '../../ground/flow/controllers/ground_flow_controller.dart';
import '../../ground/flow/screens/choose_sports_screen.dart';
import 'sports_neo_academy_flow_screens.dart';
import 'sports_neo_booking_history_screen.dart';
import 'sports_neo_choose_team_screen.dart';
import 'sports_neo_ground_detail_screen.dart';
import 'sports_neo_ledger_payments_screen.dart';
import 'sports_neo_manage_teams_screen.dart';
import 'sports_neo_nearby_grounds_screen.dart';
import 'sports_neo_notifications_screen.dart';
import 'sports_neo_onboarding_flow.dart';
import 'sports_neo_split_payment_flow_screens.dart';
import 'sports_neo_settings_screen.dart';

class SportsNeoDashboardScreen extends StatefulWidget {
  const SportsNeoDashboardScreen({super.key});

  @override
  State<SportsNeoDashboardScreen> createState() =>
      _SportsNeoDashboardScreenState();
}

class _SportsNeoDashboardScreenState extends State<SportsNeoDashboardScreen> {
  static const List<String> _sportsTabs = ['Cricket', 'Football', 'Badminton'];

  static const List<String> _drawerMenuItems = [
    'Ledger & Payments',
    'Booking History',
    'Create Team',
    'My Teams',
    'My Matches',
    'Add a Match',
    'Settings',
  ];

  final GroundWaleApi _api = GroundWaleApi.instance;

  int _selectedTab = 0;

  String _profileName = '';
  String _profilePhone = '';
  String? _profileImage;

  String _location = 'Select city';

  List<Map<String, dynamic>> _allGroundsRaw = const <Map<String, dynamic>>[];

  List<_GroundCardData> _displayGrounds = const <_GroundCardData>[];

  List<_InfoCardData> _teams = const <_InfoCardData>[];

  List<_InfoCardData> _bookings = const <_InfoCardData>[];

  List<_LedgerCardData> _ledger = const <_LedgerCardData>[];

  int _matchesCount = 0;
  int _teamsCount = 0;
  int _bookingsCount = 0;
  int _unreadNotifications = 0;

  String _filterCity = '';
  String? _manualSportFilter;
  bool _isGroundsLoading = false;

  String get _selectedSportLabel {
    final String? customSport = _manualSportFilter?.trim();
    if (customSport != null && customSport.isNotEmpty) {
      return customSport;
    }

    return _sportsTabs[_selectedTab];
  }

  String get _selectedSportFilter => _selectedSportLabel.toLowerCase();

  String? get _selectedCityFilter {
    final String city = _filterCity.trim();
    return city.isEmpty ? null : city;
  }

  @override
  void initState() {
    super.initState();

    final String? sessionCity = ApiSession.instance.city;

    if (sessionCity != null && sessionCity.isNotEmpty) {
      _filterCity = sessionCity;
    }

    _loadSportsNeoData();
  }

  Future<void> _loadSportsNeoData() async {
    _isGroundsLoading = true;

    final String? ownerId = ApiSession.instance.ownerId;

    Map<String, dynamic>? profile;
    Map<String, dynamic>? dashboard;

    List<Map<String, dynamic>> grounds = <Map<String, dynamic>>[];

    List<Map<String, dynamic>> teams = <Map<String, dynamic>>[];

    List<Map<String, dynamic>> ownerBookings = <Map<String, dynamic>>[];

    List<Map<String, dynamic>> ownerLedger = <Map<String, dynamic>>[];

    Future<T?> safely<T>(Future<T> Function() fn) async {
      try {
        return await fn();
      } catch (_) {
        return null;
      }
    }

    if (ownerId != null && ownerId.isNotEmpty) {
      final List<dynamic> batch1 = await Future.wait<dynamic>([
        safely(
          () => _api.listGrounds(
            city: _selectedCityFilter,
            sport: _selectedSportFilter,
          ),
        ),
        safely(() => _api.getOwnerProfile(ownerId)),
        safely(() => _api.getDashboard(ownerId)),
        safely(() => _api.listTeams(ownerId)),
        safely(() => _api.ensureGroundIdForOwner(ownerId)),
        safely(() => _api.listNotifications(ownerId)),
      ]);

      grounds =
          (batch1[0] as List<Map<String, dynamic>>?) ??
          <Map<String, dynamic>>[];

      profile = batch1[1] as Map<String, dynamic>?;

      dashboard = batch1[2] as Map<String, dynamic>?;

      teams =
          (batch1[3] as List<Map<String, dynamic>>?) ??
          <Map<String, dynamic>>[];

      final String? groundId = batch1[4] as String?;

      final List<Map<String, dynamic>>? notifications =
          batch1[5] as List<Map<String, dynamic>>?;

      if (notifications != null) {
        _unreadNotifications = notifications
            .where((Map<String, dynamic> item) => item['isRead'] != true)
            .length;
      }

      if (groundId != null && groundId.isNotEmpty) {
        final List<dynamic> batch2 = await Future.wait<dynamic>([
          safely(() => _api.listBookings(groundId)),
          safely(() => _api.getTransactions(groundId)),
        ]);

        ownerBookings =
            (batch2[0] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];

        ownerLedger =
            (batch2[1] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
      }
    } else {
      try {
        grounds = await _api.listGrounds(
          city: _selectedCityFilter,
          sport: _selectedSportFilter,
        );
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    final String profileName =
        _stringValue(profile, <String>['ownerName', 'name', 'fullName']) ??
        _profileName;

    final String profilePhone =
        _stringValue(profile, <String>['contactNumber', 'phone', 'mobile']) ??
        ApiSession.instance.contactNumber ??
        _profilePhone;

    final String location =
        _stringValue(profile, <String>['address', 'city', 'location']) ??
        _location;

    final String profileCity =
        _stringValue(profile, <String>['city']) ??
        location.split(',').first.trim();

    final List<_InfoCardData> mappedTeams = teams.isNotEmpty
        ? _mapTeamsFromOwnerEndpoint(teams)
        : _mapInfoCards(
            _extractMapList(dashboard, <String>[
              'myTeams',
              'teams',
              'teamList',
            ]),
            defaultStatus: 'Active',
            fallbackSubtitle: 'No details available',
          );

    final List<_InfoCardData> mappedBookings = ownerBookings.isNotEmpty
        ? _mapBookingsFromGroundEndpoint(ownerBookings)
        : _mapInfoCards(
            _extractMapList(dashboard, <String>[
              'myBookings',
              'bookings',
              'upcomingBookings',
            ]),
            defaultStatus: 'Upcoming',
            fallbackSubtitle: 'No booking details available',
          );

    final List<_LedgerCardData> mappedLedger = ownerLedger.isNotEmpty
        ? _mapLedgerCards(ownerLedger)
        : _mapLedgerCards(
            _extractMapList(dashboard, <String>[
              'ledger',
              'transactions',
              'walletTransactions',
            ]),
          );

    final int teamsCount =
        _intValue(dashboard, <String>['teamsCount']) ?? mappedTeams.length;

    final int bookingsCount =
        _intValue(dashboard, <String>['bookingsCount']) ??
        mappedBookings.length;

    final int matchesCount =
        _intValue(dashboard, <String>['matchesCount']) ??
        _intValue(dashboard, <String>['matches']) ??
        _matchesCount;

    setState(() {
      _profileName = profileName;
      _profilePhone = profilePhone;

      _profileImage = _stringValue(profile, <String>['profileImage', 'image']);

      _location = location;

      if (_filterCity.isEmpty && profileCity.isNotEmpty) {
        _filterCity = profileCity;
      }

      _allGroundsRaw = grounds;

      _displayGrounds = _buildDisplayGrounds(grounds);

      _teams = mappedTeams;
      _bookings = mappedBookings;
      _ledger = mappedLedger;

      _matchesCount = matchesCount;
      _teamsCount = teamsCount;
      _bookingsCount = bookingsCount;
      _isGroundsLoading = false;
    });
  }

  List<_GroundCardData> _buildDisplayGrounds(List<Map<String, dynamic>> raw) {
    return _mapGrounds(raw);
  }

  List<Map<String, dynamic>> get _filteredGroundsRaw {
    return _allGroundsRaw;
  }

  List<_GroundCardData> get _filteredGrounds => _displayGrounds;

  Future<void> _showLocationFilterSheet() async {
    final GoogleCitySelection? selection = await showGoogleCityPickerSheet(
      context: context,
      title: 'Select City',
      initialQuery: _filterCity,
      allowClear: true,
    );

    if (!mounted || selection == null) {
      return;
    }

    _applyCityFilter(selection.city);
  }

  Future<void> _applyCityFilter(String city) async {
    if (!mounted) {
      return;
    }

    final String trimmed = city.trim();
    setState(() {
      _filterCity = trimmed;
    });

    await _refreshGroundsForCurrentFilters();
  }

  Future<void> _refreshGroundsForCurrentFilters() async {
    if (!mounted) {
      return;
    }

    List<Map<String, dynamic>> latestGrounds = _allGroundsRaw;

    setState(() {
      _isGroundsLoading = true;
    });

    try {
      latestGrounds = await _api.listGrounds(
        city: _selectedCityFilter,
        sport: _selectedSportFilter,
      );
    } catch (_) {
      // Keep the existing cached list if API refresh fails.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _allGroundsRaw = latestGrounds;
      _displayGrounds = _buildDisplayGrounds(latestGrounds);
      _isGroundsLoading = false;
    });
  }

  Future<void> _applySportFilter(int index) async {
    if (!mounted || index < 0 || index >= _sportsTabs.length) {
      return;
    }

    setState(() {
      _selectedTab = index;
      _manualSportFilter = null;
    });

    await _refreshGroundsForCurrentFilters();
  }

  Future<void> _showMoreSports() async {
    if (!mounted) {
      return;
    }

    final GroundFlowController controller = GroundFlowController();
    controller.data.selectedSports
      ..clear()
      ..add(_selectedSportLabel);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.92,
            child: ChooseSportsScreen(
              controller: controller,
              singleSelection: true,
              onDone: (List<String> selectedSports) {
                Navigator.of(sheetContext).pop();

                if (selectedSports.isEmpty) {
                  return;
                }

                _applyCustomSportFilter(selectedSports.first);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyCustomSportFilter(String selectedSport) async {
    if (!mounted) {
      return;
    }

    final String trimmedSport = selectedSport.trim();

    if (trimmedSport.isEmpty) {
      return;
    }

    final int existingIndex = _sportsTabs.indexWhere(
      (String tab) =>
          _normalizeSportKey(tab) == _normalizeSportKey(trimmedSport),
    );

    setState(() {
      if (existingIndex >= 0) {
        _selectedTab = existingIndex;
        _manualSportFilter = null;
      } else {
        _manualSportFilter = trimmedSport;
      }
    });

    await _refreshGroundsForCurrentFilters();
  }

  String _normalizeSportKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      drawerScrimColor: const Color(0x99000000),

      drawer: _SportsNeoSidebar(
        menuItems: _drawerMenuItems,
        profileName: _profileName,
        profilePhone: _profilePhone,
        profileImage: _profileImage,
        matchesCount: _matchesCount,
        teamsCount: _teamsCount,
        bookingsCount: _bookingsCount,
        onMenuTap: _handleDrawerMenu,
      ),

      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(context),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSportsAcademySwitcher(context),

                        const SizedBox(height: 14),

                        _buildSportSelector(),

                        const SizedBox(height: 16),

                        _buildCityFilter(),

                        const SizedBox(height: 20),

                        _SectionHeader(
                          title: 'Nearby Ground',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SportsNeoNearbyGroundsScreen(
                                  grounds: _filteredGroundsRaw,
                                  fallbackLocation: _location,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildNearbyGrounds(),

                        const SizedBox(height: 22),

                        _SectionHeader(title: 'Schedule Matches', onTap: () {}),

                        const SizedBox(height: 12),

                        if (_bookings.isEmpty)
                          const _EmptySectionNotice(
                            message: 'No scheduled matches',
                          )
                        else
                          _CompactBookingCard(item: _bookings.first),

                        const SizedBox(height: 22),

                        _SectionHeader(
                          title: 'My teams',
                          actionText: 'Manage',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SportsNeoManageTeamsScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildTeams(),

                        const SizedBox(height: 22),

                        _SectionHeader(
                          title: 'My Bookings',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SportsNeoBookingHistoryScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildBookings(),

                        const SizedBox(height: 22),

                        _SectionHeader(
                          title: 'Ledger',
                          actionText: 'Full ledger',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SportsNeoLedgerPaymentsScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildLedger(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DRAWER ACTIONS
  // ---------------------------------------------------------------------------

  void _handleDrawerMenu(String label) {
    if (label == 'Ledger & Payments') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SportsNeoLedgerPaymentsScreen(),
        ),
      );
      return;
    }

    if (label == 'Booking History') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SportsNeoBookingHistoryScreen(),
        ),
      );
      return;
    }

    if (label == 'Settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SportsNeoSettingsScreen()),
      );
      return;
    }

    if (label == 'Add a Match') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SportsNeoAddMatchScreen(
            myTeam: const SportsNeoTeamInfo(
              name: 'My Team',
              players: 0,
              color: Color(0xFF0EA5E9),
            ),
            opponentTeam: const SportsNeoTeamInfo(
              name: 'Opponent Team',
              players: 0,
              color: Color(0xFF2563EB),
            ),
            amount: 0,
          ),
        ),
      );
      return;
    }

    if (label == 'My Teams' ||
        label == 'My Matches' ||
        label == 'Create Team') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SportsNeoManageTeamsScreen()),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HERO HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeroHeader(BuildContext context) {
    return SizedBox(
      height: 235,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 190,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF06142B),
                  Color(0xFF0A2550),
                  Color(0xFF07152B),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -15,
                  child: Container(
                    width: 330,
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0x551D73E8), Color(0x001D73E8)],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: .6,
                    child: CustomPaint(
                      size: const Size(double.infinity, 105),
                      painter: _StadiumPainter(),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Builder(
                            builder: (drawerContext) {
                              return _HeaderCircleButton(
                                icon: Icons.menu_rounded,
                                onTap: () {
                                  Scaffold.of(drawerContext).openDrawer();
                                },
                              );
                            },
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Find Your Ground',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.7,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                InkWell(
                                  onTap: _showLocationFilterSheet,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          _location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xE6FFFFFF),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _HeaderActionIcon(
                            icon: Icons.notifications_none_rounded,
                            badgeCount: _unreadNotifications,
                            backgroundColor: const Color(0x25FFFFFF),
                            iconColor: Colors.white,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SportsNeoNotificationsScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 7),

                          _HeaderActionIcon(
                            icon: Icons.shopping_cart_outlined,
                            backgroundColor: const Color(0x25FFFFFF),
                            iconColor: Colors.white,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SportsNeoBookingHistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),

                      const Text(
                        'Book. Play. Repeat.',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(left: 16, right: 16, bottom: 0, child: _buildSearchBar()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF101C2D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x35FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFFCBD5E1), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search sports, academies or grounds',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.tune_rounded, color: Color(0xFFCBD5E1), size: 21),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SPORTS / ACADEMIES
  // ---------------------------------------------------------------------------

  Widget _buildSportsAcademySwitcher(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_soccer_rounded,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sports',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SportsNeoAcademyDetailScreen(
                      selectedCity: _selectedCityFilter,
                    ),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: Color(0xFF475569),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Academies',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SPORTS
  // ---------------------------------------------------------------------------

  Widget _buildSportSelector() {
    const List<IconData> icons = [
      Icons.sports_cricket_rounded,
      Icons.sports_soccer_rounded,
      Icons.sports_tennis_rounded,
    ];

    return SizedBox(
      height: 92,
      child: Row(
        children: [
          for (int index = 0; index < 3; index++) ...[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: _isGroundsLoading
                    ? null
                    : () => _applySportFilter(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == index
                        ? const Color(0xFF315CF4)
                        : const Color(0xFF101C2D),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _selectedTab == index
                          ? const Color(0xFF4F74FF)
                          : const Color(0x1FFFFFFF),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[index], color: Colors.white, size: 31),
                      const SizedBox(height: 7),
                      Text(
                        _sportsTabs[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (index != 2) const SizedBox(width: 9),
          ],

          const SizedBox(width: 9),

          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: _isGroundsLoading ? null : _showMoreSports,
              child: Container(
                decoration: BoxDecoration(
                  color: _manualSportFilter == null
                      ? const Color(0xFF101C2D)
                      : const Color(0xFF315CF4),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _manualSportFilter == null
                        ? const Color(0x1FFFFFFF)
                        : const Color(0xFF4F74FF),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      color: Color(0xFFCBD5E1),
                      size: 27,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'View More',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CITY FILTER
  // ---------------------------------------------------------------------------

  Widget _buildCityFilter() {
    return InkWell(
      onTap: _showLocationFilterSheet,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF101C2D),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x202563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_city_rounded,
                color: Color(0xFF5C8FFF),
                size: 21,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'City filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _filterCity.isEmpty ? 'All cities' : _filterCity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: Color(0xCCFFFFFF)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NEARBY GROUNDS
  // ---------------------------------------------------------------------------

  Widget _buildNearbyGrounds() {
    if (_isGroundsLoading) {
      return const _GroundsLoadingNotice();
    }

    if (_filteredGrounds.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EmptySectionNotice(
            message: _filterCity.isNotEmpty
                ? "No grounds found in '$_filterCity'."
                : 'No grounds available right now.',
          ),
          if (_filterCity.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _applyCityFilter(''),
              child: const Text(
                'Show all grounds →',
                style: TextStyle(
                  color: Color(0xFF4F7FFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
    }

    final int count = _filteredGrounds.length > 3 ? 3 : _filteredGrounds.length;

    return SizedBox(
      height: 340,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          return _NearbyGroundShowcaseCard(item: _filteredGrounds[index]);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TEAMS
  // ---------------------------------------------------------------------------

  Widget _buildTeams() {
    if (_teams.isEmpty) {
      return const _EmptySectionNotice(message: 'No teams found');
    }

    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _teams.length > 5 ? 5 : _teams.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          return _TeamGradientCard(item: _teams[index]);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOOKINGS
  // ---------------------------------------------------------------------------

  Widget _buildBookings() {
    if (_bookings.isEmpty) {
      return const _EmptySectionNotice(message: 'No bookings found');
    }

    return Column(
      children: _bookings
          .take(3)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CompactBookingCard(item: item),
            ),
          )
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // LEDGER
  // ---------------------------------------------------------------------------

  Widget _buildLedger() {
    if (_ledger.isEmpty) {
      return const _EmptySectionNotice(message: 'No ledger entries found');
    }

    return Column(
      children: _ledger
          .take(2)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LedgerCard(
                title: item.title,
                subtitle: item.subtitle,
                amount: item.amount,
                date: item.date,
                positive: item.positive,
              ),
            ),
          )
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigation(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 10,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xF20A1628),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x20FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  active: true,
                  onTap: () {},
                ),

                const SizedBox(width: 65),

                _BottomNavItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Bookings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SportsNeoBookingHistoryScreen(),
                      ),
                    );
                  },
                ),

                _BottomNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () {},
                ),
              ],
            ),

            Positioned(
              top: -18,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SportsNeoManageTeamsScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB),
                    border: Border.all(
                      color: const Color(0xFF07111F),
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x662563EB),
                        blurRadius: 16,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DATA MAPPING
  // ---------------------------------------------------------------------------

  List<_GroundCardData> _mapGrounds(List<Map<String, dynamic>> items) {
    return items.map((Map<String, dynamic> item) {
      final String name =
          _stringFromAny(item, ['name', 'groundName', 'title']) ?? 'Ground';

      final String location =
          _stringFromAny(item, ['location', 'address', 'city']) ?? _location;

      final String detail = _facilityText(item) ?? 'No facility details';

      final String price = _priceText(item) ?? 'N/A';

      final List imageValues = _groundImageValuesFromAny(item);

      final String imageUrl = _groundImageFromAny(item) ?? '';

      final double rating =
          _doubleFromAny(item, ['rating', 'groundRating']) ?? 0;

      final List facilities = _facilitiesFromAny(item);

      return _GroundCardData(
        name: name,
        location: location,
        price: price,
        detail: detail,
        imageUrl: imageUrl,
        imageValues: imageValues,
        rating: rating,
        facilities: facilities,
        groundId: item['_id']?.toString() ?? item['id']?.toString() ?? '',
      );
    }).toList();
  }

  List _groundImageValuesFromAny(Map<String, dynamic> item) {
    final List values = [];

    void addIfValid(dynamic raw) {
      final String value = raw?.toString().trim() ?? '';

      if (value.isNotEmpty && !values.contains(value)) {
        values.add(value);
      }
    }

    final dynamic groundImages = item['groundImages'];

    if (groundImages is List) {
      for (final dynamic entry in groundImages) {
        if (entry is Map) {
          addIfValid(entry['url']);
        } else {
          addIfValid(entry);
        }
      }
    }

    final dynamic imageUrls = item['imageUrls'];

    if (imageUrls is List) {
      for (final dynamic entry in imageUrls) {
        if (entry is Map) {
          addIfValid(entry['url']);
        } else {
          addIfValid(entry);
        }
      }
    }

    final dynamic photos = item['photos'];

    if (photos is List) {
      for (final dynamic entry in photos) {
        if (entry is Map) {
          addIfValid(entry['url']);
        } else {
          addIfValid(entry);
        }
      }
    }

    addIfValid(item['image']);
    addIfValid(item['imageUrl']);

    return values;
  }

  String? _groundImageFromAny(Map<String, dynamic> item) {
    final List values = _groundImageValuesFromAny(item);

    if (values.isEmpty) {
      return null;
    }

    return values.first.toString();
  }

  List _facilitiesFromAny(Map<String, dynamic> item) {
    final dynamic raw = item['facilities'];

    if (raw is List) {
      return raw
          .map((dynamic value) => value.toString().trim())
          .where((String text) => text.isNotEmpty)
          .take(4)
          .toList();
    }

    final String? one = _facilityText(item);

    if (one != null && one.isNotEmpty) {
      return <String>[one];
    }

    return <String>[];
  }

  String? _facilityText(Map<String, dynamic> item) {
    final dynamic facilities = item['facilities'];

    if (facilities is List && facilities.isNotEmpty) {
      return facilities.first.toString();
    }

    return _stringFromAny(item, ['detail', 'feature']);
  }

  String? _priceText(Map<String, dynamic> item) {
    final double? hourly = _doubleFromAny(item, [
      'hourlyPrice',
      'pricePerHour',
      'hourlyRate',
    ]);

    if (hourly == null) {
      return null;
    }

    return 'Rs ${hourly.toStringAsFixed(hourly % 1 == 0 ? 0 : 2)}/hr';
  }

  List<_InfoCardData> _mapInfoCards(
    List<Map<String, dynamic>> items, {
    required String defaultStatus,
    required String fallbackSubtitle,
  }) {
    return items.take(3).map((Map<String, dynamic> item) {
      final String title =
          _stringFromAny(item, ['name', 'teamName', 'title', 'groundName']) ??
          'Untitled';

      final String subtitle =
          _stringFromAny(item, [
            'subtitle',
            'description',
            'slot',
            'time',
            'players',
          ]) ??
          fallbackSubtitle;

      final String amount = _amountText(item) ?? 'N/A';

      final String status = _stringFromAny(item, ['status']) ?? defaultStatus;

      return _InfoCardData(
        title: title,
        subtitle: subtitle,
        amount: amount,
        status: status,
      );
    }).toList();
  }

  List<_InfoCardData> _mapTeamsFromOwnerEndpoint(
    List<Map<String, dynamic>> items,
  ) {
    return items.take(3).map((Map<String, dynamic> item) {
      final String title =
          _stringFromAny(item, ['name', 'teamName', 'title']) ??
          'Untitled Team';

      final int playerCount =
          _intFromAny(item, ['playerCount', 'playersCount']) ??
          ((item['players'] is List) ? (item['players'] as List).length : 0);

      final String subtitle = '$playerCount players';

      return _InfoCardData(
        title: title,
        subtitle: subtitle,
        amount: subtitle,
        status: 'Team',
      );
    }).toList();
  }

  List<_InfoCardData> _mapBookingsFromGroundEndpoint(
    List<Map<String, dynamic>> items,
  ) {
    return items.take(3).map((Map<String, dynamic> item) {
      final String title =
          _stringFromAny(item, ['groundName', 'name', 'title']) ?? 'Booking';

      final String subtitle =
          _stringFromAny(item, [
            'slotLabel',
            'timeRange',
            'slot',
            'date',
            'startTime',
          ]) ??
          'No booking details available';

      final String amount = _amountText(item) ?? 'N/A';

      final String status =
          _stringFromAny(item, ['status', 'bookingStatus']) ?? 'Upcoming';

      return _InfoCardData(
        title: title,
        subtitle: subtitle,
        amount: amount,
        status: status,
      );
    }).toList();
  }

  List<_LedgerCardData> _mapLedgerCards(List<Map<String, dynamic>> items) {
    return items.take(2).map((Map<String, dynamic> item) {
      final String title =
          _stringFromAny(item, ['title', 'type', 'name']) ?? 'Transaction';

      final String subtitle =
          _stringFromAny(item, ['subtitle', 'description']) ?? 'Transaction';

      final double? amountValue = _doubleFromAny(item, ['amount']);

      final bool positive = amountValue == null ? true : amountValue >= 0;

      final String amount = _formatAmount(amountValue?.abs() ?? 0);

      final String date =
          _stringFromAny(item, ['date', 'createdAt']) ?? 'Today';

      return _LedgerCardData(
        title: title,
        subtitle: subtitle,
        amount: amount,
        date: date,
        positive: positive,
      );
    }).toList();
  }

  String? _amountText(Map<String, dynamic> item) {
    final double? amount = _doubleFromAny(item, ['amount', 'total', 'price']);

    if (amount == null) {
      return null;
    }

    return _formatAmount(amount);
  }

  String _formatAmount(double value) {
    final String fixed = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);

    return '₹$fixed';
  }

  String? _stringValue(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) {
      return null;
    }

    return _stringFromAny(map, keys);
  }

  String? _stringFromAny(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
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

  int? _intValue(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) {
      return null;
    }

    for (final String key in keys) {
      final dynamic value = map[key];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      if (value is String) {
        final int? parsed = int.tryParse(value.trim());

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  double? _doubleFromAny(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = map[key];

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        final String cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');

        final double? parsed = double.tryParse(cleaned);

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  int? _intFromAny(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = map[key];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      if (value is String) {
        final int? parsed = int.tryParse(value.trim());

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _extractMapList(
    Map<String, dynamic>? root,
    List<String> keys,
  ) {
    if (root == null) {
      return <Map<String, dynamic>>[];
    }

    for (final String key in keys) {
      final dynamic value = root[key];

      if (value is List) {
        return value
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (value is Map) {
        final Map<String, dynamic> nested = Map<String, dynamic>.from(value);

        final List<Map<String, dynamic>> fromNested = _extractMapList(
          nested,
          <String>['items', 'data', 'list'],
        );

        if (fromNested.isNotEmpty) {
          return fromNested;
        }
      }
    }

    return <Map<String, dynamic>>[];
  }
}

// =============================================================================
// HEADER ACTION
// =============================================================================

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.backgroundColor = const Color(0xFFE5E7EB),
    this.iconColor = const Color(0xFF1F2937),
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3220D),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// =============================================================================
// DRAWER
// =============================================================================

class _SportsNeoSidebar extends StatelessWidget {
  const _SportsNeoSidebar({
    required this.menuItems,
    required this.profileName,
    required this.profilePhone,
    required this.profileImage,
    required this.matchesCount,
    required this.teamsCount,
    required this.bookingsCount,
    required this.onMenuTap,
  });

  final List<String> menuItems;
  final String profileName;
  final String profilePhone;
  final String? profileImage;

  final int matchesCount;
  final int teamsCount;
  final int bookingsCount;

  final ValueChanged<String> onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 290,
      backgroundColor: const Color(0xFF000B2A),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF001651), Color(0xFF091E67)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0x40FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        width: 46,
                        height: 46,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                        ),
                        child: buildBase64OrNetworkImage(
                          value: profileImage,
                          fit: BoxFit.cover,
                          fallback: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF111827),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      profileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      profilePhone,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Divider(color: Color(0x2EFFFFFF), height: 1),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _DrawerStat(
                          number: '$matchesCount',
                          label: 'Matches',
                        ),
                      ),
                      Expanded(
                        child: _DrawerStat(
                          number: '$teamsCount',
                          label: 'Teams',
                        ),
                      ),
                      Expanded(
                        child: _DrawerStat(
                          number: '$bookingsCount',
                          label: 'Bookings',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return _SidebarMenuTile(
                    label: menuItems[index],
                    onTap: () {
                      Navigator.of(context).pop();

                      onMenuTap(menuItems[index]);
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF11A07),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const SportsNeoWelcomeScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

class _DrawerStat extends StatelessWidget {
  const _DrawerStat({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xD9FFFFFF),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  const _SidebarMenuTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xD9FFFFFF),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xD9FFFFFF),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onTap,
    this.actionText = 'See all',
  });

  final String title;
  final VoidCallback? onTap;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: Text(
              actionText,
              style: const TextStyle(
                color: Color(0xFF638FEF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// GROUND CARD
// =============================================================================

class _NearbyGroundShowcaseCard extends StatelessWidget {
  const _NearbyGroundShowcaseCard({required this.item});

  final _GroundCardData item;

  @override
  Widget build(BuildContext context) {
    final Widget imageFallback = Container(
      color: const Color(0xFF263449),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Color(0x667C8AA0),
        size: 32,
      ),
    );

    final List<String> facilities = item.facilities.isEmpty
        ? <String>[item.detail]
        : item.facilities.map((dynamic value) => value.toString()).toList();

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: const Color(0xFF101C2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 145,
            child: Stack(
              children: [
                Positioned.fill(
                  child: item.imageValues.isNotEmpty
                      ? _SportsNeoGroundImageCarousel(
                          imageValues: item.imageValues,
                          fallback: imageFallback,
                        )
                      : buildBase64OrNetworkImage(
                          value: item.imageUrl.isEmpty ? null : item.imageUrl,
                          fit: BoxFit.cover,
                          fallback: imageFallback,
                        ),
                ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, const Color(0x66000000)],
                      ),
                    ),
                  ),
                ),

                if (item.rating > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xDD111827),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFBBF24),
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0x99FFFFFF),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: facilities.take(3).map((String feature) {
                      return Container(
                        margin: const EdgeInsets.only(right: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0x12FFFFFF),
                        ),
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.price,
                        style: const TextStyle(
                          color: Color(0xFF4F8CFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8),

                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SportsNeoGroundDetailScreen(
                              name: item.name,
                              location: item.location,
                              image: item.imageUrl,
                              rating: item.rating,
                              facilities: List<String>.from(
                                item.facilities.map(
                                  (dynamic value) => value.toString(),
                                ),
                              ),
                              price: item.price,
                              groundId: item.groundId,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'View Detail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOOKING CARD
// =============================================================================

class _CompactBookingCard extends StatelessWidget {
  const _CompactBookingCard({required this.item});

  final _InfoCardData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x15FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x202563EB),
            ),
            child: const Icon(
              Icons.sports_cricket_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 11,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0x152563EB),
                ),
                child: Text(
                  item.status,
                  style: const TextStyle(
                    color: Color(0xFF729BF6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

// =============================================================================
// TEAM CARD
// =============================================================================

class _TeamGradientCard extends StatelessWidget {
  const _TeamGradientCard({required this.item});

  final _InfoCardData item;

  @override
  Widget build(BuildContext context) {
    const List<List<Color>> gradients = [
      [Color(0xFF23336C), Color(0xFF2E59F0)],
      [Color(0xFF034D2E), Color(0xFF04693E)],
      [Color(0xFF55236C), Color(0xFFA544D2)],
      [Color(0xFF164E63), Color(0xFF0E7490)],
    ];

    final int indexSeed = item.title.hashCode.abs() % gradients.length;

    final List<Color> colors = gradients[indexSeed];

    return Container(
      width: 145,
      height: 122,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: const Color(0x35FFFFFF),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),

          const Spacer(),

          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          Text(
            item.subtitle,
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY STATE
// =============================================================================

class _EmptySectionNotice extends StatelessWidget {
  const _EmptySectionNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xB3FFFFFF),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _GroundsLoadingNotice extends StatelessWidget {
  const _GroundsLoadingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fetching grounds for selected sport...',
              style: TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LEDGER
// =============================================================================

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.positive,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101C2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x15FFFFFF)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        color: positive
                            ? const Color(0xFF4F8CFF)
                            : const Color(0xFFD36A6A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
            decoration: const BoxDecoration(
              color: Color(0x0AFFFFFF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LedgerSummary(label: 'BOOKINGS', value: '₹4,200'),
                _LedgerSummary(label: 'SPLIT', value: '₹3,500'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerSummary extends StatelessWidget {
  const _LedgerSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF4F8CFF),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// BOTTOM NAV ITEM
// =============================================================================

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// GROUND IMAGE CAROUSEL
// =============================================================================

class _SportsNeoGroundImageCarousel extends StatefulWidget {
  const _SportsNeoGroundImageCarousel({
    required this.imageValues,
    required this.fallback,
  });

  final List imageValues;
  final Widget fallback;

  @override
  State<_SportsNeoGroundImageCarousel> createState() =>
      _SportsNeoGroundImageCarouselState();
}

class _SportsNeoGroundImageCarouselState
    extends State<_SportsNeoGroundImageCarousel> {
  late final PageController _pageController;

  Timer? _autoSlideTimer;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _startAutoSlideIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages(widget.imageValues);
  }

  @override
  void didUpdateWidget(covariant _SportsNeoGroundImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageValues != widget.imageValues) {
      _precacheImages(widget.imageValues);
    }

    if (oldWidget.imageValues.length != widget.imageValues.length) {
      _currentIndex = 0;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      _restartAutoSlide();
    }
  }

  void _precacheImages(List imageValues) {
    for (final dynamic entry in imageValues) {
      final String value = entry.toString().trim();
      if (value.isEmpty) {
        continue;
      }

      if (value.startsWith('http://') || value.startsWith('https://')) {
        precacheImage(NetworkImage(value), context);
        continue;
      }

      final bytes = decodeBase64ImageBytes(value);
      if (bytes != null) {
        precacheImage(MemoryImage(bytes), context);
      }
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlideIfNeeded() {
    _autoSlideTimer?.cancel();

    if (widget.imageValues.length <= 1) {
      return;
    }

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final int next = (_currentIndex + 1) % widget.imageValues.length;

      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _restartAutoSlide() {
    _autoSlideTimer?.cancel();
    _startAutoSlideIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageValues.isEmpty) {
      return widget.fallback;
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.imageValues.length,
          onPageChanged: (int index) {
            setState(() {
              _currentIndex = index;
            });

            _restartAutoSlide();
          },
          itemBuilder: (_, int index) {
            final String imageValue = widget.imageValues[index].toString();

            return buildBase64OrNetworkImage(
              value: imageValue,
              fit: BoxFit.cover,
              fallback: widget.fallback,
            );
          },
        ),

        if (widget.imageValues.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(widget.imageValues.length, (
                int index,
              ) {
                final bool active = index == _currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF2563EB)
                        : const Color(0xCCFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// STADIUM PAINTER
// =============================================================================

class _StadiumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fieldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x002563EB), Color(0x552563EB), Color(0x9920A95C)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Rect field = Rect.fromLTWH(
      size.width * .20,
      size.height * .44,
      size.width * .60,
      size.height * .56,
    );

    canvas.drawOval(field, fieldPaint);

    final Paint linePaint = Paint()
      ..color = const Color(0x5588B5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final Path fieldLine = Path()
      ..moveTo(size.width * .14, size.height * .72)
      ..quadraticBezierTo(
        size.width * .50,
        size.height * .42,
        size.width * .86,
        size.height * .72,
      );

    canvas.drawPath(fieldLine, linePaint);

    _drawLight(canvas, Offset(size.width * .18, size.height * .23));

    _drawLight(canvas, Offset(size.width * .82, size.height * .25));
  }

  void _drawLight(Canvas canvas, Offset center) {
    final Paint glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xAAFFFFFF), Color(0x001E88FF)],
      ).createShader(Rect.fromCircle(center: center, radius: 35));

    canvas.drawCircle(center, 35, glow);

    final Paint light = Paint()..color = const Color(0xEEFFFFFF);

    for (int x = -2; x <= 2; x++) {
      for (int y = -2; y <= 2; y++) {
        canvas.drawCircle(center + Offset(x * 4.0, y * 4.0), 1.3, light);
      }
    }

    final Paint pole = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..strokeWidth = 1;

    canvas.drawLine(
      center + const Offset(0, 8),
      center + const Offset(0, 62),
      pole,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// =============================================================================
// DATA CLASSES
// =============================================================================

class _GroundCardData {
  const _GroundCardData({
    required this.name,
    required this.location,
    required this.price,
    required this.detail,
    this.imageUrl = '',
    this.imageValues = const [],
    this.rating = 0,
    this.facilities = const [],
    this.groundId = '',
  });

  final String name;
  final String location;
  final String price;
  final String detail;

  final String imageUrl;
  final List imageValues;
  final double rating;
  final List facilities;
  final String groundId;
}

class _InfoCardData {
  const _InfoCardData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String status;
}

class _LedgerCardData {
  const _LedgerCardData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.positive,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final bool positive;
}
