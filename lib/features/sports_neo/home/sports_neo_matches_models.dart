import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class SportsNeoMatchBooking {
  const SportsNeoMatchBooking({
    required this.id,
    required this.teamName,
    required this.groundName,
    required this.location,
    required this.dateLabel,
    required this.timeRange,
    required this.amount,
    required this.playerCount,
    required this.captainName,
    required this.captainPhone,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.notes,
  });

  final String id;
  final String teamName;
  final String groundName;
  final String location;
  final String dateLabel;
  final String timeRange;
  final double amount;
  final int playerCount;
  final String captainName;
  final String captainPhone;
  final String bookingStatus;
  final String paymentStatus;
  final String notes;

  factory SportsNeoMatchBooking.fromMaps(
    Map<String, dynamic> booking,
    Map<String, dynamic> ground,
  ) {
    final String dateLabel = _formatDate(booking['date']?.toString());
    final String startTime = booking['startTime']?.toString() ?? '';
    final String endTime = booking['endTime']?.toString() ?? '';
    return SportsNeoMatchBooking(
      id: booking['_id']?.toString() ?? booking['id']?.toString() ?? '',
      teamName: booking['teamName']?.toString() ?? 'Unknown Team',
      groundName:
          ground['groundName']?.toString() ?? ground['name']?.toString() ?? 'Ground',
      location: ground['city']?.toString() ??
          ground['location']?.toString() ??
          ground['address']?.toString() ??
          'Mohali',
      dateLabel: dateLabel,
      timeRange: endTime.isEmpty ? startTime : '$startTime - $endTime',
      amount: _toDouble(booking['amount']),
      playerCount: _toInt(booking['playerCount']),
      captainName: booking['captainName']?.toString() ??
          booking['teamName']?.toString() ??
          'Captain',
      captainPhone: booking['captainPhone']?.toString() ?? '',
      bookingStatus: booking['bookingStatus']?.toString() ?? 'confirmed',
      paymentStatus: booking['paymentStatus']?.toString() ?? 'paid',
      notes: booking['notes']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Apr 8';
    }
    final DateTime? date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) {
      return raw;
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
    return '${months[date.month - 1]} ${date.day}';
  }
}

class SportsNeoTeamSummary {
  const SportsNeoTeamSummary({
    required this.teamName,
    required this.createdByMe,
    required this.captainName,
    required this.captainPhone,
    required this.playerCount,
    required this.matchesCount,
    required this.totalAmount,
    required this.recentGround,
    required this.recentLocation,
    required this.bookings,
  });

  final String teamName;
  final bool createdByMe;
  final String captainName;
  final String captainPhone;
  final int playerCount;
  final int matchesCount;
  final double totalAmount;
  final String recentGround;
  final String recentLocation;
  final List<SportsNeoMatchBooking> bookings;

  List<SportsNeoPlayerRow> get players {
    final List<SportsNeoPlayerRow> rows = <SportsNeoPlayerRow>[
      SportsNeoPlayerRow(
        name: captainName,
        subtitle: captainPhone.isEmpty ? 'Captain' : captainPhone,
        isCaptain: true,
      ),
    ];

    for (int index = 2; index <= playerCount; index++) {
      rows.add(
        SportsNeoPlayerRow(
          name: 'Player $index',
          subtitle: 'Roster details not available in API',
          isCaptain: false,
        ),
      );
    }
    return rows;
  }
}

class SportsNeoMatchesRepository {
  const SportsNeoMatchesRepository(this._api);

  final GroundWaleApi _api;

