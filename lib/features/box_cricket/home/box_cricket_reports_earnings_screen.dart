import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class BoxCricketReportsEarningsScreen extends StatefulWidget {
  const BoxCricketReportsEarningsScreen({super.key});

  @override
  State<BoxCricketReportsEarningsScreen> createState() =>
      _BoxCricketReportsEarningsScreenState();
}

class _BoxCricketReportsEarningsScreenState
    extends State<BoxCricketReportsEarningsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _report = <String, dynamic>{};
  Map<String, dynamic> _wallet = <String, dynamic>{};
  Map<String, dynamic> _bookingSummary = <String, dynamic>{};
  List<Map<String, dynamic>> _allBookings = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? groundId = ApiSession.instance.groundId;
    if (groundId == null || groundId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
            GroundWaleApi.instance.getEarningsReport(groundId),
            GroundWaleApi.instance.getWallet(groundId),
            GroundWaleApi.instance.getBookingSummary(groundId),
            GroundWaleApi.instance.listBookings(groundId),
          ]);

      if (!mounted) {
        return;
      }
      setState(() {
        _report = Map<String, dynamic>.from(results[0] as Map);
        _wallet = Map<String, dynamic>.from(results[1] as Map);
        _bookingSummary = Map<String, dynamic>.from(results[2] as Map);
        _allBookings = (results[3] as List<dynamic>)
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  List<double> _trendValues() {
    final dynamic trendData = _report['trend'] ?? _report['dailyTrend'];
    if (trendData is List) {
      final List<double> values = trendData
          .map((dynamic item) {
            if (item is num) {
              return item.toDouble();
            }
            if (item is Map) {
              final dynamic value = item['value'] ?? item['amount'];
              if (value is num) {
                return value.toDouble();
              }
            }
            return 0.0;
          })
          .where((double value) => value >= 0)
          .toList();
      if (values.isNotEmpty) {
        return values;
      }
    }
    return <double>[8, 12, 10, 16, 14, 18, 15];
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _bookingDate(Map<String, dynamic> booking) {
    final List<String> keys = <String>['date', 'bookingDate', 'slotDate'];
    for (final String key in keys) {
      final String raw = booking[key]?.toString().trim() ?? '';
      if (raw.isEmpty) {
        continue;
      }
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        final DateTime local = parsed.toLocal();
        return _dateOnly(local);
      }
      final RegExpMatch? ymd = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
      if (ymd != null) {
        return DateTime(
          int.parse(ymd.group(1)!),
          int.parse(ymd.group(2)!),
          int.parse(ymd.group(3)!),
        );
      }
    }

    final String createdAt = booking['createdAt']?.toString().trim() ?? '';
    if (createdAt.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        return _dateOnly(parsed.toLocal());
      }
    }
    return null;
  }

  bool _isRejectedBooking(Map<String, dynamic> booking) {
    final String status =
        (booking['bookingStatus']?.toString() ?? '').trim().toLowerCase();
    return status == 'cancelled' || status == 'rejected';
  }

  int _nonRejectedRevenue({DateTime? from, DateTime? to}) {
    int total = 0;
    for (final Map<String, dynamic> booking in _allBookings) {
      if (_isRejectedBooking(booking)) {
        continue;
      }
      final DateTime? bookingDate = _bookingDate(booking);
      if (bookingDate == null) {
        continue;
      }
      if (from != null && bookingDate.isBefore(_dateOnly(from))) {
        continue;
      }
      if (to != null && bookingDate.isAfter(_dateOnly(to))) {
        continue;
      }
      total += _toInt(booking['amount']);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime todayDate = _dateOnly(now);
    final DateTime weekStart = todayDate.subtract(Duration(days: now.weekday - 1));
    final DateTime monthStart = DateTime(now.year, now.month, 1);

    final int fallbackTotal = _toInt(
      _wallet['lifetimeCredit'] ?? _report['totalEarnings'],
    );
    final int totalEarnings =
        _allBookings.isEmpty ? fallbackTotal : _nonRejectedRevenue();
    final int thisMonth = _allBookings.isEmpty
        ? _toInt(_report['thisMonthEarnings'] ?? _report['monthEarnings'])
        : _nonRejectedRevenue(from: monthStart, to: todayDate);
    final int thisWeek = _allBookings.isEmpty
        ? _toInt(_report['thisWeekEarnings'] ?? _report['weekEarnings'])
        : _nonRejectedRevenue(from: weekStart, to: todayDate);
    final int today = _allBookings.isEmpty
        ? _toInt(_report['todayEarnings'])
        : _nonRejectedRevenue(from: todayDate, to: todayDate);

    final int totalBookings = _toInt(
      _bookingSummary['totalBookings'] ?? _report['totalBookings'],
    );
    final int completedBookings = _toInt(
      _bookingSummary['completed'] ??
          _bookingSummary['confirmed'] ??
          _report['completedBookings'],
    );
    final int cancelledBookings = _toInt(
      _bookingSummary['cancelled'] ?? _report['cancelledBookings'],
    );

    final String peakHours =
        _report['peakHours']?.toString() ?? '06:00 PM - 09:00 PM';

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF08B36A),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Reports & Earnings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Total Earnings',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rs $totalEarnings',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _metricChip('Today', 'Rs $today'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricChip('This Week', 'Rs $thisWeek'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricChip(
                                  'This Month',
                                  'Rs $thisMonth',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Earnings Trend',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 120,
                            child: _MiniTrend(values: _trendValues()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Peak Insights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _insightRow('Peak Booking Hours', peakHours),
                          const SizedBox(height: 8),
                          _insightRow(
                            'Most Booked Day',
                            _report['mostBookedDay']?.toString() ?? 'Sunday',
                          ),
                          const SizedBox(height: 8),
                          _insightRow(
                            'Average Booking Value',
                            'Rs ${_toInt(_report['avgBookingValue'])}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Booking Stats',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _statsTile(
                                  title: 'Total',
                                  value: '$totalBookings',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statsTile(
                                  title: 'Completed',
                                  value: '$completedBookings',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statsTile(
                                  title: 'Cancelled',
                                  value: '$cancelledBookings',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Report download will be available soon.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF08B36A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        label: const Text(
                          'Download Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: null,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1FFFFFFF)),
      color: const Color(0x08FFFFFF),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 10,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  Widget _metricChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0x14FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightRow(String title, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _statsTile({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0x0FFFFFFF),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            title,
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
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrend extends StatelessWidget {
  const _MiniTrend({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final double maxValue = values.reduce(
      (double a, double b) => a > b ? a : b,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values.map((double value) {
        final double ratio = maxValue == 0 ? 0 : value / maxValue;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              height: 20 + (ratio * 90),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF08B36A), Color(0xFF00C9A7)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
