import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'academy_edit_batch_screen.dart';

class AcademyBatchTimingsScreen extends StatefulWidget {
  const AcademyBatchTimingsScreen({super.key});

  @override
  State<AcademyBatchTimingsScreen> createState() =>
      _AcademyBatchTimingsScreenState();
}

class _AcademyBatchTimingsScreenState extends State<AcademyBatchTimingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  String? _selectedAcademyId;
  List<Map<String, dynamic>> _batches = <Map<String, dynamic>>[];

  String _academyId(Map<String, dynamic> academy) {
    return academy['_id']?.toString() ?? academy['id']?.toString() ?? '';
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
        setState(() {
          _isLoading = false;
          _batches = <Map<String, dynamic>>[];
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final List<Map<String, dynamic>> academies = await GroundWaleApi.instance
          .listAcademies(ownerId);
      String? academyId = _selectedAcademyId;
      if (academyId == null ||
          !academies.any((Map<String, dynamic> item) => _academyId(item) == academyId)) {
        academyId = ApiSession.instance.selectedAcademyId;
      }
      if (academyId == null ||
          !academies.any((Map<String, dynamic> item) => _academyId(item) == academyId)) {
        academyId = academies.isEmpty ? null : _academyId(academies.first);
      }
      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId, academyId: academyId);
      if (!mounted) {
        return;
      }
      setState(() {
        _academies = academies;
        _selectedAcademyId = academyId;
        _batches = batches;
        _isLoading = false;
      });
      ApiSession.instance.setSelectedAcademy(academyId: academyId);
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

  String _batchId(Map<String, dynamic> batch) {
    return batch['_id']?.toString() ?? batch['id']?.toString() ?? '';
  }

  List<String> _batchDays(Map<String, dynamic> batch) {
    final List<dynamic> rawDays =
        batch['days'] as List<dynamic>? ?? <dynamic>[];
    if (rawDays.isEmpty) {
      return const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    }
    return rawDays.map((dynamic value) => value.toString()).toList();
  }

  Future<void> _openEditor({Map<String, dynamic>? batch}) async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AcademyEditBatchScreen(
          batchId: batch == null ? null : _batchId(batch),
          batchName: batch?['name']?.toString() ?? '',
          coachName: batch?['coachName']?.toString() ?? '',
          coachExperience: (batch?['coachExperience'] as num?)?.toInt() ?? 0,
          startTime: batch?['startTime']?.toString() ?? '09:00',
          endTime: batch?['endTime']?.toString() ?? '10:00',
          days: _batchDays(batch ?? <String, dynamic>{}),
          capacity: (batch?['capacity'] as num?)?.toInt() ?? 30,
          status: batch?['status']?.toString() ?? 'active',
          monthlyFee: (batch?['monthlyFee'] as num?)?.toDouble() ?? 0,
          enrolledStudents: (batch?['studentsCount'] as num?)?.toInt() ?? 0,
          isCreate: batch == null,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _load();
    }
  }

  Future<void> _deleteBatch(Map<String, dynamic> batch) async {
    final String? ownerId = ApiSession.instance.ownerId;
    final String batchId = _batchId(batch);
    if (ownerId == null || ownerId.isEmpty || batchId.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF203A43),
          title: const Text(
            'Delete batch?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will remove ${batch['name'] ?? 'this batch'} and unassign students from it.',
            style: const TextStyle(color: Color(0xFFCEE9E2)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFE3220D)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await GroundWaleApi.instance.deleteAcademyBatch(ownerId, batchId);
      if (!mounted) {
        return;
      }
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Batch deleted')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF00C9A7),
                backgroundColor: const Color(0xFF203A43),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Batch Timings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAcademyId,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0x99FFFFFF),
                      ),
                      dropdownColor: const Color(0xFF203A43),
                      decoration: InputDecoration(
                        labelText: 'Select Academy',
                        labelStyle: const TextStyle(
                          color: Color(0xB3E6F7F4),
                          fontSize: 13,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0x0FFFFFFF),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                        ),
                      ),
                      items: _academies.map((Map<String, dynamic> academy) {
                        final String id = _academyId(academy);
                        final String name = academy['name']?.toString() ?? 'Academy';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) async {
                        if (value == null || value == _selectedAcademyId) {
                          return;
                        }
                        setState(() {
                          _selectedAcademyId = value;
                          _batches = <Map<String, dynamic>>[];
                        });
                        ApiSession.instance.setSelectedAcademy(academyId: value);
                        await _load();
                      },
                    ),
                    const SizedBox(height: 12),
                    ..._batches.map((Map<String, dynamic> batch) {
                      final List<String> days = _batchDays(batch);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                          color: const Color(0x08FFFFFF),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        batch['name']?.toString() ?? 'Batch',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 18,
                                            color: Color(0x99FFFFFF),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${batch['startTime'] ?? '-'} - ${batch['endTime'] ?? '-'}',
                                            style: const TextStyle(
                                              color: Color(0xCCFFFFFF),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: () =>
                                          _openEditor(batch: batch),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteBatch(batch),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFE3220D),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (days.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: days
                                    .map(
                                      (String day) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: const Color(0x2600C9A7),
                                        ),
                                        child: Text(
                                          day,
                                          style: const TextStyle(
                                            color: Color(0xFF00C9A7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Coach: ${batch['coachName'] ?? '-'}',
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    ElevatedButton(
                      onPressed: () => _openEditor(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        foregroundColor: const Color(0xFF1D1D1D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add Batch'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
