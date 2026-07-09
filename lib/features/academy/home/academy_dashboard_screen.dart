import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/ist_greeting.dart';
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
  const AcademyDashboardScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboard = <String, dynamic>{};
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  String? _selectedAcademyId;
  List<Map<String, dynamic>> _batches = <Map<String, dynamic>>[];
  String _selectedBatchFilter = 'All';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  String _academyId(Map<String, dynamic> academy) {
    return academy['_id']?.toString() ?? academy['id']?.toString() ?? '';
  }

  String _academyName(Map<String, dynamic> academy) {
    final String name = academy['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'Academy' : name;
  }

  String? _academyImageUrl(Map<String, dynamic> academy) {
    final List<String> keys = <String>[
      'imageUrl',
      'coverImage',
      'bannerImage',
      'photoUrl',
      'image',
    ];
    for (final String key in keys) {
      final String value = academy[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _monthLabel(DateTime date) {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<int> _buildWeeklySeries(int monthEarnings, int paidStudents, int pendingStudents) {
    final int base = math.max(monthEarnings, 1);
    final int weeklyBase = math.max((base / 5).round(), 1);
    final int momentum = (paidStudents - pendingStudents).clamp(-5, 5);
    final List<int> values = <int>[
      weeklyBase + momentum,
      (weeklyBase * 2) + momentum,
      (weeklyBase * 3) + momentum,
      (weeklyBase * 4) + momentum,
      base + momentum,
    ];
    return values.map((int value) => math.max(value, 1)).toList();
  }

  String _ordinalLabel(int index) {
    switch (index) {
      case 0:
        return '1st';
      case 1:
        return '2nd';
      case 2:
        return '3rd';
      case 3:
        return '4th';
      default:
        return '5th';
    }
  }

  List<String> _academyFacilities(Map<String, dynamic> academy) {
    final List<dynamic> raw = (academy['facilities'] as List<dynamic>?) ??
        (academy['amenities'] as List<dynamic>?) ??
        (academy['features'] as List<dynamic>?) ??
        <dynamic>[];

    final List<String> values = raw
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    if (values.isNotEmpty) {
      return values;
    }

    return <String>[
      'Parking',
      'Washroom',
      'Water',
      'Lighting',
      'Ball Machine',
      'Hard Court',
    ];
  }

  String _facilityLabel(String value) {
    final String key = value.trim().toLowerCase();
    if (key.contains('park')) {
      return '🅿️ Parking';
    }
    if (key.contains('wash')) {
      return '🚻 Washroom';
    }
    if (key.contains('water')) {
      return '💧 Water';
    }
    if (key.contains('light')) {
      return '💡 Lighting';
    }
    if (key.contains('ball')) {
      return '🎾 Ball Machine';
    }
    if (key.contains('court')) {
      return '🎾 Hard Court';
    }
    return value;
  }

  int _academyMonthlyFee(Map<String, dynamic> academy) {
    final dynamic direct = academy['monthlyFee'] ?? academy['monthlyFees'];
    if (direct is int) {
      return direct;
    }
    if (direct is double) {
      return direct.round();
    }
    if (direct is String) {
      return int.tryParse(direct) ?? 0;
    }
    return 0;
  }

  Widget _academyImageWidget(String? imageValue) {
    if (imageValue == null || imageValue.trim().isEmpty) {
      return Container(
        color: const Color(0xFF1B2F38),
        alignment: Alignment.center,
        child: const Icon(
          Icons.school_outlined,
          color: Color(0xFF9FB9B3),
          size: 30,
        ),
      );
    }

    final String source = imageValue.trim();

    // Accept values like: data:image/png;base64,AAAA...
    if (source.startsWith('data:image')) {
      final int commaIndex = source.indexOf(',');
      if (commaIndex > -1 && commaIndex < source.length - 1) {
        try {
          final String encoded = source.substring(commaIndex + 1);
          return Image.memory(
            base64Decode(encoded),
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) => _academyImageFallback(),
          );
        } catch (_) {
          return _academyImageFallback();
        }
      }
      return _academyImageFallback();
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) => _academyImageFallback(),
      );
    }

    // Also support plain base64 payloads.
    try {
      return Image.memory(
        base64Decode(source),
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) => _academyImageFallback(),
      );
    } catch (_) {
      return _academyImageFallback();
    }
  }

  Widget _academyImageFallback() {
    return Container(
      color: const Color(0xFF1B2F38),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: Color(0xFF9FB9B3),
        size: 28,
      ),
    );
  }

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
      final List<Map<String, dynamic>> academies = await GroundWaleApi.instance
          .listAcademies(ownerId);
      final String? preferredAcademyId =
          ApiSession.instance.selectedAcademyId?.trim().isNotEmpty == true
          ? ApiSession.instance.selectedAcademyId
          : null;
      String? selectedAcademyId;
      if (preferredAcademyId != null &&
          academies.any((Map<String, dynamic> item) =>
              _academyId(item) == preferredAcademyId)) {
        selectedAcademyId = preferredAcademyId;
      } else if (academies.isNotEmpty) {
        selectedAcademyId = _academyId(academies.first);
      }

      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId, academyId: selectedAcademyId);
      final String selectedFilter = _normalizeSelectedFilter(batches);
      final String? selectedBatchId = _batchIdByFilterLabel(
        selectedFilter,
        batches,
      );
      final Map<String, dynamic> dashboard = await GroundWaleApi.instance
          .getAcademyDashboard(
            ownerId,
            batchId: selectedBatchId,
            academyId: selectedAcademyId,
            monthKey: _monthKey(_selectedMonth),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _academies = academies;
        _selectedAcademyId = selectedAcademyId;
        _dashboard = dashboard;
        _batches = batches;
        _selectedBatchFilter = selectedFilter;
        _isLoading = false;
      });
      final Map<String, dynamic>? selectedAcademy = academies
          .where((Map<String, dynamic> item) =>
              _academyId(item) == _selectedAcademyId)
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (Map<String, dynamic>? _) => true,
            orElse: () => academies.isEmpty ? null : academies.first,
          );
      ApiSession.instance.setSelectedAcademy(
        academyId: _selectedAcademyId,
        academyName: selectedAcademy == null ? null : _academyName(selectedAcademy),
      );
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

  Future<void> _createAcademy() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    final TextEditingController nameController = TextEditingController();
    final TextEditingController cityController = TextEditingController();
    final bool? shouldCreate = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF203A43),
          title: const Text('Add Academy', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Academy Name',
                  hintStyle: TextStyle(color: Color(0x99FFFFFF)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cityController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'City (optional)',
                  hintStyle: TextStyle(color: Color(0x99FFFFFF)),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (shouldCreate != true || !mounted) {
      return;
    }

    final String name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Academy name is required')),
      );
      return;
    }

    try {
      await GroundWaleApi.instance.createAcademy(ownerId, <String, dynamic>{
        'name': name,
        'city': cityController.text.trim(),
      });
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
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
          .getAcademyDashboard(
            ownerId,
            batchId: batchId,
            academyId: _selectedAcademyId,
            monthKey: _monthKey(_selectedMonth),
          );
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

  Future<void> _onAcademyFilterTap(String academyId) async {
    if (_selectedAcademyId == academyId) {
      return;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    setState(() {
      _selectedAcademyId = academyId;
      _selectedBatchFilter = 'All';
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId, academyId: academyId);
      final String selectedFilter = _normalizeSelectedFilter(batches);
      final String? selectedBatchId = _batchIdByFilterLabel(
        selectedFilter,
        batches,
      );
      final Map<String, dynamic> dashboard = await GroundWaleApi.instance
          .getAcademyDashboard(
            ownerId,
            batchId: selectedBatchId,
            academyId: academyId,
            monthKey: _monthKey(_selectedMonth),
          );

      if (!mounted) {
        return;
      }
      final Map<String, dynamic> selectedAcademy = _academies.firstWhere(
        (Map<String, dynamic> item) => _academyId(item) == academyId,
        orElse: () => <String, dynamic>{},
      );
      ApiSession.instance.setSelectedAcademy(
        academyId: academyId,
        academyName: _academyName(selectedAcademy),
      );
      setState(() {
        _dashboard = dashboard;
        _batches = batches;
        _selectedBatchFilter = selectedFilter;
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

  Future<void> _changeMonth(int delta) async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty || _isLoading) {
      return;
    }

    final DateTime next = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final String? selectedBatchId = _batchIdByFilterLabel(
      _selectedBatchFilter,
      _batches,
    );

    setState(() {
      _selectedMonth = next;
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> dashboard = await GroundWaleApi.instance
          .getAcademyDashboard(
            ownerId,
            batchId: selectedBatchId,
            academyId: _selectedAcademyId,
            monthKey: _monthKey(next),
          );
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
    final String ownerName =
        ApiSession.instance.ownerName?.trim().isNotEmpty == true
            ? ApiSession.instance.ownerName!.trim()
            : 'Owner';
    final String greetingMessage = istGreetingMessage(ownerName);

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
      (fees['collectedAmount'] ?? 0) + (fees['pendingAmount'] ?? 0) ?? _dashboard['thisMonthEarnings'] ?? 0,
    );
    final List<int> weeklySeries = _buildWeeklySeries(
      monthEarnings,
      paidStudents,
      pendingStudents,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                greetingMessage,
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
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _academies.length + 1,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == _academies.length) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: _createAcademy,
                                child: Container(
                                  width: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0x1FFFFFFF)),
                                    color: const Color(0x0FFFFFFF),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Color(0xFFE6F7F4),
                                  ),
                                ),
                              ),
                            );
                          }
                          final Map<String, dynamic> academy = _academies[index];
                          final String academyId = _academyId(academy);
                          final bool selected = academyId == _selectedAcademyId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: academyId.isEmpty
                                  ? null
                                  : () => _onAcademyFilterTap(academyId),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF00C9A7)
                                        : const Color(0x1FFFFFFF),
                                  ),
                                  color: selected
                                      ? const Color(0x2200C9A7)
                                      : const Color(0x0FFFFFFF),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.school_outlined,
                                      size: 16,
                                      color: Color(0xFFE6F7F4),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _academyName(academy),
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF00C9A7)
                                            : const Color(0xFFE6F7F4),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_academies.isNotEmpty)
                      SizedBox(
                        height: 460,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _academies.length,
                          separatorBuilder: (_, int index) => const SizedBox(width: 12),
                          itemBuilder: (BuildContext context, int index) {
                            final Map<String, dynamic> academy = _academies[index];
                            final String academyId = _academyId(academy);
                            final bool selected = academyId == _selectedAcademyId;
                            final String? imageUrl = _academyImageUrl(academy);
                            final List<String> facilities = _academyFacilities(academy);
                            final int monthlyFee = _academyMonthlyFee(academy);
                            return GestureDetector(
                              onTap: academyId.isEmpty
                                  ? null
                                  : () => _onAcademyFilterTap(academyId),
                              child: Container(
                                width: 300,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF00C9A7)
                                        : const Color(0x1FFFFFFF),
                                  ),
                                  color: const Color(0x0FFFFFFF),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10),
                                      ),
                                      child: SizedBox(
                                        height: 176,
                                        width: double.infinity,
                                        child: imageUrl == null
                                            ? Container(
                                                color: const Color(0xFF1B2F38),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.school_outlined,
                                                  color: Color(0xFF9FB9B3),
                                                  size: 30,
                                                ),
                                              )
                                            : _academyImageWidget(imageUrl),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            _academyName(academy),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            academy['city']?.toString().trim().isNotEmpty == true
                                                ? academy['city'].toString().trim()
                                                : 'Location not set',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF9FB9B3),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: facilities.map((String facility) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  color: const Color(0x0AFFFFFF),
                                                ),
                                                child: Text(
                                                  _facilityLabel(facility),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.only(top: 10),
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                top: BorderSide(color: Color(0x14000000)),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: <Widget>[
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    const Text(
                                                      'Monthly Fees',
                                                      style: TextStyle(
                                                        color: Color(0xFF667084),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Rs $monthlyFee',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 38,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .push(
                                                            MaterialPageRoute<void>(
                                                              builder: (_) => const AcademyBatchTimingsScreen(),
                                                            ),
                                                          )
                                                          .then((_) => _load());
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF2563EB),
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                    ),
                                                    child: const Text(
                                                      'View Batches',
                                                      style: TextStyle(
                                                        fontSize: 13,
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
                          },
                        ),
                      ),
                    if (_academies.isNotEmpty) const SizedBox(height: 12),
                    if (_academies.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                          color: const Color(0x0FFFFFFF),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'No Academy Found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create an academy to see dashboard data for this tab.',
                              style: TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _createAcademy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9A7),
                                foregroundColor: const Color(0xFF06271F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Add Academy'),
                            ),
                          ],
                        ),
                      )
                    else
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _changeMonth(-1),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0x0DFFFFFF),
                                ),
                                child: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _monthLabel(_selectedMonth),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _changeMonth(1),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0x0DFFFFFF),
                                ),
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x333B82F6)),
                        color: const Color(0x143B82F6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Rs $monthEarnings',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_monthLabel(_selectedMonth)} Earning',
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Weekly Graph',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 94,
                            child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                final List<Color> barColors = <Color>[
                                  const Color(0xFFFBB831),
                                  const Color(0xFFFB569C),
                                  const Color(0xFFE850E0),
                                  const Color(0xFF8225E2),
                                  const Color(0xFF9C27B0),
                                ];
                                final int maxValue = weeklySeries.reduce(math.max);
                                return Stack(
                                  children: <Widget>[
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top: 2,
                                      bottom: 22,
                                      child: CustomPaint(
                                        painter: _WeeklyTrendPainter(
                                          values: weeklySeries,
                                          maxValue: maxValue,
                                          lineColor: const Color(0xFFBDBDBD),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 22,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: List<Widget>.generate(weeklySeries.length, (
                                          int index,
                                        ) {
                                          final double ratio = weeklySeries[index] / maxValue;
                                          final double height = 14 + (ratio * 44);
                                          return Container(
                                            width: 28,
                                            height: height,
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(6),
                                              ),
                                              color: barColors[index % barColors.length],
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: List<Widget>.generate(weeklySeries.length, (
                                          int index,
                                        ) {
                                          return SizedBox(
                                            width: 28,
                                            child: Text(
                                              _ordinalLabel(index),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
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
                                    builder: (_) => const AcademyBatchTimingsScreen(),
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
                                builder: (_) => const AcademyManageStudentsScreen(),
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
                                    builder: (_) => const AcademyMarkAttendanceScreen(),
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
                            'Fees Overview',
                            style: TextStyle(
                              color: Color(0xFFE6F7F4),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                    builder: (_) => const AcademyFeeDetailsScreen(),
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
                                    builder: (_) => const AcademyBatchTimingsScreen(),
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
                          final Map<String, dynamic> batch = filteredBatches[index];
                          final String name = batch['name']?.toString() ?? 'Batch';
                          final String start = batch['startTime']?.toString() ?? '09:00';
                          final String end = batch['endTime']?.toString() ?? '10:00';
                          final String coach = batch['coachName']?.toString() ?? 'Coach';
                          final int studentsCount = _toInt(
                            batch['capacity'] ?? batch['studentsCount'],
                          );
                          final String status =
                              (batch['status']?.toString() ?? 'active').toLowerCase();

                          return Container(
                            width: 286,
                            padding: const EdgeInsets.all(16),
                            decoration: _overlayCardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFE6F7F4),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
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
                                _batchMeta(Icons.schedule_rounded, '$start - $end'),
                                const SizedBox(height: 10),
                                _batchMeta(Icons.calendar_month_outlined, _batchDays(batch)),
                                const SizedBox(height: 10),
                                _batchMeta(Icons.person_outline_rounded, 'Coach: $coach'),
                                const SizedBox(height: 10),
                                _batchMeta(Icons.groups_outlined, 'Students: $studentsCount'),
                                const Spacer(),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _darkActionButton('View Batch', () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => AcademyViewBatchScreen(
                                              batchId: batch['_id']?.toString() ??
                                                  batch['id']?.toString(),
                                              batchName: name,
                                              coachName: coach,
                                              time: '$start - $end',
                                              days: _batchDays(batch),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _darkActionButton('Edit', () {
                                        Navigator.of(context)
                                            .push(
                                              MaterialPageRoute<void>(
                                                builder: (_) => AcademyEditBatchScreen(
                                                  batchId: batch['_id']?.toString() ??
                                                      batch['id']?.toString(),
                                                  batchName: name,
                                                  coachName: coach,
                                                  startTime: start,
                                                  endTime: end,
                                                  days: (batch['days'] as List<dynamic>? ??
                                                          <dynamic>[])
                                                      .map((dynamic value) =>
                                                          value.toString())
                                                      .toList(),
                                                  capacity: _toInt(batch['capacity']),
                                                  status: batch['status']?.toString() ??
                                                      'active',
                                                  monthlyFee:
                                                      (batch['monthlyFee'] as num?)
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
      bottomNavigationBar: widget.showBottomNav
          ? ModuleBottomNav(
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
      )
          : null,
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

class _WeeklyTrendPainter extends CustomPainter {
  _WeeklyTrendPainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
  });

  final List<int> values;
  final int maxValue;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || maxValue <= 0) {
      return;
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Paint pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final double stepX = values.length == 1 ? 0 : size.width / (values.length - 1);
    for (int index = 0; index < values.length; index++) {
      final double x = stepX * index;
      final double ratio = values[index] / maxValue;
      final double y = size.height - (ratio * (size.height - 6)) - 3;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int index = 0; index < values.length; index++) {
      final double x = stepX * index;
      final double ratio = values[index] / maxValue;
      final double y = size.height - (ratio * (size.height - 6)) - 3;
      canvas.drawCircle(Offset(x, y), 2.2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor;
  }
}
