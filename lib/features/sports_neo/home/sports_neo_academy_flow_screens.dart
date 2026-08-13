import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';
import '../../../core/widgets/google_city_picker_sheet.dart';
import '../../ground/flow/controllers/ground_flow_controller.dart';
import '../../ground/flow/screens/choose_sports_screen.dart';
import 'sports_neo_booking_history_screen.dart';
import 'sports_neo_choose_team_screen.dart';
import 'sports_neo_dashboard_screen.dart';
import 'sports_neo_ledger_payments_screen.dart';
import 'sports_neo_manage_teams_screen.dart';
import 'sports_neo_onboarding_flow.dart';
import 'sports_neo_settings_screen.dart';
import 'sports_neo_side_bar_screen.dart';
import 'sports_neo_split_payment_flow_screens.dart';

class SportsNeoAcademyDetailScreen extends StatefulWidget {
  const SportsNeoAcademyDetailScreen({super.key, this.selectedCity});

  final String? selectedCity;

  @override
  State<SportsNeoAcademyDetailScreen> createState() =>
      _SportsNeoAcademyDetailScreenState();
}

class _SportsNeoAcademyDetailScreenState
    extends State<SportsNeoAcademyDetailScreen> {
  static const List<String> _sportsTabs = <String>[
    'Cricket',
    'Football',
    'Badminton',
  ];

  static const List<String> _drawerMenuItems = <String>[
    'Ledger & Payments',
    'Booking History',
    'Create Team',
    'My Teams',
    'My Matches',
    'Add a Match',
    'Settings',
  ];

  final GroundWaleApi _api = GroundWaleApi.instance;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _enrollments = <Map<String, dynamic>>[];
  String _selectedSport = 'Cricket';
  String _filterCity = '';

  String _profileName = '';
  String _profilePhone = '';
  String? _profileImage;

  int _matchesCount = 0;
  int _teamsCount = 0;
  int _bookingsCount = 0;

  String? get _playerId => ApiSession.instance.ownerId;


  String get _selectedSportLabel => _selectedSport;
  String? get _selectedCityFilter {
    final String city = _filterCity.trim();
    return city.isEmpty ? null : city;
  }
  bool isTabSelected(int index) {
    return _normalizeSportKey(_selectedSport) ==
        _normalizeSportKey(_sportsTabs[index]);
  }

  bool get isViewMoreSelected {
    return !_sportsTabs.any(
      (sport) =>
          _normalizeSportKey(sport) ==
          _normalizeSportKey(_selectedSport),
    );
  }
  String get _selectedSportFilter => _selectedSportLabel.toLowerCase();

  @override
  void initState() {
    super.initState();

    final String explicit = widget.selectedCity?.trim() ?? '';
    if (explicit.isNotEmpty) {
      _filterCity = explicit;
    } else {
      final String sessionCity = ApiSession.instance.city?.trim() ?? '';
      _filterCity = sessionCity;
    }

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String? playerId = _playerId;
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _api.discoverAcademies(
            playerId: playerId,
            city: _selectedCityFilter,
            sport: _selectedSportFilter,
          ),
          if (playerId != null && playerId.isNotEmpty)
            _api.listPlayerAcademyEnrollments(playerId)
          else
            Future<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]),
          if (playerId != null && playerId.isNotEmpty)
            _api.getOwnerProfile(playerId)
          else
            Future<Map<String, dynamic>?>.value(null),
          if (playerId != null && playerId.isNotEmpty)
            _api.getDashboard(playerId)
          else
            Future<Map<String, dynamic>?>.value(null),
        ],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        final Map<String, dynamic>? profile =
            results[2] as Map<String, dynamic>?;
        final Map<String, dynamic>? dashboard =
            results[3] as Map<String, dynamic>?;

        final String profileName =
            _stringFromAny(profile, <String>[
              'ownerName',
              'name',
              'fullName',
            ]) ??
            (ApiSession.instance.ownerName ?? _profileName);
        final String profilePhone =
            _stringFromAny(profile, <String>[
              'contactNumber',
              'phone',
              'mobile',
            ]) ??
            (ApiSession.instance.contactNumber ?? _profilePhone);

        _academies = (results[0] as List<dynamic>)
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();
        _enrollments = (results[1] as List<dynamic>)
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();

        _profileName = profileName;
        _profilePhone = profilePhone;
        _profileImage = _stringFromAny(profile, <String>[
          'profileImage',
          'image',
        ]);

        _matchesCount =
            _intFromAny(dashboard, <String>['matchesCount', 'matches']) ??
            _matchesCount;
        _teamsCount =
            _intFromAny(dashboard, <String>['teamsCount']) ?? _teamsCount;
        _bookingsCount =
            _intFromAny(dashboard, <String>['bookingsCount']) ?? _bookingsCount;

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

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

    await _applyCityFilter(selection.city);
  }

  Future<void> _applyCityFilter(String city) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _filterCity = city.trim();
    });

    await _load();
  }

  Future<void> _applySportFilter(int index) async {
    if (!mounted) return;

    setState(() {
      _selectedSport = _sportsTabs[index];
    });

    await _load();
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
  Future<void> _applyCustomSportFilter(String sport) async {
    if (!mounted) return;

    setState(() {
      _selectedSport = sport.trim();
    });

    await _load();
  }

  String _normalizeSportKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String? _stringFromAny(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) {
      return null;
    }

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

  int? _intFromAny(Map<String, dynamic>? map, List<String> keys) {
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

  Widget _buildTopShell(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 180,
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
                    child: Container(
                      height: 105,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x002563EB),
                            Color(0x552563EB),
                            Color(0x9920A95C),
                          ],
                        ),
                      ),
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
                              return InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () {
                                  Scaffold.of(drawerContext).openDrawer();
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0x22FFFFFF),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.menu_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Find Your Academy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
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
                                          _filterCity.isEmpty
                                              ? 'All cities'
                                              : _filterCity,
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

                          InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SportsNeoBookingHistoryScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0x25FFFFFF),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),

                      const Text(
                        'Train. Improve. Repeat.',
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

          Positioned(left: 16, right: 16, bottom: 25, child: _buildSearchBar()),
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
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            children: <Widget>[
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
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const SportsNeoDashboardScreen(),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_soccer_rounded,
                  color: Color(0xFF475569),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Sports',
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
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Academies',
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
        ),
      ],
    ),
  );
}

  Widget _buildSportSelector() {
    const List<IconData> icons = <IconData>[
      Icons.sports_cricket_rounded,
      Icons.sports_soccer_rounded,
      Icons.sports_tennis_rounded,
    ];

    return SizedBox(
      height: 92,
      child: Row(
        children: <Widget>[
          for (int index = 0; index < 3; index++) ...<Widget>[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: _isLoading ? null : () => _applySportFilter(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isTabSelected(index)
                        ? const Color(0xFF315CF4)
                        : const Color(0xFF101C2D),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isTabSelected(index)
                          ? const Color(0xFF4F74FF)
                          : const Color(0x1FFFFFFF),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
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
              onTap: _isLoading ? null : _showMoreSports,
              child: Container(
                decoration: BoxDecoration(
                  color: isViewMoreSelected
                      ? const Color(0xFF315CF4)
                      : const Color(0xFF101C2D),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isViewMoreSelected
                        ? const Color(0xFF4F74FF)
                        : const Color(0x1FFFFFFF),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.grid_view_rounded,
                      color: isViewMoreSelected
                          ? Colors.white
                          : const Color(0xFFCBD5E1),
                      size: 27,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      isViewMoreSelected ? _selectedSport : 'View More',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isViewMoreSelected
                            ? Colors.white
                            : const Color(0xFF60A5FA),
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
          children: <Widget>[
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
                children: <Widget>[
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

  Future<void> _openAcademy(Map<String, dynamic> academy) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _SportsNeoAcademyOverviewScreen(
          academy: academy,
          playerId: _playerId,
          playerName: ApiSession.instance.ownerName ?? '',
          playerPhone: ApiSession.instance.contactNumber ?? '',
        ),
      ),
    );

    if (changed == true) {
      await _load();
    }
  }

  List<Map<String, dynamic>> get _enrolledAcademies {
    return _enrollments
        .map((Map<String, dynamic> item) {
          final dynamic academy = item['academy'];
          if (academy is Map) {
            final Map<String, dynamic> normalized = Map<String, dynamic>.from(
              academy,
            );
            normalized['enrollment'] = item;
            normalized['isEnrolled'] = true;
            return normalized;
          }
          return <String, dynamic>{};
        })
        .where((Map<String, dynamic> item) => item.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> enrolledAcademies = _enrolledAcademies;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      drawerScrimColor: const Color(0x99000000),
      drawer: SportsNeoSidebar(
        menuItems: _drawerMenuItems,
        profileName: _profileName,
        profilePhone: _profilePhone,
        profileImage: _profileImage,
        matchesCount: _matchesCount,
        teamsCount: _teamsCount,
        bookingsCount: _bookingsCount,
        onMenuTap: _handleDrawerMenu,
        onLogout: () {
          ApiSession.instance.clear();

          if (!context.mounted) {
            return;
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SportsNeoWelcomeScreen()),
            (_) => false,
          );
        },
      ),

      body: SafeArea(
        bottom: false,
        child: _error != null
            ? _AcademyErrorState(message: _error!, onRetry: _load)
            : RefreshIndicator(
                color: const Color(0xFF2563EB),
                onRefresh: _load,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: <Widget>[
                    _buildTopShell(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildSportsAcademySwitcher(context),
                          const SizedBox(height: 14),
                          _buildSportSelector(),
                          const SizedBox(height: 16),
                          _buildCityFilter(),
                          const SizedBox(height: 18),
                          if (_isLoading)
                            const _AcademiesLoadingNotice()
                          else ...<Widget>[
                            _AcademySectionHeader(
                              title: 'Nearby Academies',
                              subtitle: _selectedCityFilter == null
                                  ? 'Discover $_selectedSportLabel academies across all cities'
                                  : 'Discover $_selectedSportLabel academies in ${_selectedCityFilter!}',
                              actionText: 'See all',
                              onTap: _academies.isEmpty
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => _AcademyListScreen(
                                            academies: _academies,
                                            cityLabel: _selectedCityFilter,
                                            sportLabel: _selectedSportLabel,
                                            onOpenAcademy: _openAcademy,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                            const SizedBox(height: 12),
                            if (_academies.isEmpty)
                              const _AcademyEmptyCard(
                                message:
                                    'No academies found for the selected city.',
                              )
                            else
                              SizedBox(
                                height: 360,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _academies.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (_, int index) {
                                    final Map<String, dynamic> academy =
                                        _academies[index];
                                    return SizedBox(
                                      width: 270,
                                      child: _AcademyListCard(
                                        academy: academy,
                                        enrolled: academy['isEnrolled'] == true,
                                        onTap: () => _openAcademy(academy),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 22),
                            _AcademySectionHeader(
                              title: 'My Academies',
                              subtitle: enrolledAcademies.isEmpty
                                  ? 'Your joined academies will appear here'
                                  : 'Your enrolled academies',
                            ),
                            const SizedBox(height: 12),
                            if (enrolledAcademies.isEmpty)
                              const _AcademyEmptyCard(
                                message: 'You have not joined any academy yet.',
                              )
                            else
                              SizedBox(
                                height: 146,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: enrolledAcademies.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (_, int index) {
                                    final Map<String, dynamic> academy =
                                        enrolledAcademies[index];
                                    return _MyAcademyCard(
                                      academy: academy,
                                      onTap: () => _openAcademy(academy),
                                    );
                                  },
                                ),
                              ),
                          ],
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

class _AcademyListScreen extends StatelessWidget {
  const _AcademyListScreen({
    required this.academies,
    required this.cityLabel,
    required this.sportLabel,
    required this.onOpenAcademy,
  });

  final List<Map<String, dynamic>> academies;
  final String? cityLabel;
  final String sportLabel;
  final Future<void> Function(Map<String, dynamic> academy) onOpenAcademy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121C3E),
        foregroundColor: Colors.white,
        title: Text(
          cityLabel == null
              ? '$sportLabel Academies'
              : '$cityLabel $sportLabel Academies',
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: academies.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, int index) {
          final Map<String, dynamic> academy = academies[index];
          return _AcademyListCard(
            academy: academy,
            enrolled: academy['isEnrolled'] == true,
            onTap: () async {
              await onOpenAcademy(academy);
            },
          );
        },
      ),
    );
  }
}

class _SportsNeoAcademyOverviewScreen extends StatefulWidget {
  const _SportsNeoAcademyOverviewScreen({
    required this.academy,
    required this.playerId,
    required this.playerName,
    required this.playerPhone,
  });

  final Map<String, dynamic> academy;
  final String? playerId;
  final String playerName;
  final String playerPhone;

  @override
  State<_SportsNeoAcademyOverviewScreen> createState() =>
      _SportsNeoAcademyOverviewScreenState();
}

class _SportsNeoAcademyOverviewScreenState
    extends State<_SportsNeoAcademyOverviewScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;

  late Map<String, dynamic> _academy;
  late int _selectedBatchIndex;
  int _selectedPlanIndex = 0;
  bool _isJoining = false;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _academy = Map<String, dynamic>.from(widget.academy);
    _selectedBatchIndex = _resolveInitialBatchIndex();
  }

  int _resolveInitialBatchIndex() {
    final List<Map<String, dynamic>> batches = _batches;
    final String enrolledBatchId = _text(_enrollment['batchId']);
    if (enrolledBatchId.isEmpty) {
      return 0;
    }
    for (int index = 0; index < batches.length; index++) {
      if (_text(batches[index]['_id']) == enrolledBatchId) {
        return index;
      }
    }
    return 0;
  }

  List<Map<String, dynamic>> get _batches => _mapList(_academy['batches']);
  Map<String, dynamic> get _selectedFeePlan {
    if (_feePlans.isEmpty) {
      return <String, dynamic>{};
    }

    final int safeIndex =
        _selectedPlanIndex.clamp(0, _feePlans.length - 1);

    return _feePlans[safeIndex];
  }
  Map<String, dynamic> get _selectedBatch {
    if (_batches.isEmpty) {
      return <String, dynamic>{};
    }
    final int safeIndex = _selectedBatchIndex.clamp(0, _batches.length - 1);
    return _batches[safeIndex];
  }

  Map<String, dynamic> get _enrollment {
    final dynamic data = _academy['enrollment'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  bool get _isEnrolled => _academy['isEnrolled'] == true;

  List<Map<String, dynamic>> get _feePlans =>
      _mapList(_selectedBatch['feePlans']);

  Future<void> _joinAcademy() async {
    final String? playerId = widget.playerId;
    if (playerId == null || playerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to join academy')),
      );
      return;
    }
    if (_isEnrolled) {
      return;
    }

    setState(() => _isJoining = true);
    try {
      final Map<String, dynamic> student = await _api
          .joinAcademy(playerId, <String, dynamic>{
            'academyId': _text(_academy['_id']),
            if (_text(_selectedBatch['_id']).isNotEmpty)
              'batchId': _text(_selectedBatch['_id']),
            'batchName': _text(_selectedBatch['name']),
            'planIndex': _selectedPlanIndex,
            'fullName': widget.playerName,
            'phone': widget.playerPhone,
          });

      if (!mounted) {
        return;
      }

      setState(() {
        _academy = <String, dynamic>{
          ..._academy,
          'isEnrolled': true,
          'enrollment': student,
        };
        _didChange = true;
        _isJoining = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined academy successfully')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

Future<void> _showAllPlans() async {
  final List<Map<String, dynamic>> plans = _feePlans;

  if (plans.isEmpty) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'All Plans',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              for (int index = 0; index < plans.length; index++) ...<Widget>[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlanIndex = index;
                    });

                    Navigator.of(sheetContext).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: index == _selectedPlanIndex
                          ? const Color(0x332563EB)
                          : const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: index == _selectedPlanIndex
                            ? const Color(0xFF2563EB)
                            : const Color(0x1FFFFFFF),
                        width: index == _selectedPlanIndex ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _text(plans[index]['duration']).isEmpty
                                    ? 'Plan ${index + 1}'
                                    : _text(plans[index]['duration']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _priceLabel(plans[index]['price']),
                                style: const TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index == _selectedPlanIndex)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2563EB),
                            size: 24,
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
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> batch = _selectedBatch;
    final Map<String, dynamic> primaryPlan = _selectedFeePlan;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121C3E),
        foregroundColor: Colors.white,
        title: Text(
          _text(_academy['name']).isEmpty ? 'Academy' : _text(_academy['name']),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_didChange),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          _AcademyHeroCard(academy: _academy),
          const SizedBox(height: 16),
          if (_isEnrolled) ...<Widget>[
            _SectionCard(
              title: 'Membership',
              child: Column(
                children: <Widget>[
                  const _InfoRow(
                    label: 'Status',
                    value: 'Enrolled',
                    valueColor: Color(0xFF4ADE80),
                  ),
                  _InfoRow(
                    label: 'Batch',
                    value: _text(_enrollment['batchName']).isEmpty
                        ? _text(batch['name'])
                        : _text(_enrollment['batchName']),
                  ),
                  _InfoRow(
                    label: 'Joined On',
                    value: _formatDate(_text(_enrollment['joinDate'])),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SectionCard(
            title: 'Available Batches',
            child: _batches.isEmpty
                ? const Text(
                    'No batches available right now.',
                    style: TextStyle(color: Colors.white70),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List<Widget>.generate(_batches.length, (
                      int index,
                    ) {
                      final Map<String, dynamic> item = _batches[index];
                      final bool active = index == _selectedBatchIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBatchIndex = index;
                            _selectedPlanIndex = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF2563EB)
                                : const Color(0x0AFFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF2563EB)
                                  : const Color(0x1FFFFFFF),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _text(item['name']).isEmpty
                                    ? 'Batch ${index + 1}'
                                    : _text(item['name']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timeRange(item),
                                style: const TextStyle(
                                  color: Color(0xCCDBEAFE),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Pricing',
            trailing: _feePlans.length > 1
                ? TextButton(
                    onPressed: _showAllPlans,
                    child: const Text('See All'),
                  )
                : null,
            child: Column(
              children: <Widget>[
                _InfoRow(
                  label: 'Plan',
                  value: _text(primaryPlan['duration']).isEmpty
                      ? 'Default'
                      : _text(primaryPlan['duration']),
                ),
                _InfoRow(
                  label: 'Price',
                  value: _priceLabel(
                    _text(primaryPlan['price']).isEmpty
                        ? batch['monthlyFee']
                        : primaryPlan['price'],
                  ),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Batch Details',
            child: Column(
              children: <Widget>[
                _InfoRow(
                  label: 'Capacity',
                  value: _toInt(batch['capacity']) > 0
                      ? '${_toInt(batch['capacity'])} players'
                      : '--',
                ),
                _InfoRow(label: 'Coaching Days', value: _daysLabel(batch)),
                _InfoRow(
                  label: 'Timing',
                  value: _timeRange(batch),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Coach Details',
            child: Column(
              children: <Widget>[
                _InfoRow(
                  label: 'Coach',
                  value: _text(batch['coachName']).isEmpty
                      ? 'Not added yet'
                      : _text(batch['coachName']),
                ),
                _InfoRow(
                  label: 'Experience',
                  value: _toInt(batch['coachExperience']) > 0
                      ? '${_toInt(batch['coachExperience'])} years'
                      : '--',
                ),
                _InfoRow(
                  label: 'Phone',
                  value: _text(batch['coachNumber']).isEmpty
                      ? '--'
                      : _text(batch['coachNumber']),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isEnrolled || _isJoining ? null : _joinAcademy,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isJoining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEnrolled ? 'Already Enrolled' : 'Join Batch',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AcademySectionHeader extends StatelessWidget {
  const _AcademySectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
              ),
            ],
          ),
        ),
        if (actionText != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(actionText!)),
      ],
    );
  }
}

class _MyAcademyCard extends StatelessWidget {
  const _MyAcademyCard({required this.academy, required this.onTap});

  final Map<String, dynamic> academy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> enrollment = academy['enrollment'] is Map
        ? Map<String, dynamic>.from(academy['enrollment'] as Map)
        : <String, dynamic>{};

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              _text(academy['name']).isEmpty
                  ? 'Academy'
                  : _text(academy['name']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _text(enrollment['batchName']).isEmpty
                  ? _locationLabel(academy)
                  : _text(enrollment['batchName']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xD9FFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcademyListCard extends StatelessWidget {
  const _AcademyListCard({
    required this.academy,
    required this.enrolled,
    required this.onTap,
  });

  final Map<String, dynamic> academy;
  final bool enrolled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> batches = _mapList(academy['batches']);
    final Map<String, dynamic> firstBatch = batches.isNotEmpty
        ? batches.first
        : <String, dynamic>{};
    final List<Map<String, dynamic>> feePlans = _mapList(
      firstBatch['feePlans'],
    );
    final Map<String, dynamic> firstPlan = feePlans.isNotEmpty
        ? feePlans.first
        : <String, dynamic>{};

        final List<String> facilities =
    _academyFacilities(academy, firstBatch).take(2).toList();
    final String headerLabel = _academyHeaderLabel(academy, firstBatch);
    final String statusLabel = _academyStatusLabel(
      academy,
      firstBatch,
      enrolled,
    );
    final String location = _locationLabel(academy);
    final List<String> imageValues = _academyImageValues(academy);
    final String price = _priceLabel(
      _text(firstPlan['price']).isEmpty
          ? firstBatch['monthlyFee']
          : firstPlan['price'],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x14FFFFFF)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 152,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _AcademyImageCarousel(
                      imageValues: imageValues,
                      fallback: const _AcademyImageFallback(),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.transparent,
                            const Color(0x66000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _ImageBadge(label: headerLabel),
                    ),
                    if (statusLabel.isNotEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _ImageBadge(label: statusLabel),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _text(academy['name']).isEmpty
                              ? 'Academy'
                              : _text(academy['name']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (enrolled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Enrolled',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF667084),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF98A2B3),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: facilities
                        .map((String item) => _AcademyFacilityChip(label: item))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _text(firstPlan['duration']).isEmpty
                                    ? 'Monthly Plan'
                                    : _text(firstPlan['duration']),
                                style: const TextStyle(
                                  color: Color(0xFF98A2B3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                price,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'View Batch',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcademyHeroCard extends StatelessWidget {
  const _AcademyHeroCard({required this.academy});

  final Map<String, dynamic> academy;

  @override
  Widget build(BuildContext context) {
    final List<String> imageValues = _academyImageValues(academy);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF111827),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: _AcademyImageCarousel(
                imageValues: imageValues,
                fallback: const _AcademyImageFallback(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _text(academy['name']).isEmpty
                      ? 'Academy'
                      : _text(academy['name']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _locationLabel(academy),
                  style: const TextStyle(
                    color: Color(0xCCDBEAFE),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _textList(
                    academy['sports'],
                  ).map((String sport) => _MiniChip(label: sport)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyImageFallback extends StatelessWidget {
  const _AcademyImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      alignment: Alignment.center,
      child: const Icon(
        Icons.school_rounded,
        color: Color(0xFF93C5FD),
        size: 52,
      ),
    );
  }
}

class _AcademyImageCarousel extends StatefulWidget {
  const _AcademyImageCarousel({
    required this.imageValues,
    required this.fallback,
  });

  final List<String> imageValues;
  final Widget fallback;

  @override
  State<_AcademyImageCarousel> createState() => _AcademyImageCarouselState();
}

class _AcademyImageCarouselState extends State<_AcademyImageCarousel> {
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
  void didUpdateWidget(covariant _AcademyImageCarousel oldWidget) {
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

  void _precacheImages(List<String> imageValues) {
    for (final String value in imageValues) {
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
      children: <Widget>[
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
            return buildBase64OrNetworkImage(
              value: widget.imageValues[index],
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x142563EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFBFDBFE),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD242424),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AcademyFacilityChip extends StatelessWidget {
  const _AcademyFacilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x0AEAF4FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyEmptyCard extends StatelessWidget {
  const _AcademyEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}

class _AcademyErrorState extends StatelessWidget {
  const _AcademyErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.white70, size: 42),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _AcademiesLoadingNotice extends StatelessWidget {
  const _AcademiesLoadingNotice();

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
        children: <Widget>[
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
              'Fetching academies for selected sport...',
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

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is List<dynamic>) {
    return value
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

List<String> _textList(dynamic value) {
  if (value is List<dynamic>) {
    return value
        .map((dynamic item) => _text(item))
        .where((String item) => item.isNotEmpty)
        .toList();
  }
  return <String>[];
}

String _text(dynamic value) => value?.toString().trim() ?? '';

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_text(value)) ?? 0;
}

List<String> _academyImageValues(Map<String, dynamic> academy) {
  final List<String> values = <String>[];

  void addIfValid(dynamic raw) {
    final String value = _text(raw);
    if (value.isEmpty || values.contains(value)) {
      return;
    }
    values.add(value);
  }

  final dynamic groundImages = academy['groundImages'];
  if (groundImages is List) {
    for (final dynamic entry in groundImages) {
      if (entry is Map) {
        addIfValid(entry['url']);
      } else {
        addIfValid(entry);
      }
    }
  }

  final dynamic imageUrls = academy['imageUrls'];
  if (imageUrls is List) {
    for (final dynamic entry in imageUrls) {
      if (entry is Map) {
        addIfValid(entry['url']);
      } else {
        addIfValid(entry);
      }
    }
  }

  final dynamic photos = academy['photos'];
  if (photos is List) {
    for (final dynamic entry in photos) {
      if (entry is Map) {
        addIfValid(entry['url']);
      } else {
        addIfValid(entry);
      }
    }
  }

  final dynamic images = academy['images'];
  if (images is List) {
    for (final dynamic entry in images) {
      if (entry is Map) {
        addIfValid(entry['url']);
      } else {
        addIfValid(entry);
      }
    }
  }

  addIfValid(academy['image']);
  addIfValid(academy['imageUrl']);

  return values;
}

String _priceLabel(dynamic value) {
  final String text = _text(value);
  if (text.isEmpty) {
    return '--';
  }
  if (text.contains('₹')) {
    return text;
  }
  return '₹$text';
}

String _locationLabel(Map<String, dynamic> academy) {
  final String city = _text(academy['city']);
  final String state = _text(academy['state']);
  if (city.isNotEmpty && state.isNotEmpty) {
    return '$city, $state';
  }
  return city.isNotEmpty
      ? city
      : (state.isNotEmpty ? state : 'Location unavailable');
}

String _daysLabel(Map<String, dynamic> batch) {
  final List<String> days = _textList(batch['days']);
  if (days.isEmpty) {
    return '--';
  }
  return days.join(', ');
}

String _timeRange(Map<String, dynamic> batch) {
  final String start = _text(batch['startTime']);
  final String end = _text(batch['endTime']);
  if (start.isEmpty && end.isEmpty) {
    return 'Time not added';
  }
  if (start.isEmpty) {
    return end;
  }
  if (end.isEmpty) {
    return start;
  }
  return '$start - $end';
}

String _formatDate(String raw) {
  if (raw.isEmpty) {
    return '--';
  }
  final DateTime? parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) {
    return '--';
  }
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

List<String> _academyFacilities(
  Map<String, dynamic> academy,
  Map<String, dynamic> batch,
) {
  final List<String> chips = <String>[];

  void addChip(String value) {
    final String text = _text(value);
    if (text.isEmpty || chips.contains(text)) {
      return;
    }
    chips.add(text);
  }

  for (final String facility in _textList(academy['facilities'])) {
    addChip(facility);
  }

  final String coachName = _text(batch['coachName']);
  if (coachName.isNotEmpty) {
    addChip('Coach Available');
  }

  final String category = _text(batch['category']);
  if (category.isNotEmpty) {
    addChip(category);
  }

  final int capacity = _toInt(batch['capacity']);
  if (capacity > 0) {
    addChip('$capacity Seats');
  }

  return chips.take(6).toList();
}

String _academyHeaderLabel(
  Map<String, dynamic> academy,
  Map<String, dynamic> batch,
) {
  final String category = _text(batch['category']);
  if (category.isNotEmpty) {
    return category;
  }
  final List<String> sports = _textList(academy['sports']);
  if (sports.isNotEmpty) {
    return sports.first;
  }
  return 'Academy';
}

String _academyStatusLabel(
  Map<String, dynamic> academy,
  Map<String, dynamic> batch,
  bool enrolled,
) {
  if (enrolled) {
    return 'Enrolled';
  }
  if (_text(batch['coachName']).isNotEmpty) {
    return 'Coach Available';
  }
  final String city = _text(academy['city']);
  return city.isNotEmpty ? city : '';
}
