import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../ground/flow/controllers/ground_flow_controller.dart';
import '../../ground/flow/models/ground_registration_data.dart';
import '../../ground/flow/screens/register_ground_flow_screen.dart';
import 'academy_add_student_screen.dart';
import 'academy_batch_timings_screen.dart';
import 'academy_edit_batch_screen.dart';
import 'academy_fee_details_screen.dart';
import 'academy_manage_students_screen.dart';
import 'academy_mark_attendance_screen.dart';
import 'academy_view_batch_screen.dart';

class AcademyDashboardScreen extends StatefulWidget {
  const AcademyDashboardScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen> {
  bool _isLoading = true;
  final Map<String, Uint8List> _imageCache = {};

  Uint8List _decodedImage(String source) {
    return _imageCache.putIfAbsent(source, () {
      return base64Decode(_normalizeBase64(source));
    });
  }

  Map<String, dynamic> _dashboard = <String, dynamic>{};
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  String? _selectedAcademyId;
  List<Map<String, dynamic>> _batches = <Map<String, dynamic>>[];
  String _selectedBatchFilter = 'All';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // ─────────────────────────────────────────────────────────────
  //  QUARTERLY GRAPH HELPERS
  // ─────────────────────────────────────────────────────────────

  /// Builds 4-month data ending at [_selectedMonth].
  /// Only the current month carries real API values; the others show 0
  /// until a quarterly endpoint is available.
  List<Map<String, dynamic>> _buildQuarterlyData(
    int collectedAmount,
    int pendingAmount,
    int paidStudents,
    int pendingStudents,
  ) {
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];

    for (int i = 3; i >= 0; i--) {
      final DateTime month = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - i,
      );
      final bool isCurrent = i == 0;

      result.add(<String, dynamic>{
        'month': month,
        'label': _shortMonthLabel(month),
        'paid': isCurrent ? collectedAmount : 0,
        'pending': isCurrent ? pendingAmount : 0,
        'total': isCurrent ? (collectedAmount + pendingAmount) : 0,
      });
    }

