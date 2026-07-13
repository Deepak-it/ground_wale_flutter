import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';
import 'sports_neo_booking_cart_screen.dart';
import 'sports_neo_manage_teams_screen.dart';
import 'sports_neo_notifications_screen.dart';
import 'sports_neo_onboarding_flow.dart';
import 'sports_neo_settings_screen.dart';

class SportsNeoDashboardScreen extends StatefulWidget {
  const SportsNeoDashboardScreen({super.key});

  @override
  State<SportsNeoDashboardScreen> createState() =>
      _SportsNeoDashboardScreenState();
}

class _SportsNeoDashboardScreenState extends State<SportsNeoDashboardScreen> {
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

  int _selectedTab = 0;
  String _profileName = 'Rahul Sharma';
  String _profilePhone = '+91 9876543210';
  String? _profileImage;
  String _location = 'Sector 118, Mohali';

  List<_GroundCardData> _grounds = const <_GroundCardData>[
    _GroundCardData(
      name: 'Highland Arena',
      location: 'Sector 118, Mohali',
      price: 'Rs 1200/hr',
      detail: 'Lighting',
    ),
    _GroundCardData(
      name: 'TurfPoint 360',
      location: 'Sector 118, Mohali',
      price: 'Rs 1000/hr',
      detail: 'Flood Lights',
    ),
    _GroundCardData(
      name: 'Goal Box',
      location: 'Sector 118, Mohali',
      price: 'Rs 1400/hr',
      detail: 'Parking',
    ),
  ];

  List<_InfoCardData> _teams = const <_InfoCardData>[
    _InfoCardData(
      title: 'Thunder XI',
      subtitle: '11 players',
      amount: '₹2,200',
      status: 'Active',
    ),
    _InfoCardData(
      title: 'Thunder XI',
      subtitle: '11 players',
      amount: '₹1,800',
      status: 'Active',
    ),
    _InfoCardData(
      title: 'Thunder XI',
      subtitle: '11 players',
      amount: '₹2,600',
      status: 'Active',
    ),
  ];

  List<_InfoCardData> _bookings = const <_InfoCardData>[
    _InfoCardData(
      title: 'CitySports Arena',
      subtitle: 'Tomorrow 6:00 AM - 8:00 AM\nThunder XI - Slot #3',
      amount: '₹1,000',
      status: 'Upcoming',
    ),
    _InfoCardData(
      title: 'CitySports Arena',
      subtitle: 'Tomorrow 6:00 AM - 8:00 AM\nThunder XI - Slot #3',
      amount: '₹1,000',
      status: 'Upcoming',
    ),
    _InfoCardData(
      title: 'CitySports Arena',
      subtitle: 'Tomorrow 6:00 AM - 8:00 AM\nThunder XI - Slot #3',
      amount: '₹1,000',
      status: 'Upcoming',
    ),
  ];

  List<_LedgerCardData> _ledger = const <_LedgerCardData>[
    _LedgerCardData(
      title: 'Booking Credit',
      subtitle: 'Thunder XI - 11 players split',
      amount: '₹4,200',
      date: 'Apr 06',
      positive: true,
    ),
    _LedgerCardData(
      title: 'Team Split Settled',
      subtitle: 'Thunder XI - 11 players split',
      amount: '₹3,500',
      date: 'Apr 04',
      positive: false,
    ),
  ];