  Future<List<SportsNeoTeamSummary>> loadTeams() async {
    final List<Map<String, dynamic>> grounds = await _api.listGrounds();
    final Map<String, Map<String, dynamic>> groundById = <String, Map<String, dynamic>>{};
    final List<SportsNeoMatchBooking> allBookings = <SportsNeoMatchBooking>[];

    for (final Map<String, dynamic> ground in grounds) {
      final String groundId =
          ground['_id']?.toString() ?? ground['id']?.toString() ?? '';
      if (groundId.isEmpty) {
        continue;
      }
      groundById[groundId] = ground;
      try {
        final List<Map<String, dynamic>> bookings = await _api.listBookings(groundId);
        allBookings.addAll(
          bookings.map(
            (Map<String, dynamic> booking) => SportsNeoMatchBooking.fromMaps(
              booking,
              ground,
            ),
          ),
        );
      } catch (_) {}
    }

    if (allBookings.isEmpty) {
      return _fallbackTeams;
    }

    final String contactNumber = ApiSession.instance.contactNumber?.trim() ?? '';
    final String ownerName = ApiSession.instance.ownerName?.trim().toLowerCase() ?? '';
    final Map<String, List<SportsNeoMatchBooking>> grouped =
        <String, List<SportsNeoMatchBooking>>{};

    for (final SportsNeoMatchBooking booking in allBookings) {
      grouped.putIfAbsent(booking.teamName, () => <SportsNeoMatchBooking>[]).add(booking);
    }

    final List<SportsNeoTeamSummary> teams = grouped.entries.map((entry) {
      final List<SportsNeoMatchBooking> bookings = List<SportsNeoMatchBooking>.from(entry.value)
        ..sort((a, b) => b.dateLabel.compareTo(a.dateLabel));
      final SportsNeoMatchBooking recent = bookings.first;
      final int playerCount = bookings.fold<int>(
        0,
        (int current, SportsNeoMatchBooking booking) =>
            booking.playerCount > current ? booking.playerCount : current,
      );
      final bool createdByMe = bookings.any((SportsNeoMatchBooking booking) {
        final bool phoneMatch =
            contactNumber.isNotEmpty && booking.captainPhone.trim() == contactNumber;
        final bool nameMatch = ownerName.isNotEmpty &&
            booking.captainName.trim().toLowerCase() == ownerName;
        return phoneMatch || nameMatch;
      });

      return SportsNeoTeamSummary(
        teamName: entry.key,
        createdByMe: createdByMe,
        captainName: recent.captainName,
        captainPhone: recent.captainPhone,
        playerCount: playerCount == 0 ? 11 : playerCount,
        matchesCount: bookings.length,
        totalAmount: bookings.fold<double>(
          0,
          (double sum, SportsNeoMatchBooking booking) => sum + booking.amount,
        ),
        recentGround: recent.groundName,
        recentLocation: recent.location,
        bookings: bookings,
      );
    }).toList();

    teams.sort((a, b) {
      if (a.createdByMe != b.createdByMe) {
        return a.createdByMe ? -1 : 1;
      }
      return b.matchesCount.compareTo(a.matchesCount);
    });
    return teams;
  }
}

class SportsNeoPlayerRow {
  const SportsNeoPlayerRow({
    required this.name,
    required this.subtitle,
    required this.isCaptain,
  });

  final String name;
  final String subtitle;
  final bool isCaptain;
}

const List<SportsNeoTeamSummary> _fallbackTeams = <SportsNeoTeamSummary>[
  SportsNeoTeamSummary(
    teamName: 'Thunderbolts XI',
    createdByMe: true,
    captainName: 'Rahul Sharma',
    captainPhone: '+91 9876543210',
    playerCount: 11,
    matchesCount: 8,
    totalAmount: 2400,
    recentGround: 'Victory Cricket Stadium',
    recentLocation: 'Sector 118, Mohali',
    bookings: <SportsNeoMatchBooking>[
      SportsNeoMatchBooking(
        id: '',
        teamName: 'Thunderbolts XI',
        groundName: 'Victory Cricket Stadium',
        location: 'Sector 118, Mohali',
        dateLabel: 'Apr 8',
        timeRange: '6:00 AM - 8:00 AM',
        amount: 350,
        playerCount: 11,
        captainName: 'Rahul Sharma',
        captainPhone: '+91 9876543210',
        bookingStatus: 'confirmed',
        paymentStatus: 'paid',
        notes: 'White Ball',
      ),
    ],
  ),
  SportsNeoTeamSummary(
    teamName: 'Manu XI',
    createdByMe: false,
    captainName: 'Manu',
    captainPhone: '',
    playerCount: 11,
    matchesCount: 4,
    totalAmount: 1200,
    recentGround: 'Green Turf Arena',
    recentLocation: 'Sector 62',
    bookings: <SportsNeoMatchBooking>[
      SportsNeoMatchBooking(
        id: '',
        teamName: 'Manu XI',
        groundName: 'Green Turf Arena',
        location: 'Sector 62',
        dateLabel: 'Apr 7',
        timeRange: '7:00 PM - 8:00 PM',
        amount: 500,
        playerCount: 11,
        captainName: 'Manu',
        captainPhone: '',
        bookingStatus: 'confirmed',
        paymentStatus: 'pending',
        notes: '',
      ),
    ],
  ),
];