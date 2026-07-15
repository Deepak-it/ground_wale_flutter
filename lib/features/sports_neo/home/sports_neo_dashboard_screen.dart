import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';
import 'sports_neo_booking_cart_screen.dart';
import 'sports_neo_ground_detail_screen.dart';
import 'sports_neo_manage_teams_screen.dart';
import 'sports_neo_nearby_grounds_screen.dart';
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
  List<Map<String, dynamic>> _allGroundsRaw = const <Map<String, dynamic>>[];

  List<_GroundCardData> _grounds = const <_GroundCardData>[];

  List<_InfoCardData> _teams = const <_InfoCardData>[];

  List<_InfoCardData> _bookings = const <_InfoCardData>[];

  List<_LedgerCardData> _ledger = const <_LedgerCardData>[];

  int _matchesCount = 0;
  int _teamsCount = 0;
  int _bookingsCount = 0;
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
    List<Map<String, dynamic>> teams = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> ownerBookings = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> ownerLedger = <Map<String, dynamic>>[];

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
        teams = await _api.listTeams(ownerId);
      } catch (_) {}
      try {
        final String? groundId = await _api.ensureGroundIdForOwner(ownerId);
        if (groundId != null && groundId.isNotEmpty) {
          ownerBookings = await _api.listBookings(groundId);
          ownerLedger = await _api.getTransactions(groundId);
        }
      } catch (_) {}
      try {
        final List<Map<String, dynamic>> notifications = await _api
            .listNotifications(ownerId);
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
      _allGroundsRaw = grounds;
      _grounds = mappedGrounds;
      _teams = mappedTeams;
      _bookings = mappedBookings;
      _ledger = mappedLedger;
      _matchesCount = matchesCount;
      _teamsCount = teamsCount;
      _bookingsCount = bookingsCount;
    });
  }

  List<_GroundCardData> _mapGrounds(List<Map<String, dynamic>> items) {
    return items.map((Map<String, dynamic> item) {
      final String name =
          _stringFromAny(item, <String>['name', 'groundName', 'title']) ??
          'Ground';
      final String location =
          _stringFromAny(item, <String>['location', 'address', 'city']) ??
          _location;
      final String detail = _facilityText(item) ?? 'No facility details';
      final String price = _priceText(item) ?? 'N/A';
      final String imageUrl = _groundImageFromAny(item) ?? '';
      final double rating =
          _doubleFromAny(item, <String>['rating', 'groundRating']) ?? 0;
      final List<String> facilities = _facilitiesFromAny(item);
      return _GroundCardData(
        name: name,
        location: location,
        price: price,
        detail: detail,
        imageUrl: imageUrl,
        rating: rating,
        facilities: facilities,
      );
    }).toList();
  }

  String? _groundImageFromAny(Map<String, dynamic> item) {
    final dynamic groundImages = item['groundImages'];
    if (groundImages is List && groundImages.isNotEmpty) {
      final dynamic first = groundImages.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map) {
        final String url = first['url']?.toString().trim() ?? '';
        if (url.isNotEmpty) {
          return url;
        }
      }
    }

    final String image = item['image']?.toString().trim() ?? '';
    if (image.isNotEmpty) {
      return image;
    }

    final String imageUrl = item['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final dynamic photos = item['photos'];
    if (photos is List && photos.isNotEmpty) {
      final dynamic first = photos.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map) {
        return first['url']?.toString();
      }
    }

    return null;
  }

  List<String> _facilitiesFromAny(Map<String, dynamic> item) {
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

  List<_InfoCardData> _mapInfoCards(
    List<Map<String, dynamic>> items, {
    required String defaultStatus,
    required String fallbackSubtitle,
  }) {
    return items.take(3).map((Map<String, dynamic> item) {
      final String title =
          _stringFromAny(item, <String>[
            'name',
            'teamName',
            'title',
            'groundName',
          ]) ??
          'Untitled';
      final String subtitle =
          _stringFromAny(item, <String>[
            'subtitle',
            'description',
            'slot',
            'time',
            'players',
          ]) ??
          fallbackSubtitle;
      final String amount = _amountText(item) ?? 'N/A';
      final String status =
          _stringFromAny(item, <String>['status']) ?? defaultStatus;
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
          _stringFromAny(item, <String>['name', 'teamName', 'title']) ??
          'Untitled Team';
      final int playerCount =
          _intFromAny(item, <String>['playerCount', 'playersCount']) ??
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
          _stringFromAny(item, <String>['groundName', 'name', 'title']) ??
          'Booking';
      final String subtitle =
          _stringFromAny(item, <String>[
            'slotLabel',
            'timeRange',
            'slot',
            'date',
            'startTime',
          ]) ??
          'No booking details available';
      final String amount = _amountText(item) ?? 'N/A';
      final String status =
          _stringFromAny(item, <String>['status', 'bookingStatus']) ??
          'Upcoming';
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
          'Transaction';
      final double? amountValue = _doubleFromAny(item, <String>['amount']);
      final bool positive = amountValue == null ? true : amountValue >= 0;
      final String amount = _formatAmount(amountValue?.abs() ?? 0);
      final String date =
          _stringFromAny(item, <String>['date', 'createdAt']) ?? 'Today';
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
    final double? amount = _doubleFromAny(item, <String>[
      'amount',
      'total',
      'price',
    ]);
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
          if (label == 'My Teams' ||
              label == 'My Matches' ||
              label == 'Create Team') {
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
          padding: const EdgeInsets.only(bottom: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: 160,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF121C3E),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Builder(
                              builder: (BuildContext drawerContext) {
                                return InkWell(
                                  onTap: () =>
                                      Scaffold.of(drawerContext).openDrawer(),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0x26FFFFFF),
                                      borderRadius: BorderRadius.circular(20),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Find Your Ground',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _location,
                                          style: const TextStyle(
                                            color: Color(0xE6FFFFFF),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _HeaderActionIcon(
                              icon: Icons.notifications_none_rounded,
                              badgeCount: _unreadNotifications,
                              backgroundColor: const Color(0x26FFFFFF),
                              iconColor: Colors.white,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const SportsNeoNotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _HeaderActionIcon(
                              icon: Icons.shopping_cart_outlined,
                              backgroundColor: const Color(0x26FFFFFF),
                              iconColor: Colors.white,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const SportsNeoBookingCartScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 15,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(31, 54, 48, 48),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x29000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(
                            Icons.search,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search sports, academies or grounds',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 38),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                        color: const Color(0x0AFFFFFF),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(12),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: <Color>[
                                    Color(0xFF5C8FFF),
                                    Color(0xFF1354E3),
                                  ],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Sports',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                'Academies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 57,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0x0AFFFFFF),
                      ),
                      child: Row(
                        children: List<Widget>.generate(
                          _sportsTabs.length + 1,
                          (int index) {
                            final bool isViewMore = index == _sportsTabs.length;
                            final bool active =
                                !isViewMore && _selectedTab == index;
                            final String label = isViewMore
                                ? 'View More'
                                : _sportsTabs[index];
                            return Expanded(
                              child: InkWell(
                                onTap: isViewMore
                                    ? null
                                    : () =>
                                          setState(() => _selectedTab = index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isViewMore
                                        ? const Color(0x1F2563EB)
                                        : active
                                        ? const Color(0xFF2563EB)
                                        : const Color(0x0AFFFFFF),
                                    borderRadius: index == 0
                                        ? const BorderRadius.horizontal(
                                            left: Radius.circular(12),
                                          )
                                        : index == _sportsTabs.length
                                        ? const BorderRadius.horizontal(
                                            right: Radius.circular(12),
                                          )
                                        : BorderRadius.zero,
                                    border: index < _sportsTabs.length
                                        ? const Border(
                                            right: BorderSide(
                                              color: Color(0x1FFFFFFF),
                                            ),
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isViewMore
                                          ? const Color(0xFF2563EB)
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Nearby Ground',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SportsNeoNearbyGroundsScreen(
                              grounds: _allGroundsRaw,
                              fallbackLocation: _location,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_grounds.isEmpty)
                      const _EmptySectionNotice(
                        message: 'No grounds available right now',
                      )
                    else
                      SizedBox(
                        height: 336,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _grounds.length > 3 ? 3 : _grounds.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (BuildContext context, int index) {
                            final _GroundCardData item = _grounds[index];
                            return _NearbyGroundShowcaseCard(item: item);
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    const _SectionHeader(title: 'Schedule Matches'),
                    const SizedBox(height: 12),
                    if (_bookings.isEmpty)
                      const _EmptySectionNotice(message: 'No scheduled matches')
                    else
                      _CompactBookingCard(item: _bookings.first),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'My teams',
                      actionText: 'Manage',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SportsNeoManageTeamsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_teams.isEmpty)
                      const _EmptySectionNotice(message: 'No teams found')
                    else
                      SizedBox(
                        height: 122,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _teams.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (BuildContext context, int index) {
                            return _TeamGradientCard(item: _teams[index]);
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    const _SectionHeader(title: 'My Bookings'),
                    const SizedBox(height: 12),
                    if (_bookings.isEmpty)
                      const _EmptySectionNotice(message: 'No bookings found')
                    else
                      ..._bookings
                          .take(3)
                          .map(
                            (_InfoCardData item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CompactBookingCard(item: item),
                            ),
                          ),
                    const SizedBox(height: 4),
                    const Text(
                      'Full ledger',
                      style: TextStyle(
                        color: Color(0xFF638FEF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_ledger.isEmpty)
                      const _EmptySectionNotice(
                        message: 'No ledger entries found',
                      )
                    else
                      ..._ledger
                          .take(2)
                          .map(
                            (_LedgerCardData item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _LedgerCard(
                                title: item.title,
                                subtitle: item.subtitle,
                                amount: item.amount,
                                date: item.date,
                                positive: item.positive,
                              ),
                            ),
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
        children: <Widget>[
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
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
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
          child: Text(
            actionText,
            style: const TextStyle(
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

class _NearbyGroundShowcaseCard extends StatelessWidget {
  const _NearbyGroundShowcaseCard({required this.item});

  final _GroundCardData item;

  @override
  Widget build(BuildContext context) {
    final Widget imageFallback = Container(
      color: const Color(0xFF3B4253),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.white54, size: 28),
    );

    final List<String> facilities = item.facilities.isEmpty
        ? <String>[item.detail]
        : item.facilities;

    return Container(
      width: 263,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1F242424)),
        color: const Color(0x0AFFFFFF),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 140,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: buildBase64OrNetworkImage(
                    value: item.imageUrl.isEmpty ? null : item.imageUrl,
                    fit: BoxFit.cover,
                    fallback: imageFallback,
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
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0x99FFFFFF),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: facilities.take(4).map((String feature) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0x0AFFFFFF),
                      ),
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.price,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SportsNeoGroundDetailScreen(
                              name: item.name,
                              location: item.location,
                              image: item.imageUrl,
                              rating: item.rating,
                              facilities: item.facilities,
                              price: item.price,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'View Detail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
        ],
      ),
    );
  }
}

class _CompactBookingCard extends StatelessWidget {
  const _CompactBookingCard({required this.item});

  final _InfoCardData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        color: const Color(0x0AFFFFFF),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0x222563EB),
            ),
            child: const Icon(
              Icons.sports_cricket,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                item.amount,
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
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0x0AFFFFFF),
                ),
                child: Text(
                  item.status,
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

class _TeamGradientCard extends StatelessWidget {
  const _TeamGradientCard({required this.item});

  final _InfoCardData item;

  @override
  Widget build(BuildContext context) {
    const List<List<Color>> gradients = <List<Color>>[
      <Color>[Color(0xFF23336C), Color(0xFF2E59F0)],
      <Color>[Color(0xFF034D2E), Color(0xFF04693E)],
      <Color>[Color(0xFF55236C), Color(0xFFA544D2)],
    ];
    final int indexSeed = item.title.hashCode.abs() % gradients.length;
    final List<Color> colors = gradients[indexSeed];

    return Container(
      width: 141,
      height: 122,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x3D2563EB),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.sports_cricket,
              color: Colors.white,
              size: 18,
            ),
          ),
          const Spacer(),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 12,
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

class _EmptySectionNotice extends StatelessWidget {
  const _EmptySectionNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
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
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 18,
            ),
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
    this.imageUrl = '',
    this.rating = 0,
    this.facilities = const <String>[],
  });

  final String name;
  final String location;
  final String price;
  final String detail;
  final String imageUrl;
  final double rating;
  final List<String> facilities;
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