    return result;
  }

  String _shortMonthLabel(DateTime date) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[date.month - 1];
  }

  // ─────────────────────────────────────────────────────────────
  //  ACADEMY HELPERS
  // ─────────────────────────────────────────────────────────────

  String _academyId(Map<String, dynamic> academy) =>
      academy['_id']?.toString() ?? academy['id']?.toString() ?? '';

  String _academyName(Map<String, dynamic> academy) {
    final String name = academy['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'Academy' : name;
  }

  String? _academyImageUrl(Map<String, dynamic> academy) {
    for (final String key in <String>[
      'imageUrl', 'coverImage', 'bannerImage', 'photoUrl', 'image',
    ]) {
      final String value = academy[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  List<String> _academyImageValues(Map<String, dynamic> academy) {
    final List<String> values = <String>[];

    void addIfValid(dynamic raw) {
      final String value = raw?.toString().trim() ?? '';
      if (value.isNotEmpty && !values.contains(value)) values.add(value);
    }

    addIfValid(academy['image']);
    addIfValid(academy['imageUrl']);
    addIfValid(academy['coverImage']);
    addIfValid(academy['bannerImage']);
    addIfValid(academy['photoUrl']);

    for (final String key in <String>['imageUrls', 'academyImages', 'images']) {
      final dynamic list = academy[key];
      if (list is List) {
        for (final dynamic item in list) addIfValid(item);
      }
    }

    return values;
  }

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime date) {
    const List<String> months = <String>[
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<String> _academyFacilities(Map<String, dynamic> academy) {
    final List<dynamic> raw =
        (academy['facilities'] as List<dynamic>?) ??
        (academy['amenities']  as List<dynamic>?) ??
        (academy['features']   as List<dynamic>?) ??
        <dynamic>[];

    final List<String> values = raw
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    return values.isNotEmpty
        ? values
        : <String>['Parking', 'Washroom', 'Water', 'Lighting', 'Ball Machine', 'Hard Court'];
  }

  String _facilityLabel(String value) {
    final String key = value.trim().toLowerCase();
    if (key.contains('park'))  return '🅿️ Parking';
    if (key.contains('wash'))  return '🚻 Washroom';
    if (key.contains('water')) return '💧 Water';
    if (key.contains('light')) return '💡 Lighting';
    if (key.contains('ball'))  return '🎾 Ball Machine';
    if (key.contains('court')) return '🎾 Hard Court';
    return value;
  }

  int _academyMonthlyFee(Map<String, dynamic> academy) {
    final dynamic batchRaw = academy['batch'];
    if (batchRaw is Map) {
      final List<dynamic> plans =
          batchRaw['feePlans'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic plan in plans) {
        if (plan is Map) {
          final String dur =
              plan['duration']?.toString().trim().toLowerCase() ?? '';
          if (dur == 'monthly') {
            return int.tryParse(
                  plan['price']?.toString().replaceAll(',', '') ?? '',
                ) ?? 0;
          }
        }
      }
    }
    final dynamic direct = academy['monthlyFee'] ?? academy['monthlyFees'];
    if (direct is int)    return direct;
    if (direct is double) return direct.round();
    if (direct is String) return int.tryParse(direct) ?? 0;
    return 0;
  }

  // ignore: unused_element
  List<Map<String, String>> _academyFeePlans(Map<String, dynamic> academy) {
    final dynamic batchRaw = academy['batch'];
    if (batchRaw is Map) {
      final List<dynamic> plans =
          batchRaw['feePlans'] as List<dynamic>? ?? <dynamic>[];
      return plans.whereType<Map>().map((Map p) => <String, String>{
        'duration': p['duration']?.toString() ?? 'Monthly',
        'price': p['price']?.toString() ?? '0',
      }).toList();
    }
    return <Map<String, String>>[];
  }

  // ─────────────────────────────────────────────────────────────
  //  IMAGE HELPERS
  // ─────────────────────────────────────────────────────────────

  Widget _academyImageWidget(String? imageValue) {
    if (imageValue == null || imageValue.trim().isEmpty) {
      return Container(
        color: const Color(0xFF1B2F38),
        alignment: Alignment.center,
        child: const Icon(Icons.school_outlined, color: Color(0xFF9FB9B3), size: 30),
      );
    }

    final String source = imageValue.trim();

    if (source.startsWith('data:image')) {
      final int commaIndex = source.indexOf(',');
      if (commaIndex > -1 && commaIndex < source.length - 1) {
        try {
          final String encoded = _normalizeBase64(source.substring(commaIndex + 1));
          return Image.memory(_decodedImage(encoded), fit: BoxFit.cover, gaplessPlayback: true);
        } catch (_) {
          return _academyImageFallback();
        }
      }
      return _academyImageFallback();
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _academyImageFallback(),
        gaplessPlayback: true,
      );
    }

    try {
      final String encoded = _normalizeBase64(source);
      return Image.memory(_decodedImage(encoded), fit: BoxFit.cover, gaplessPlayback: true);
    } catch (_) {
      return _academyImageFallback();
    }
  }

  String _normalizeBase64(String input) {
    String normalized = input.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) return '';
    normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
    final int remainder = normalized.length % 4;
    if (remainder != 0) {
      normalized = normalized.padRight(normalized.length + (4 - remainder), '=');
    }
    return normalized;
  }

  Widget _academyImageFallback() {
    return Container(
      color: const Color(0xFF1B2F38),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9FB9B3), size: 28),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ─────────────────────────────────────────────────────────────
  //  DATA LOADING
  // ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final List<Map<String, dynamic>> academies =
          await GroundWaleApi.instance.listAcademies(ownerId);

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

      final List<Map<String, dynamic>> batches =
          await GroundWaleApi.instance
              .listAcademyBatches(ownerId, academyId: selectedAcademyId);

      final String selectedFilter = _normalizeSelectedFilter(batches);
      final String? selectedBatchId =
          _batchIdByFilterLabel(selectedFilter, batches);

      final Map<String, dynamic> dashboard =
          await GroundWaleApi.instance.getAcademyDashboard(
        ownerId,
        batchId: selectedBatchId,
        academyId: selectedAcademyId,
        monthKey: _monthKey(_selectedMonth),
      );

      if (!mounted) return;

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
          .firstWhere((_) => true,
              orElse: () => academies.isEmpty ? null : academies.first);

      ApiSession.instance.setSelectedAcademy(
        academyId: _selectedAcademyId,
        academyName:
            selectedAcademy == null ? null : _academyName(selectedAcademy),
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
    if (ApiSession.instance.ownerId == null) return;

    final GroundFlowController flowController = GroundFlowController();
    flowController.data.offerType = OfferType.academyCoaching;
    flowController.data.ownerName = ApiSession.instance.ownerName ?? '';
    flowController.data.contactNumber = ApiSession.instance.contactNumber ?? '';
    flowController.data.otpVerified = true;
    flowController.skipOwnershipVerification = true;

    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterGroundFlowScreen(
          initialController: flowController,
          initialStep: 13,
          onFinish: () {
            Navigator.of(context, rootNavigator: true).pop();
            _load();
          },
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _addFacilityToAcademy(
    String academyId,
    List<String> existingFacilities,
  ) async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) return;

    const List<String> suggestions = <String>[
      'Parking', 'Cafeteria / Food', 'First Aid', 'Rest Room',
      'Changing Room', 'Dugout', 'Lighting', 'Wi-Fi',
      'Locker Room', 'CCTV', 'Water', 'Shower', 'Washroom',
      'Seating Area', 'AC Hall', 'Equipment Room',
    ];

    final Set<String> selected = Set<String>.from(existingFacilities);

    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              builder: (BuildContext _, ScrollController sc) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F2027),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Manage Facilities',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text(
                              'Done',
                              style: TextStyle(color: Color(0xFF00C9A7)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          controller: sc,
                          children: <Widget>[
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: suggestions.map((String f) {
                                final bool isSel = selected.contains(f);
                                return GestureDetector(
                                  onTap: () => setSheetState(() {
                                    isSel
                                        ? selected.remove(f)
                                        : selected.add(f);
                                  }),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel
                                            ? const Color(0xFF00C9A7)
                                            : const Color(0x1FFFFFFF),
                                      ),
                                      color: isSel
                                          ? const Color(0x1400C9A7)
                                          : const Color(0x0FFFFFFF),
                                    ),
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                        color: isSel
                                            ? const Color(0xFF00C9A7)
                                            : Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await GroundWaleApi.instance.updateAcademy(
        ownerId,
        academyId,
        <String, dynamic>{'facilities': selected.toList()},
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  FILTER / BATCH HELPERS
  // ─────────────────────────────────────────────────────────────

  String _normalizeSelectedFilter(List<Map<String, dynamic>> batches) {
    if (_selectedBatchFilter == 'All') return 'All';
    final String selectedKey = _selectedBatchFilter.trim().toLowerCase();
    final bool exists = batches.any((Map<String, dynamic> batch) =>
        (batch['name']?.toString() ?? '').trim().toLowerCase() == selectedKey);
    return exists ? _selectedBatchFilter : 'All';
  }

  String? _batchIdByFilterLabel(
    String label,
    List<Map<String, dynamic>> batches,
  ) {
    if (label == 'All') return null;
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
    if (label == _selectedBatchFilter) return;
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) return;

    final String? batchId = _batchIdByFilterLabel(label, _batches);
    setState(() {
      _selectedBatchFilter = label;
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> dashboard =
          await GroundWaleApi.instance.getAcademyDashboard(
        ownerId,
        batchId: batchId,
        academyId: _selectedAcademyId,
        monthKey: _monthKey(_selectedMonth),
      );
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onAcademyFilterTap(String academyId) async {
    if (_selectedAcademyId == academyId) return;
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) return;

    setState(() {
      _selectedAcademyId = academyId;
      _selectedBatchFilter = 'All';
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> batches =
          await GroundWaleApi.instance
              .listAcademyBatches(ownerId, academyId: academyId);
      final String selectedFilter = _normalizeSelectedFilter(batches);
      final String? selectedBatchId =
          _batchIdByFilterLabel(selectedFilter, batches);
      final Map<String, dynamic> dashboard =
          await GroundWaleApi.instance.getAcademyDashboard(
        ownerId,
        batchId: selectedBatchId,
        academyId: academyId,
        monthKey: _monthKey(_selectedMonth),
      );

      if (!mounted) return;

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
      if (!mounted) return;
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
    if (ownerId == null || ownerId.isEmpty || _isLoading) return;

    final DateTime next =
        DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final String? selectedBatchId =
        _batchIdByFilterLabel(_selectedBatchFilter, _batches);

    setState(() {
      _selectedMonth = next;
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> dashboard =
          await GroundWaleApi.instance.getAcademyDashboard(
        ownerId,
        batchId: selectedBatchId,
        academyId: _selectedAcademyId,
        monthKey: _monthKey(next),
      );
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  MISC HELPERS
  // ─────────────────────────────────────────────────────────────

  int _toInt(dynamic value) {
    if (value is int)    return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _batchDays(Map<String, dynamic> batch) {
    final List<dynamic> daysRaw =
        batch['days'] as List<dynamic>? ?? <dynamic>[];
    if (daysRaw.isEmpty) return 'Mon - Sat';
    final List<String> days =
        daysRaw.map((dynamic d) => d.toString()).toList();
    return days.length == 1 ? days.first : '${days.first} - ${days.last}';
  }

  List<Map<String, dynamic>> _filteredBatches() {
    if (_selectedBatchFilter == 'All') return _batches;
    final String query = _selectedBatchFilter.trim().toLowerCase();
    return _batches
        .where((Map<String, dynamic> batch) =>
            (batch['name']?.toString() ?? '').trim().toLowerCase() == query)
        .toList();
  }

  List<String> _batchFilterLabels() {
    final Set<String> seen = <String>{};
    final List<String> labels = <String>['All'];
    for (final Map<String, dynamic> batch in _batches) {
      final String name = (batch['name']?.toString() ?? '').trim();
      if (name.isEmpty) continue;
      final String key = name.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      labels.add(name);
    }
    return labels;
  }

  List<Map<String, dynamic>> _orderedAcademies(
      List<Map<String, dynamic>> input) {
    if (_selectedAcademyId == null || _selectedAcademyId!.isEmpty) return input;
    final List<Map<String, dynamic>> selected = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> others  = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> academy in input) {
      if (_academyId(academy) == _selectedAcademyId) {
        selected.add(academy);
      } else {
        others.add(academy);
      }
    }
    return <Map<String, dynamic>>[...selected, ...others];
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

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

    final int totalStudents  = _toInt(students['total']);
    final int presentToday   = _toInt(attendance['present']);
    final int absentToday    = attendance.containsKey('absent')
        ? _toInt(attendance['absent'])
        : (totalStudents - presentToday).clamp(0, 1000000);

    final int collectedAmount = _toInt(fees['collectedAmount'] ?? 0);
    final int pendingAmount   = _toInt(fees['pendingAmount']);
    final int paidStudents    = _toInt(fees['paidStudents']);
    final int pendingStudents = _toInt(fees['pendingStudents']);
    final int monthEarnings   = _toInt(collectedAmount + pendingAmount);

    final List<Map<String, dynamic>> quarterlyData = _buildQuarterlyData(
      collectedAmount,
      pendingAmount,
      paidStudents,
      pendingStudents,
    );

    final List<Map<String, dynamic>> orderedAcademies =
        _orderedAcademies(_academies);
    final List<Map<String, dynamic>> filteredBatches = _filteredBatches();
    final List<String> batchFilterLabels = _batchFilterLabels();

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF00C9A7)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF00C9A7),
                backgroundColor: const Color(0xFF203A43),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  children: <Widget>[
                    // ── Loading bar ────────────────────────────────
                    if (_isLoading) ...<Widget>[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        minHeight: 2,
                        color: Color(0xFFDDF730),
                        backgroundColor: Color(0x1FFFFFFF),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // ── Slide hint ─────────────────────────────────
                    if (_academies.isNotEmpty)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            'Slide right',
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            color: Color(0x99FFFFFF),
                            size: 18,
                          ),
                        ],
                      ),
                    if (_academies.isNotEmpty) const SizedBox(height: 8),

                    // ── Academy carousel ───────────────────────────
                    if (_academies.isNotEmpty)
                      SizedBox(
                        height: 336,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: orderedAcademies.length + 1,
                          separatorBuilder: (_, int index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (BuildContext context, int index) {
                            if (index == orderedAcademies.length) {
                              return _addAcademyCard();
                            }
                            final Map<String, dynamic> academy =
                                orderedAcademies[index];
                            return _academyCard(
                              academy,
                              selected: _academyId(academy) == _selectedAcademyId,
                            );
                          },
                        ),
                      ),
                    if (_academies.isNotEmpty) const SizedBox(height: 12),

                    // ── Empty state ────────────────────────────────
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
                                  color: Color(0xCCFFFFFF), fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _createAcademy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9A7),
                                foregroundColor: const Color(0xFF06271F),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Add Academy'),
                            ),
                          ],
                        ),
                      )

                    // ── Batch filter chips ─────────────────────────
                    else
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: batchFilterLabels.map((String label) {
                            final bool selected =
                                _selectedBatchFilter == label;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => _onBatchFilterTap(label),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
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

                    // ── Month navigator ────────────────────────────
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
                                child: const Icon(Icons.chevron_left,
                                    color: Colors.white),
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
                                child: const Icon(Icons.chevron_right,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ══════════════════════════════════════════════
                    //  QUARTERLY GRAPH CARD
                    // ══════════════════════════════════════════════
                    _buildQuarterlyGraph(
                      quarterlyData: quarterlyData,
                      monthEarnings: monthEarnings,
                    ),

                    const SizedBox(height: 8),

                    // ── Paid / Pending summary row ─────────────────
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
                        const Text('•',
                            style: TextStyle(color: Color(0x66FFFFFF))),
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

                    // ── Action tiles ───────────────────────────────
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
                          highlighted: true,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyAddStudentScreen()))
                              .then((_) => _load()),
                        ),
                        _actionTile(
                          icon: Icons.group_add_rounded,
                          label: 'Add Batch',
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyBatchTimingsScreen()))
                              .then((_) => _load()),
                        ),
                        _actionTile(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Manage Student',
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyManageStudentsScreen()))
                              .then((_) => _load()),
                        ),
                        _actionTile(
                          icon: Icons.notifications_active_outlined,
                          label: 'Fees Reminder',
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyFeeDetailsScreen()))
                              .then((_) => _load()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Total Students card ────────────────────────
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
                                    color: Color(0xFF9FB9B3), fontSize: 14),
                              ),
                              Text(
                                'Absent Today: $absentToday',
                                style: const TextStyle(
                                    color: Color(0xFF9FB9B3), fontSize: 14),
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
                                      color: const Color(0xFF22C55E)),
                                ),
                                Expanded(
                                  flex: absentToday == 0 ? 1 : absentToday,
                                  child: Container(
                                      height: 8,
                                      color: const Color(0xFFEF4444)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Attendance card ────────────────────────────
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
                                  Color(0xFF22C55E)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const AcademyMarkAttendanceScreen()))
                                  .then((_) => _load()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9A7),
                                foregroundColor: const Color(0xFF052017),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Mark Attendance',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Fees Overview card ─────────────────────────
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
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0x33F97316)),
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
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const AcademyFeeDetailsScreen()))
                                  .then((_) => _load()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF203A43),
                                foregroundColor: const Color(0xFFDFF7F0),
                                elevation: 0,
                              ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Manage Batches header ──────────────────────
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
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AcademyBatchTimingsScreen()))
                              .then((_) => _load()),
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

                    // ── Batch cards carousel ───────────────────────
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
                              batch['coachName']?.toString() ?? 'Coach';
                          final int studentsCount = _toInt(
                              batch['capacity'] ?? batch['studentsCount']);
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
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(4),
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
                                _batchMeta(Icons.schedule_rounded,
                                    '$start - $end'),
                                const SizedBox(height: 10),
                                _batchMeta(Icons.calendar_month_outlined,
                                    _batchDays(batch)),
                                const SizedBox(height: 10),
                                _batchMeta(Icons.person_outline_rounded,
                                    'Coach: $coach'),
                                const SizedBox(height: 10),
                                _batchMeta(Icons.groups_outlined,
                                    'Students: $studentsCount'),
                                const Spacer(),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _darkActionButton('View Batch',
                                          () {
                                        Navigator.of(context)
                                            .push(MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    AcademyViewBatchScreen(
                                                      batchId: batch['_id']
                                                              ?.toString() ??
                                                          batch['id']
                                                              ?.toString(),
                                                      batchName: name,
                                                      coachName: coach,
                                                      time: '$start - $end',
                                                      days: _batchDays(batch),
                                                    )))
                                            .then((_) => _load());
                                      }),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _darkActionButton('Edit', () {
                                        Navigator.of(context)
                                            .push(MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    AcademyEditBatchScreen(
                                                      batchId: batch['_id']
                                                              ?.toString() ??
                                                          batch['id']
                                                              ?.toString(),
                                                      batchName: name,
                                                      coachName: coach,
                                                      startTime: start,
                                                      endTime: end,
                                                      days: (batch['days']
                                                                      as List<
                                                                          dynamic>? ??
                                                                  <dynamic>[])
                                                              .map((dynamic v) =>
                                                                  v.toString())
                                                              .toList(),
                                                      capacity: _toInt(
                                                          batch['capacity']),
                                                      status: batch['status']
                                                              ?.toString() ??
                                                          'active',
                                                      monthlyFee: (batch[
                                                                      'monthlyFee']
                                                                  as num?)
                                                              ?.toDouble() ??
                                                          0,
                                                      feePlans: (batch['feePlans']
                                                                      as List<
                                                                          dynamic>? ??
                                                                  <dynamic>[])
                                                          .whereType<Map>()
                                                          .map((Map p) =>
                                                              <String, String>{
                                                                'duration': p[
                                                                            'duration']
                                                                        ?.toString() ??
                                                                    'Monthly',
                                                                'price': p[
                                                                            'price']
                                                                        ?.toString() ??
                                                                    '0',
                                                              })
                                                          .toList(),
                                                      coachExperience: _toInt(
                                                          batch[
                                                              'coachExperience']),
                                                      enrolledStudents: _toInt(
                                                          batch['studentsCount'] ??
                                                              batch['capacity']),
                                                    )))
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
      bottomNavigationBar: null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  QUARTERLY GRAPH WIDGET
  // ─────────────────────────────────────────────────────────────

  Widget _buildQuarterlyGraph({
    required List<Map<String, dynamic>> quarterlyData,
    required int monthEarnings,
  }) {
    // Max total across all 4 months (at least 1 to avoid ÷ 0)
    final int maxTotal = quarterlyData
        .map((Map<String, dynamic> m) => m['total'] as int)
        .fold(1, (int a, int b) => a > b ? a : b);

    const double maxBarHeight  = 80.0;
    const double amountHeight  = 20.0;
    const double labelHeight   = 18.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x333B82F6)),
        color: const Color(0x143B82F6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Header ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Quarterly Graph',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Legend ──────────────────────────────────────────
          Row(
            children: <Widget>[
              _legendDot(const Color(0xFF22C55E)),
              const SizedBox(width: 4),
              const Text('Paid',
                  style: TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 11)),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFFF97316)),
              const SizedBox(width: 4),
              const Text('Pending',
                  style: TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),

          // ── Bars ────────────────────────────────────────────
          SizedBox(
            height: amountHeight + maxBarHeight + 8 + labelHeight,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double barWidth =
                    (constraints.maxWidth - 48) / 4;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: quarterlyData
                      .map((Map<String, dynamic> data) {
                    final int paid    = data['paid']    as int;
                    final int pending = data['pending'] as int;
                    final int total   = data['total']   as int;
                    final String label = data['label']  as String;

                    final bool isCurrent =
                        (data['month'] as DateTime).month ==
                            _selectedMonth.month &&
                        (data['month'] as DateTime).year ==
                            _selectedMonth.year;

                    // Bar heights
                    final double totalRatio =
                        total <= 0 ? 0 : total / maxTotal;
                    final double barHeight = math.max(
                        totalRatio * maxBarHeight,
                        total > 0 ? 6.0 : 2.0);

                    final double paidHeight = total == 0
                        ? 0
                        : (paid / total) * barHeight;
                    final double pendingHeight =
                        barHeight - paidHeight;

                    // Amount label text
                    final String amountText = total <= 0
                        ? '-'
                        : (total >= 1000
                            ? '${(total / 1000).toStringAsFixed(1)}k'
                            : '$total');

                    return SizedBox(
                      width: barWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          // ── Amount on top ──────────────
                          SizedBox(
                            height: amountHeight,
                            child: Text(
                              amountText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: total > 0
                                    ? (isCurrent
                                        ? Colors.white
                                        : const Color(0xFF9CA3AF))
                                    : const Color(0x44FFFFFF),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // ── Stacked bar ────────────────
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  // Pending = orange (top)
                                  if (pendingHeight > 0)
                                    Container(
                                      height: pendingHeight,
                                      width: double.infinity,
                                      color: isCurrent
                                          ? const Color(0xFFF97316)
                                          : const Color(0x55F97316),
                                    ),
                                  // Paid = green (bottom)
                                  Container(
                                    height: math.max(paidHeight, 2.0),
                                    width: double.infinity,
                                    color: isCurrent
                                        ? const Color(0xFF22C55E)
                                        : const Color(0x4422C55E),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // ── Month label ────────────────
                          SizedBox(
                            height: labelHeight,
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isCurrent
                                    ? const Color(0xFF00C9A7)
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BOTTOM SHEET — ALL FACILITIES
  // ─────────────────────────────────────────────────────────────

  void _showAllFacilities(BuildContext context, List<String> facilities) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'All Facilities',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: facilities
                  .map(
                    (String facility) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0x0AFFFFFF),
                      ),
                      child: Text(
                        _facilityLabel(facility),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  CARD / TILE WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _addAcademyCard() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF00C9A7),
            ),
            child: const Icon(Icons.add, size: 54, color: Colors.white),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: _createAcademy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                foregroundColor: const Color(0xFF06271F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Academy',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _academyCard(Map<String, dynamic> academy,
      {bool selected = false}) {
    final String academyId   = _academyId(academy);
    final String name        = _academyName(academy);
    final String location    =
        academy['city']?.toString().trim().isNotEmpty == true
            ? academy['city'].toString().trim()
            : 'Location not set';
    final String rating      = academy['rating']?.toString() ?? '4.6';
    final List<String> imageValues = _academyImageValues(academy);
    final String? imageUrl   = _academyImageUrl(academy);
    final List<String> facilities = _academyFacilities(academy);
    final int monthlyFee     = _academyMonthlyFee(academy);

    return GestureDetector(
      onTap:
          academyId.isEmpty ? null : () => _onAcademyFilterTap(academyId),
      child: Container(
        width: 263,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF00C9A7)
                : const Color(0x1FFFFFFF),
            width: selected ? 1.5 : 1,
          ),
          color: const Color(0x0AFFFFFF),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 140,
                width: double.infinity,
                color: const Color(0x29242424),
                child: Stack(
                  children: <Widget>[
                    if (imageValues.isNotEmpty)
                      Positioned.fill(
                        child: _AcademyImageCarousel(
                          imageValues: imageValues,
                          imageBuilder: _academyImageWidget,
                        ),
                      )
                    else
                      Positioned.fill(
                        child: imageUrl == null
                            ? Container(
                                color: const Color(0xFF1B2F38),
                                alignment: Alignment.center,
                                child: const Icon(Icons.school_outlined,
                                    color: Color(0xFF9FB9B3), size: 30),
                              )
                            : _academyImageWidget(imageUrl),
                      ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xCC0B0E0C),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.star_border,
                                color: Color(0xFFEAB308), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Color(0x99FFFFFF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: <Widget>[
                      ...facilities.take(3).map(
                            (String facility) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
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
                            ),
                          ),
                      if (facilities.length > 3)
                        GestureDetector(
                          onTap: () =>
                              _showAllFacilities(context, facilities),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color(0x0AFFFFFF),
                            ),
                            child: const Text(
                              '...',
                              style: TextStyle(
                                color: Color(0xFF00C9A7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () =>
                            _addFacilityToAcademy(academyId, facilities),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0x3300C9A7)),
                            color: const Color(0x0A00C9A7),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.add,
                                  size: 12, color: Color(0xFF00C9A7)),
                              SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Color(0xFF00C9A7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Color(0x14000000))),
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
                            const SizedBox(height: 4),
                            Text(
                              'Rs $monthlyFee',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .push(MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const AcademyBatchTimingsScreen()))
                                .then((_) => _load()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'View Batches',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
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

  BoxDecoration _overlayCardDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0AFFFFFF),
      );

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
              fontWeight: FontWeight.w500),
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
        child: Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ACADEMY IMAGE CAROUSEL
// ═══════════════════════════════════════════════════════════════

class _AcademyImageCarousel extends StatefulWidget {
  const _AcademyImageCarousel({
    required this.imageValues,
    required this.imageBuilder,
  });

  final List<String> imageValues;
  final Widget Function(String imageValue) imageBuilder;

  @override
  State<_AcademyImageCarousel> createState() =>
      _AcademyImageCarouselState();
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
    for (final String image in widget.imageValues) {
      precacheImage(NetworkImage(image), context);
    }
  }

  @override
  void didUpdateWidget(covariant _AcademyImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageValues != widget.imageValues) {
      for (final String image in widget.imageValues) {
        precacheImage(NetworkImage(image), context);
      }
    }
    if (oldWidget.imageValues.length != widget.imageValues.length) {
      _currentIndex = 0;
      _pageController.jumpToPage(0);
      _restartAutoSlide();
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
    if (widget.imageValues.length <= 1) return;
    _autoSlideTimer =
        Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final int nextIndex =
          (_currentIndex + 1) % widget.imageValues.length;
      _pageController.animateToPage(
        nextIndex,
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
    final List<String> images = widget.imageValues;
    if (images.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: <Widget>[
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (int index) {
            setState(() => _currentIndex = index);
            _restartAutoSlide();
          },
          itemBuilder: (_, int index) =>
              widget.imageBuilder(images[index]),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(images.length, (int index) {
                final bool isActive = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF00C9A7)
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