  int _matchesCount = 24;
  int _teamsCount = 3;
  int _bookingsCount = 12;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadSportsNeoData();
  }

  Future<void> _loadSportsNeoData() async {
    final String? ownerId = ApiSession.instance.ownerId;

    Map<String, dynamic>? profile;
    Map<String, dynamic>? dashboard;
    List<Map<String, dynamic>> grounds = <Map<String, dynamic>>[];

    try {
      grounds = await _api.listGrounds();
    } catch (_) {}

    if (ownerId != null && ownerId.isNotEmpty) {
      try {
        profile = await _api.getOwnerProfile(ownerId);
      } catch (_) {}
      try {
        dashboard = await _api.getDashboard(ownerId);
      } catch (_) {}
      try {
        final List<Map<String, dynamic>> notifications =
            await _api.listNotifications(ownerId);
        _unreadNotifications = notifications
            .where((Map<String, dynamic> item) => item['isRead'] != true)
            .length;
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

    final List<_GroundCardData> mappedGrounds = _mapGrounds(grounds);
    final List<_InfoCardData> mappedTeams = _mapInfoCards(
      _extractMapList(dashboard, <String>['myTeams', 'teams', 'teamList']),
      defaultStatus: 'Active',
      fallbackSubtitle: '11 players',
    );
    final List<_InfoCardData> mappedBookings = _mapInfoCards(
      _extractMapList(dashboard, <String>['myBookings', 'bookings', 'upcomingBookings']),
      defaultStatus: 'Upcoming',
      fallbackSubtitle: 'Tomorrow 6:00 AM - 8:00 AM\nThunder XI - Slot #3',
    );
    final List<_LedgerCardData> mappedLedger = _mapLedgerCards(
      _extractMapList(dashboard, <String>['ledger', 'transactions', 'walletTransactions']),
    );

    final int teamsCount = _intValue(dashboard, <String>['teamsCount']) ??
        mappedTeams.length;
    final int bookingsCount = _intValue(dashboard, <String>['bookingsCount']) ??
        mappedBookings.length;
    final int matchesCount = _intValue(dashboard, <String>['matchesCount']) ??
        _intValue(dashboard, <String>['matches']) ??
        _matchesCount;

    setState(() {
      _profileName = profileName;
      _profilePhone = profilePhone;
      _profileImage = _stringValue(profile, <String>['profileImage', 'image']);
      _location = location;
      if (mappedGrounds.isNotEmpty) {
        _grounds = mappedGrounds;
      }
      if (mappedTeams.isNotEmpty) {
        _teams = mappedTeams;
      }
      if (mappedBookings.isNotEmpty) {
        _bookings = mappedBookings;
      }
      if (mappedLedger.isNotEmpty) {
        _ledger = mappedLedger;
      }
      _matchesCount = matchesCount;
      _teamsCount = teamsCount;
      _bookingsCount = bookingsCount;
    });
  }

  List<_GroundCardData> _mapGrounds(List<Map<String, dynamic>> items) {
    return items.take(3).map((Map<String, dynamic> item) {
      final String name = _stringFromAny(item, <String>['name', 'groundName', 'title']) ??
          'Ground';
      final String location =
          _stringFromAny(item, <String>['location', 'address', 'city']) ??
          _location;
      final String detail = _facilityText(item) ?? 'Lighting';
      final String price = _priceText(item) ?? 'Rs 1200/hr';
      return _GroundCardData(
        name: name,
        location: location,
        price: price,
        detail: detail,
      );
    }).toList();
  }

  List<_InfoCardData> _mapInfoCards(
    List<Map<String, dynamic>> items, {
    required String defaultStatus,
    required String fallbackSubtitle,
  }) {
    return items.take(3).map((Map<String, dynamic> item) {
      final String title =
          _stringFromAny(item, <String>['name', 'teamName', 'title', 'groundName']) ??
          'Untitled';
      final String subtitle = _stringFromAny(item, <String>[
            'subtitle',
            'description',
            'slot',
            'time',
            'players',
          ]) ??
          fallbackSubtitle;
      final String amount = _amountText(item) ?? '₹1,000';
      final String status = _stringFromAny(item, <String>['status']) ?? defaultStatus;
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
          _stringFromAny(item, <String>['title', 'type', 'name']) ??
          'Transaction';
      final String subtitle =
          _stringFromAny(item, <String>['subtitle', 'description']) ??
          'Sports Neo transaction';
      final double? amountValue = _doubleFromAny(item, <String>['amount']);
      final bool positive = amountValue == null ? true : amountValue >= 0;
      final String amount = _formatAmount(amountValue?.abs() ?? 0);
      final String date = _stringFromAny(item, <String>['date', 'createdAt']) ?? 'Today';
      return _LedgerCardData(
        title: title,
        subtitle: subtitle,
        amount: amount,
        date: date,
        positive: positive,
      );
    }).toList();
  }

  String? _priceText(Map<String, dynamic> item) {
    final double? hourly = _doubleFromAny(item, <String>[
      'hourlyPrice',
      'pricePerHour',
      'hourlyRate',
    ]);
    if (hourly == null) {
      return null;
    }
    return 'Rs ${hourly.toStringAsFixed(hourly % 1 == 0 ? 0 : 2)}/hr';
  }

  String? _amountText(Map<String, dynamic> item) {
    final double? amount = _doubleFromAny(item, <String>['amount', 'total', 'price']);
    if (amount == null) {
      return null;
    }
    return _formatAmount(amount);
  }

  String? _facilityText(Map<String, dynamic> item) {
    final dynamic facilities = item['facilities'];
    if (facilities is List && facilities.isNotEmpty) {
      return facilities.first.toString();
    }
    return _stringFromAny(item, <String>['detail', 'feature']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      drawerScrimColor: const Color(0x66000000),
      drawer: _SportsNeoSidebar(
        menuItems: _drawerMenuItems,
        profileName: _profileName,
        profilePhone: _profilePhone,
        profileImage: _profileImage,
        matchesCount: _matchesCount,
        teamsCount: _teamsCount,
        bookingsCount: _bookingsCount,
        onMenuTap: (String label) {
          if (label == 'Settings') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SportsNeoSettingsScreen(),
              ),
            );
            return;
          }
          if (label == 'My Teams' || label == 'My Matches' || label == 'Create Team') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SportsNeoManageTeamsScreen(),
              ),
            );
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Builder(
                    builder: (BuildContext context) {
                      return InkWell(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B253D),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Find Your Ground',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      _HeaderActionIcon(
                        icon: Icons.notifications_none_rounded,
                        badgeCount: _unreadNotifications,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SportsNeoNotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _HeaderActionIcon(
                        icon: Icons.shopping_cart_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SportsNeoBookingCartScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: Color(0xB3FFFFFF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _location,
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0x08FFFFFF),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.search, color: Color(0x99FFFFFF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Search grounds',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.tune_rounded, color: Color(0x99FFFFFF), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Row(
                  children: List<Widget>.generate(_sportsTabs.length, (int i) {
                    final bool active = _selectedTab == i;
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            borderRadius: i == 0
                                ? const BorderRadius.horizontal(
                                    left: Radius.circular(12),
                                  )
                                : i == _sportsTabs.length - 1
                                ? const BorderRadius.horizontal(
                                    right: Radius.circular(12),
                                  )
                                : BorderRadius.zero,
                            border: i != _sportsTabs.length - 1
                                ? const Border(
                                    right: BorderSide(color: Color(0x1FFFFFFF)),
                                  )
                                : null,
                          ),
                          child: Text(
                            _sportsTabs[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionHeader(title: 'Nearby Ground'),
              const SizedBox(height: 10),
              ..._grounds.take(3).map(( _GroundCardData item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GroundCard(
                      name: item.name,
                      location: item.location,
                      price: item.price,
                      detail: item.detail,
                    ),
                  )),
              const SizedBox(height: 2),
              _SectionHeader(
                title: 'My teams',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SportsNeoManageTeamsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ..._teams.take(3).map(( _InfoCardData item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InfoCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      amount: item.amount,
                      status: item.status,
                    ),
                  )),
              const SizedBox(height: 2),
              const _SectionHeader(title: 'My Bookings'),
              const SizedBox(height: 10),
              ..._bookings.take(3).map(( _InfoCardData item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InfoCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      amount: item.amount,
                      status: item.status,
                    ),
                  )),
              const SizedBox(height: 8),
              const Text(
                'Full ledger',
                style: TextStyle(
                  color: Color(0xFF638FEF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              ..._ledger.take(2).map(( _LedgerCardData item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LedgerCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      amount: item.amount,
                      date: item.date,
                      positive: item.positive,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: const Color(0xFF1F2937), size: 20),
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
      width: 281,
      backgroundColor: const Color(0xFF000B2A),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF001651), Color(0xFF091E67)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
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
                            Icons.arrow_forward,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 44,
                        height: 44,
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
                            size: 20,
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
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0x2EFFFFFF), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _DrawerStat(
                          number: '$matchesCount',
                          label: 'matches',
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
                itemBuilder: (BuildContext context, int index) {
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
                height: 44,
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
                      MaterialPageRoute<void>(
                        builder: (_) => const SportsNeoWelcomeScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        InkWell(
          onTap: onTap,
          child: const Text(
            'See all',
            style: TextStyle(
              color: Color(0xFF638FEF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _GroundCard extends StatelessWidget {
  const _GroundCard({
    required this.name,
    required this.location,
    required this.price,
    required this.detail,
  });

  final String name;
  final String location;
  final String price;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x222563EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.sports_soccer, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x222563EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.groups, color: Colors.white, size: 18),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF729BF6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      amount,
                      style: TextStyle(
                        color: positive
                            ? const Color(0xFF3A74E6)
                            : const Color(0xFFD36A6A),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            decoration: const BoxDecoration(
              color: Color(0x0AFFFFFF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
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

class _DrawerStat extends StatelessWidget {
  const _DrawerStat({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
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
            fontSize: 12,
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
          fontSize: 22 / 1.5,
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

class _LedgerSummary extends StatelessWidget {
  const _LedgerSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GroundCardData {
  const _GroundCardData({
    required this.name,
    required this.location,
    required this.price,
    required this.detail,
  });

  final String name;
  final String location;
  final String price;
  final String detail;
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
