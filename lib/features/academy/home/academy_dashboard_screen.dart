import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/widgets/module_bottom_nav.dart';
import 'academy_add_student_screen.dart';
import 'academy_announcement_screen.dart';
import 'academy_batch_timings_screen.dart';
import 'academy_edit_batch_screen.dart';
import 'academy_fee_details_screen.dart';
import 'academy_manage_students_screen.dart';
import 'academy_mark_attendance_screen.dart';
import 'academy_profile_screen.dart';
import 'academy_view_batch_screen.dart';

class AcademyDashboardScreen extends StatefulWidget {
  const AcademyDashboardScreen({super.key});

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboard = <String, dynamic>{};
  List<Map<String, dynamic>> _batches = <Map<String, dynamic>>[];
  String _selectedBatchFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId);
      final String selectedFilter = _normalizeSelectedFilter(batches);
      final String? selectedBatchId = _batchIdByFilterLabel(
        selectedFilter,
        batches,
      );
      final Map<String, dynamic> dashboard = await GroundWaleApi.instance
          .getAcademyDashboard(ownerId, batchId: selectedBatchId);
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _batches = batches;
        _selectedBatchFilter = selectedFilter;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  String _normalizeSelectedFilter(List<Map<String, dynamic>> batches) {
    if (_selectedBatchFilter == 'All') {
      return 'All';
    }
    final String selectedKey = _selectedBatchFilter.trim().toLowerCase();
    final bool exists = batches.any((Map<String, dynamic> batch) {
      final String name = (batch['name']?.toString() ?? '')
          .trim()
          .toLowerCase();
      return name == selectedKey;
    });
    return exists ? _selectedBatchFilter : 'All';
  }

  String? _batchIdByFilterLabel(
    String label,
    List<Map<String, dynamic>> batches,
  ) {
    if (label == 'All') {
      return null;
    }
    final String query = label.trim().toLowerCase();
    final Map<String, dynamic> found = batches.firstWhere(
      (Map<String, dynamic> batch) =>
          (batch['name']?.toString() ?? '').trim().toLowerCase() == query,
      orElse: () => <String, dynamic>{},
    );
    final String? id = found['_id']?.toString() ?? found['id']?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }

  Future<void> _onBatchFilterTap(String label) async {
    if (label == _selectedBatchFilter) {
      return;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    final String? batchId = _batchIdByFilterLabel(label, _batches);

    setState(() {
      _selectedBatchFilter = label;
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> dashboard = await GroundWaleApi.instance
          .getAcademyDashboard(ownerId, batchId: batchId);
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
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

  String _batchDays(Map<String, dynamic> batch) {
    final List<dynamic> daysRaw =
        batch['days'] as List<dynamic>? ?? <dynamic>[];
    if (daysRaw.isEmpty) {
      return 'Mon - Sat';
    }
    final List<String> days = daysRaw.map((dynamic d) => d.toString()).toList();
    if (days.length == 1) {
      return days.first;
    }
    return '${days.first} - ${days.last}';
  }

  List<Map<String, dynamic>> _filteredBatches() {
    if (_selectedBatchFilter == 'All') {
      return _batches;
    }
    final String query = _selectedBatchFilter.trim().toLowerCase();
    return _batches.where((Map<String, dynamic> batch) {
      final String name = (batch['name']?.toString() ?? '')
          .trim()
          .toLowerCase();
      return name == query;
    }).toList();
  }

  List<String> _batchFilterLabels() {
    final Set<String> seen = <String>{};
    final List<String> labels = <String>['All'];

    for (final Map<String, dynamic> batch in _batches) {
      final String name = (batch['name']?.toString() ?? '').trim();
      if (name.isEmpty) {
        continue;
      }
      final String key = name.toLowerCase();
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      labels.add(name);
    }

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> students = Map<String, dynamic>.from(
      _dashboard['students'] as Map? ?? <String, dynamic>{},
    );
    final Map<String, dynamic> fees = Map<String, dynamic>.from(
      _dashboard['fees'] as Map? ?? <String, dynamic>{},
    );
    final Map<String, dynamic> attendance = Map<String, dynamic>.from(
      _dashboard['attendanceToday'] as Map? ?? <String, dynamic>{},
    );

    final int totalStudents = _toInt(students['total']);
    final int presentToday = _toInt(attendance['present']);
    final int absentToday = attendance.containsKey('absent')
        ? _toInt(attendance['absent'])
        : (totalStudents - presentToday).clamp(0, 1000000);

    final int pendingAmount = _toInt(fees['pendingAmount']);
    final int paidStudents = _toInt(fees['paidStudents']);
    final int pendingStudents = _toInt(fees['pendingStudents']);
    final int monthEarnings = _toInt(
      fees['collectedAmount'] ?? _dashboard['thisMonthEarnings'] ?? 0,
    );

    final List<Map<String, dynamic>> filteredBatches = _filteredBatches();
    final List<String> batchFilterLabels = _batchFilterLabels();

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF00C9A7),
                backgroundColor: const Color(0xFF203A43),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 92),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).maybePop();
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Color(0xFFDDF730),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Good Morning, Akash',
                                style: TextStyle(
                                  color: Color(0xFF7B8A97),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Academy Batch',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x0FFFFFFF),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFFE6F7F4),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: batchFilterLabels.map((String label) {
                          final bool selected = _selectedBatchFilter == label;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _onBatchFilterTap(label),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF1C333B)
                                        : const Color(0x1F242424),
                                  ),
                                  color: selected
                                      ? const Color(0xFF00C9A7)
                                      : const Color(0x0FFFFFFF),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFF242424)
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF1E293B), Color(0xFF334155)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'This Month Earnings',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rs $monthEarnings',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Text(
                                '$paidStudents Paid',
                                style: const TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '•',
                                style: TextStyle(color: Color(0x66FFFFFF)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$pendingStudents Pending',
                                style: const TextStyle(
                                  color: Color(0xFFF97316),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: const Color(0x1AFFFFFF),
                            ),
                            child: const Text(
                              '+12% from last month',
                              style: TextStyle(
                                color: Color(0xE6FFFFFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.03,
                      children: <Widget>[
                        _actionTile(
                          icon: Icons.person_add_alt_1_rounded,
                          label: 'Add Student',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AcademyAddStudentScreen(),
                              ),
                            );
                          },
                          highlighted: true,
                        ),
                        _actionTile(
                          icon: Icons.group_add_rounded,
                          label: 'Add Batch',
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const AcademyBatchTimingsScreen(),
                                  ),
                                )
                                .then((_) => _load());
                          },
                        ),
                        _actionTile(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Manage Student',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const AcademyManageStudentsScreen(),
                              ),
                            );
                          },
                        ),
                        _actionTile(
                          icon: Icons.notifications_active_outlined,
                          label: 'Fees Reminder',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AcademyFeeDetailsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _overlayCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Total Students',
                            style: TextStyle(
                              color: Color(0xFFE6F7F4),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalStudents',
                            style: const TextStyle(
                              color: Color(0xFFE6F7F4),
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Present Today: $presentToday',
                                style: const TextStyle(
                                  color: Color(0xFF9FB9B3),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Absent Today: $absentToday',
                                style: const TextStyle(
                                  color: Color(0xFF9FB9B3),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: presentToday == 0 ? 1 : presentToday,
                                  child: Container(
                                    height: 8,
                                    color: const Color(0xFF22C55E),
                                  ),
                                ),
                                Expanded(
                                  flex: absentToday == 0 ? 1 : absentToday,
                                  child: Container(
                                    height: 8,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _overlayCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Today\'s Attendance',
                            style: TextStyle(
                              color: Color(0xFFE6F7F4),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$presentToday / $totalStudents Present',
                            style: const TextStyle(
                              color: Color(0xFFE6F7F4),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: totalStudents == 0
                                  ? 0
                                  : presentToday / totalStudents,
                              backgroundColor: const Color(0xFF12252B),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF22C55E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const AcademyMarkAttendanceScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9A7),
                                foregroundColor: const Color(0xFF052017),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Mark Attendance',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _overlayCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Fees Collection',
                            style: TextStyle(
                              color: Color(0xFFE6F7F4),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _kvRow(
                            'Paid Students',
                            '$paidStudents',
                            const Color(0xFF22C55E),
                          ),
                          const SizedBox(height: 8),
                          _kvRow(
                            'Pending Fees',
                            '$pendingStudents',
                            const Color(0xFFF97316),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0x33F97316),
                              ),
                              color: const Color(0x1AF97316),
                            ),
                            child: Text(
                              'Rs $pendingAmount Pending Amount',
                              style: const TextStyle(
                                color: Color(0xFFF97316),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const AcademyFeeDetailsScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF203A43),
                                foregroundColor: const Color(0xFFDFF7F0),
                                elevation: 0,
                              ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Manage Batches',
                          style: TextStyle(
                            color: Color(0xFFE6F7F4),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const AcademyBatchTimingsScreen(),
                                  ),
                                )
                                .then((_) => _load());
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF00C9A7),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 246,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredBatches.length,
                        separatorBuilder: (BuildContext _, int index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final Map<String, dynamic> batch =
                              filteredBatches[index];
                          final String name =
                              batch['name']?.toString() ?? 'Batch';
                          final String start =
                              batch['startTime']?.toString() ?? '09:00';
                          final String end =
                              batch['endTime']?.toString() ?? '10:00';
                          final String coach =
                              batch['coachName']?.toString() ?? 'Rahul';
                          final int studentsCount = _toInt(
                            batch['capacity'] ?? batch['studentsCount'],
                          );
                          final String status =
                              (batch['status']?.toString() ?? 'active')
                                  .toLowerCase();

                          return Container(
                            width: 286,
                            padding: const EdgeInsets.all(16),
                            decoration: _overlayCardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Color(0xFFE6F7F4),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: status == 'active'
                                            ? const Color(0x1A22C55E)
                                            : const Color(0x33F97316),
                                      ),
                                      child: Text(
                                        status == 'active'
                                            ? 'ACTIVE'
                                            : status.toUpperCase(),
                                        style: TextStyle(
                                          color: status == 'active'
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFFF97316),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _batchMeta(
                                  Icons.schedule_rounded,
                                  '$start - $end',
                                ),
                                const SizedBox(height: 10),
                                _batchMeta(
                                  Icons.calendar_month_outlined,
                                  _batchDays(batch),
                                ),
                                const SizedBox(height: 10),
                                _batchMeta(
                                  Icons.person_outline_rounded,
                                  'Coach: $coach',
                                ),
                                const SizedBox(height: 10),
                                _batchMeta(
                                  Icons.groups_outlined,
                                  'Students: $studentsCount',
                                ),
                                const Spacer(),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _darkActionButton(
                                        'View Batch',
                                        () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  AcademyViewBatchScreen(
                                                    batchId:
                                                        batch['_id']
                                                            ?.toString() ??
                                                        batch['id']?.toString(),
                                                    batchName: name,
                                                    coachName: coach,
                                                    time: '$start - $end',
                                                    days: _batchDays(batch),
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _darkActionButton('Edit', () {
                                        Navigator.of(context)
                                            .push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    AcademyEditBatchScreen(
                                                      batchId:
                                                          batch['_id']
                                                              ?.toString() ??
                                                          batch['id']
                                                              ?.toString(),
                                                      batchName: name,
                                                      coachName: coach,
                                                      startTime: start,
                                                      endTime: end,
                                                      days:
                                                          (batch['days']
                                                                      as List<
                                                                        dynamic
                                                                      >? ??
                                                                  <dynamic>[])
                                                              .map(
                                                                (
                                                                  dynamic value,
                                                                ) => value
                                                                    .toString(),
                                                              )
                                                              .toList(),
                                                      capacity: _toInt(
                                                        batch['capacity'],
                                                      ),
                                                      status:
                                                          batch['status']
                                                              ?.toString() ??
                                                          'active',
                                                      monthlyFee:
                                                          (batch['monthlyFee']
                                                                  as num?)
                                                              ?.toDouble() ??
                                                          0,
                                                      enrolledStudents: _toInt(
                                                        batch['studentsCount'] ??
                                                            batch['capacity'],
                                                      ),
                                                    ),
                                              ),
                                            )
                                            .then((_) => _load());
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: ModuleBottomNav(
        currentIndex: 0,
        activeColor: const Color(0xFF00C9A7),
        inactiveColor: const Color(0xFF9FB9B3),
        backgroundColor: const Color(0x0FFFFFFF),
        borderColor: const Color(0x1FFFFFFF),
        horizontalPadding: 26,
        bottomPadding: 20,
        items: <ModuleBottomNavItem>[
          ModuleBottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () {},
          ),
          ModuleBottomNavItem(
            icon: Icons.campaign_outlined,
            label: 'Announcement',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AcademyAnnouncementScreen(),
                ),
              );
            },
          ),
          ModuleBottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AcademyProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  BoxDecoration _overlayCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0x1FFFFFFF)),
      color: const Color(0x0AFFFFFF),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: highlighted
              ? const Color(0x0FFFFFFF)
              : const Color(0x08FFFFFF),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: const Color(0xFF00C9A7), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE6F7F4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String key, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          key,
          style: const TextStyle(
            color: Color(0xFF9FB9B3),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _batchMeta(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF9FB9B3)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9FB9B3),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _darkActionButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF203A43),
          foregroundColor: const Color(0xFFDFF7F0),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
