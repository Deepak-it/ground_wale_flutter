import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyAnnouncementScreen extends StatefulWidget {
  const AcademyAnnouncementScreen({
    super.key,
    this.onHomeTap,
    this.onProfileTap,
    this.showBottomNav = true,
  });

  final VoidCallback? onHomeTap;
  final VoidCallback? onProfileTap;
  final bool showBottomNav;

  @override
  State<AcademyAnnouncementScreen> createState() =>
      _AcademyAnnouncementScreenState();
}

class _AcademyAnnouncementScreenState extends State<AcademyAnnouncementScreen> {
  int _selectedFilter = 0;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  String? _selectedAcademyId;

  final List<_AcademyAnnouncement> _announcements = <_AcademyAnnouncement>[];

  String _academyId(Map<String, dynamic> academy) {
    return academy['_id']?.toString() ?? academy['id']?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _announcements.clear();
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
      final List<Map<String, dynamic>> items = await GroundWaleApi.instance
          .listAcademyAnnouncements(ownerId, academyId: academyId);
      if (!mounted) {
        return;
      }

      setState(() {
        _academies = academies;
        _selectedAcademyId = academyId;
        _announcements
          ..clear()
          ..addAll(
            items.map(
              (Map<String, dynamic> item) => _AcademyAnnouncement.fromMap(item),
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    final List<_AcademyAnnouncement> filtered = _filteredAnnouncements();

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _onCreateTap,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF00C9A7),
                            foregroundColor: const Color(0xFF242424),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF1C333B)),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text(
                            'Create',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SearchBox(
                      controller: _searchController,
                      hint: 'Search announcement',
                      onChanged: (_) => setState(() {}),
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
                      onChanged: (String? value) {
                        if (value == null || value == _selectedAcademyId) {
                          return;
                        }
                        setState(() => _selectedAcademyId = value);
                        ApiSession.instance.setSelectedAcademy(academyId: value);
                        _loadAnnouncements();
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final String label = _filters[index];
                          final bool selected = index == _selectedFilter;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilter = index),
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
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00C9A7),
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            'No announcements found',
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.map(
                        (_AcademyAnnouncement item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnnouncementListCard(
                            announcement: item,
                            onTap: () => _openDetail(item),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Future<void> _onCreateTap() async {
    final _AcademyAnnouncement? draft = await Navigator.of(context)
        .push<_AcademyAnnouncement>(
          MaterialPageRoute<_AcademyAnnouncement>(
            builder: (_) => const _AcademySendAnnouncementScreen(),
          ),
        );

    if (draft == null) {
      return;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner session not found')),
        );
      }
      return;
    }

    try {
      final Map<String, dynamic> saved = await GroundWaleApi.instance
          .createAcademyAnnouncement(ownerId, draft.toPayload());
      final _AcademyAnnouncement created = _AcademyAnnouncement.fromMap(saved);

      if (!mounted) {
        return;
      }

      setState(() {
        _announcements.insert(0, created);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement Sent Successfully')),
      );
    }
  }

  Future<void> _openDetail(_AcademyAnnouncement item) async {
    final _AnnouncementDetailResult? result = await Navigator.of(context)
        .push<_AnnouncementDetailResult>(
          MaterialPageRoute<_AnnouncementDetailResult>(
            builder: (_) =>
                _AcademyAnnouncementDetailScreen(announcement: item),
          ),
        );

    if (result == null) {
      return;
    }

    setState(() {
      final int index = _announcements.indexWhere(
        (_AcademyAnnouncement element) => element.id == item.id,
      );
      if (index < 0) {
        return;
      }

      if (result.action == _AnnouncementDetailAction.delete) {
        _announcements.removeAt(index);
      } else if (result.updated != null) {
        _announcements[index] = result.updated!;
      }
    });

    if (!mounted) {
      return;
    }

    if (result.action == _AnnouncementDetailAction.delete) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Announcement deleted')));
    } else if (result.action == _AnnouncementDetailAction.resend) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Announcement resent')));
    }
  }

  List<_AcademyAnnouncement> _filteredAnnouncements() {
    final String query = _searchController.text.trim().toLowerCase();

    return _announcements.where((_AcademyAnnouncement item) {
      final bool matchesFilter = switch (_selectedFilter) {
        0 => true,
        1 => item.kind == _AnnouncementKind.fees,
        2 => item.kind == _AnnouncementKind.schedule,
        _ => true,
      };

      if (!matchesFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return item.title.toLowerCase().contains(query) ||
          item.message.toLowerCase().contains(query);
    }).toList();
  }
}

class _AcademySendAnnouncementScreen extends StatefulWidget {
  const _AcademySendAnnouncementScreen({this.initial});

  final _AcademyAnnouncement? initial;

  @override
  State<_AcademySendAnnouncementScreen> createState() =>
      _AcademySendAnnouncementScreenState();
}

class _AcademySendAnnouncementScreenState
    extends State<_AcademySendAnnouncementScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  bool _scheduleLater = true;
  _AnnouncementAudience _audience = _AnnouncementAudience.all;
  _AnnouncementKind _kind = _AnnouncementKind.general;
  bool _isLoadingAudience = true;
  List<_AudienceOption> _audienceOptions = const <_AudienceOption>[];
  String? _selectedBatchId;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  @override
  void initState() {
    super.initState();
    final _AcademyAnnouncement? initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _messageController = TextEditingController(text: initial?.message ?? '');
    _audience = initial?.audience ?? _AnnouncementAudience.all;
    _selectedBatchId = initial?.batchId;
    _kind = initial?.kind ?? _AnnouncementKind.general;
    _scheduleLater = initial?.status == _AnnouncementStatus.scheduled;
    if (initial?.scheduledAt != null) {
      _scheduledDate = initial!.scheduledAt;
      _scheduledTime = TimeOfDay.fromDateTime(initial.scheduledAt!);
    }
    _loadAudienceOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initial != null;

  Future<void> _loadAudienceOptions() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() {
          _audienceOptions = const <_AudienceOption>[
            _AudienceOption(id: null, label: 'All Students'),
          ];
          _isLoadingAudience = false;
        });
      }
      return;
    }

    try {
      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId);
      final List<_AudienceOption> options = <_AudienceOption>[
        const _AudienceOption(id: null, label: 'All Students'),
        ...batches.map(
          (Map<String, dynamic> batch) => _AudienceOption(
            id: batch['_id']?.toString(),
            label: batch['name']?.toString().trim().isNotEmpty == true
                ? batch['name'].toString().trim()
                : 'Batch',
          ),
        ),
      ];

      if (!mounted) {
        return;
      }
      setState(() {
        _audienceOptions = options;
        if (_selectedBatchId != null &&
            options.every((o) => o.id != _selectedBatchId)) {
          _selectedBatchId = null;
          _audience = _AnnouncementAudience.all;
        }
        _isLoadingAudience = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _audienceOptions = const <_AudienceOption>[
          _AudienceOption(id: null, label: 'All Students'),
        ];
        _isLoadingAudience = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _IconTap(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Announcement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isEdit)
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1C333B)),
                        color: const Color(0xFF00C9A7),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const _Label('Title'),
              const SizedBox(height: 8),
              _InputBox(
                child: AppTextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter title',
                    hintStyle: TextStyle(color: Color(0x99FFFFFF)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _Label('Message'),
              const SizedBox(height: 8),
              _InputBox(
                child: AppTextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  minLines: 4,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Write your message...',
                    hintStyle: TextStyle(color: Color(0x99FFFFFF)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Select Audience'),
              const SizedBox(height: 8),
              if (_isLoadingAudience)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00C9A7),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _audienceOptions
                      .map(
                        (_AudienceOption option) => _SelectableChip(
                          label: option.label,
                          selected: option.id == null
                              ? _selectedBatchId == null
                              : _selectedBatchId == option.id,
                          onTap: () {
                            setState(() {
                              _selectedBatchId = option.id;
                              _audience = option.id == null
                                  ? _AnnouncementAudience.all
                                  : _AnnouncementAudience.batch;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 20),
              const _SectionTitle('Announcement Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _AnnouncementKind.values
                    .map(
                      (_AnnouncementKind value) => _SelectableChip(
                        label: value.label,
                        selected: _kind == value,
                        onTap: () => setState(() => _kind = value),
                        icon: Icon(
                          value.icon,
                          size: 16,
                          color: value.iconColor,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              const _Label('Attachments (Optional)'),
              const SizedBox(height: 8),
              _InputBox(
                child: Row(
                  children: const <Widget>[
                    Icon(Icons.attach_file_rounded, color: Color(0x99FFFFFF)),
                    SizedBox(width: 10),
                    Text(
                      'Add Image / PDF',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Schedule Later',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _scheduleLater,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF00C9A7),
                    onChanged: (bool value) {
                      setState(() {
                        _scheduleLater = value;
                      });
                    },
                  ),
                ],
              ),
              if (_scheduleLater) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: _InputBox(
                          child: Text(
                            _scheduledDate == null
                                ? 'dd-mm-yyyy'
                                : _dateLabel(_scheduledDate!),
                            style: TextStyle(
                              color: _scheduledDate == null
                                  ? const Color(0x99FFFFFF)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: _InputBox(
                          child: Text(
                            _scheduledTime == null
                                ? '--:--'
                                : _scheduledTime!.format(context),
                            style: TextStyle(
                              color: _scheduledTime == null
                                  ? const Color(0x99FFFFFF)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _sendAnnouncement,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF00C9A7),
                    foregroundColor: const Color(0xFF1D1D1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEdit ? 'Update Announcement' : 'Send Announcement',
                    style: const TextStyle(
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
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year, now.month, now.day);
    DateTime initialDate = _scheduledDate == null
        ? firstDate
        : DateTime(
            _scheduledDate!.year,
            _scheduledDate!.month,
            _scheduledDate!.day,
          );
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
      initialDate: initialDate,
    );

    if (picked == null) {
      return;
    }

    setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );

    if (picked == null) {
      return;
    }

    setState(() => _scheduledTime = picked);
  }

  void _sendAnnouncement() {
    final String title = _titleController.text.trim();
    final String message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and message')),
      );
      return;
    }

    if (_scheduleLater && (_scheduledDate == null || _scheduledTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select schedule date and time')),
      );
      return;
    }

    final DateTime now = DateTime.now();
    DateTime? scheduledAt;
    if (_scheduleLater) {
      scheduledAt = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );
      if (!scheduledAt.isAfter(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a future schedule date/time'),
          ),
        );
        return;
      }
    }
    final String id =
        widget.initial?.id ?? now.microsecondsSinceEpoch.toString();

    final _AcademyAnnouncement announcement = _AcademyAnnouncement(
      id: id,
      title: title,
      message: message,
      kind: _kind,
      audience: _audience,
      batchId: _selectedBatchId,
      batchName: _selectedBatchId == null
          ? null
          : _audienceOptions
                .firstWhere(
                  (_AudienceOption o) => o.id == _selectedBatchId,
                  orElse: () => const _AudienceOption(id: null, label: ''),
                )
                .label,
      status: _scheduleLater
          ? _AnnouncementStatus.scheduled
          : _AnnouncementStatus.sent,
      timeLabel: _scheduleLater
          ? '${_dateLabel(_scheduledDate!)} ${_scheduledTime!.format(context)}'
          : _timelineDate(now),
      scheduledAt: scheduledAt,
      sentAt: _scheduleLater ? null : now,
      seenStudents: widget.initial?.seenStudents ?? _seenStudents,
      notSeenStudents: widget.initial?.notSeenStudents ?? _notSeenStudents,
      attachmentName: widget.initial?.attachmentName,
      attachmentSize: widget.initial?.attachmentSize,
    );

    Navigator.of(context).pop(announcement);
  }
}

class _AcademyAnnouncementDetailScreen extends StatefulWidget {
  const _AcademyAnnouncementDetailScreen({required this.announcement});

  final _AcademyAnnouncement announcement;

  @override
  State<_AcademyAnnouncementDetailScreen> createState() =>
      _AcademyAnnouncementDetailScreenState();
}

class _AcademyAnnouncementDetailScreenState
    extends State<_AcademyAnnouncementDetailScreen> {
  late _AcademyAnnouncement _announcement;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: <Widget>[
                  _IconTap(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Announcement Detail',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _AnnouncementDetailCard(
                  announcement: _announcement,
                  onSeenTap: () => _openRecipients(true),
                  onNotSeenTap: () => _openRecipients(false),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF0F2027),
          border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _editAnnouncement,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit Announcement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SecondaryActionButton(
                    label: 'Resend',
                    icon: Icons.refresh_rounded,
                    color: const Color(0xFFE2E8F0),
                    backgroundColor: const Color(0x14FFFFFF),
                    onTap: _resendAnnouncement,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryActionButton(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    backgroundColor: const Color(0x1AEF4444),
                    onTap: _deleteAnnouncement,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openRecipients(bool seen) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _AcademyAnnouncementRecipientsScreen(
          announcement: _announcement,
          seen: seen,
        ),
      ),
    );
  }

  Future<void> _editAnnouncement() async {
    final _AcademyAnnouncement? draft = await Navigator.of(context)
        .push<_AcademyAnnouncement>(
          MaterialPageRoute<_AcademyAnnouncement>(
            builder: (_) =>
                _AcademySendAnnouncementScreen(initial: _announcement),
          ),
        );

    if (draft == null) {
      return;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner session not found')),
        );
      }
      return;
    }

    try {
      final Map<String, dynamic> saved = await GroundWaleApi.instance
          .updateAcademyAnnouncement(
            ownerId,
            _announcement.id,
            draft.toPayload(),
          );
      final _AcademyAnnouncement updated = _AcademyAnnouncement.fromMap(saved);
      setState(() => _announcement = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      _AnnouncementDetailResult(
        action: _AnnouncementDetailAction.edit,
        updated: _announcement,
      ),
    );
  }

  void _resendAnnouncement() {
    _resendAnnouncementApi();
  }

  Future<void> _resendAnnouncementApi() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner session not found')),
        );
      }
      return;
    }

    final _AcademyAnnouncement next = _announcement.copyWith(
      status: _AnnouncementStatus.sent,
      sentAt: DateTime.now(),
      scheduledAt: null,
      timeLabel: _timelineDate(DateTime.now()),
    );

    try {
      final Map<String, dynamic> saved = await GroundWaleApi.instance
          .updateAcademyAnnouncement(
            ownerId,
            _announcement.id,
            next.toPayload(),
          );
      final _AcademyAnnouncement updated = _AcademyAnnouncement.fromMap(saved);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        _AnnouncementDetailResult(
          action: _AnnouncementDetailAction.resend,
          updated: updated,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Owner session not found')));
      return;
    }

    try {
      await GroundWaleApi.instance.deleteAcademyAnnouncement(
        ownerId,
        _announcement.id,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      const _AnnouncementDetailResult(action: _AnnouncementDetailAction.delete),
    );
  }
}

class _AcademyAnnouncementRecipientsScreen extends StatefulWidget {
  const _AcademyAnnouncementRecipientsScreen({
    required this.announcement,
    required this.seen,
  });

  final _AcademyAnnouncement announcement;
  final bool seen;

  @override
  State<_AcademyAnnouncementRecipientsScreen> createState() =>
      _AcademyAnnouncementRecipientsScreenState();
}

class _AcademyAnnouncementRecipientsScreenState
    extends State<_AcademyAnnouncementRecipientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_StudentDelivery> source = widget.seen
        ? widget.announcement.seenStudents
        : widget.announcement.notSeenStudents;

    final String query = _searchController.text.trim().toLowerCase();
    final List<_StudentDelivery> students = source.where((
      _StudentDelivery item,
    ) {
      return query.isEmpty || item.name.toLowerCase().contains(query);
    }).toList();

    final int total =
        widget.announcement.seenStudents.length +
        widget.announcement.notSeenStudents.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: <Widget>[
                  _IconTap(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                    color: const Color(0xFF242424),
                    backgroundColor: const Color(0xFFF4F4F4),
                    borderColor: const Color(0x1F242424),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.seen
                              ? 'Seen by Students'
                              : 'Not Seen by Students',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${source.length} / $total Students',
                          style: const TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SearchBox(
                        controller: _searchController,
                        hint: 'Search student',
                        dark: false,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.seen
                            ? 'Seen (${students.length})'
                            : 'Not seen (${students.length})',
                        style: const TextStyle(
                          color: Color(0xFF313638),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: students.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final _StudentDelivery student = students[index];
                            return _RecipientTile(
                              student: student,
                              seen: widget.seen,
                            );
                          },
                        ),
                      ),
                    ],
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

class _AnnouncementDetailCard extends StatelessWidget {
  const _AnnouncementDetailCard({
    required this.announcement,
    required this.onSeenTap,
    required this.onNotSeenTap,
  });

  final _AcademyAnnouncement announcement;
  final VoidCallback onSeenTap;
  final VoidCallback onNotSeenTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1E293B), Color(0xFF334155)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x263B82F6),
                ),
                child: Icon(
                  announcement.kind.icon,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(status: announcement.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            announcement.message,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                announcement.timeLabel,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x14FFFFFF)),
          const SizedBox(height: 10),
          const Text(
            'Sent To:',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x14FFFFFF),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.groups_2_outlined,
                  color: Color(0xFFE2E8F0),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  announcement.audienceLabel,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (announcement.attachmentName != null) ...<Widget>[
            const SizedBox(height: 16),
            const Divider(color: Color(0x14FFFFFF)),
            const SizedBox(height: 10),
            const Text(
              'Attachment',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x33000000),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0x26EF4444),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          announcement.attachmentName!,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (announcement.attachmentSize != null)
                          Text(
                            announcement.attachmentSize!,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0x1AFFFFFF),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Color(0x14FFFFFF)),
          _SeenTile(
            label: 'Seen by ${announcement.seenStudents.length} students',
            seen: true,
            onTap: onSeenTap,
          ),
          _SeenTile(
            label:
                'Not seen by ${announcement.notSeenStudents.length} students',
            seen: false,
            onTap: onNotSeenTap,
          ),
        ],
      ),
    );
  }
}

class _SeenTile extends StatelessWidget {
  const _SeenTile({
    required this.label,
    required this.seen,
    required this.onTap,
  });

  final String label;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = seen ? const Color(0xFF4ADE80) : const Color(0xFFEF4444);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint.withAlpha(38),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                seen ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: tint,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF64748B),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementListCard extends StatelessWidget {
  const _AnnouncementListCard({
    required this.announcement,
    required this.onTap,
  });

  final _AcademyAnnouncement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  announcement.kind.icon,
                  color: announcement.kind.iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: announcement.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              announcement.timeLabel,
              style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({required this.student, required this.seen});

  final _StudentDelivery student;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final Color tint = seen ? const Color(0xFF099459) : const Color(0xFFE3220D);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFDFE5E7),
            child: Text(
              _initials(student.name),
              style: const TextStyle(
                color: Color(0xFF313638),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  student.name,
                  style: const TextStyle(
                    color: Color(0xFF313638),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (seen)
                  Text(
                    'Seen at ${student.time ?? '10:30 AM'}',
                    style: const TextStyle(
                      color: Color(0xFF313638),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: tint.withAlpha(31),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  seen ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 16,
                  color: tint,
                ),
                const SizedBox(width: 4),
                Text(
                  seen ? 'Seen' : 'Not Seen',
                  style: TextStyle(
                    color: tint,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: color,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _AnnouncementStatus status;

  @override
  Widget build(BuildContext context) {
    final Color tint = status == _AnnouncementStatus.sent
        ? const Color(0xFF20D487)
        : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: tint.withAlpha(31),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: tint,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hint,
    this.dark = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool dark;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? const Color(0x1FFFFFFF) : const Color(0x1F242424),
        ),
        color: dark ? const Color(0x0FFFFFFF) : const Color(0x0F242424),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search_rounded,
            color: dark ? const Color(0x99FFFFFF) : const Color(0x99242424),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF242424),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: dark
                      ? const Color(0x99FFFFFF)
                      : const Color(0x99242424),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.backgroundColor = const Color(0x0FFFFFFF),
    this.borderColor = const Color(0x14FFFFFF),
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: child,
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF00C9A7)
                  : const Color(0x1FFFFFFF),
            ),
            color: selected ? const Color(0xFF00C9A7) : const Color(0x0FFFFFFF),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[icon!, const SizedBox(width: 8)],
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF242424) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceOption {
  const _AudienceOption({required this.id, required this.label});

  final String? id;
  final String label;
}

enum _AnnouncementAudience {
  all('All Students'),
  morning('Morning Batch'),
  evening('Evening Batch'),
  batch('Batch');

  const _AnnouncementAudience(this.label);
  final String label;
}

enum _AnnouncementKind {
  fees('Fees', Icons.currency_rupee_rounded, Color(0xFF08B36A)),
  schedule('Schedule', Icons.schedule_rounded, Color(0xFF4E80ED)),
  holiday('Holiday', Icons.calendar_month_rounded, Color(0xFF9638D9)),
  general('General', Icons.campaign_rounded, Color(0xFFE3220D));

  const _AnnouncementKind(this.label, this.icon, this.iconColor);
  final String label;
  final IconData icon;
  final Color iconColor;
}

enum _AnnouncementStatus {
  sent('Sent'),
  scheduled('Scheduled');

  const _AnnouncementStatus(this.label);
  final String label;
}

class _AcademyAnnouncement {
  const _AcademyAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.kind,
    required this.audience,
    required this.status,
    required this.timeLabel,
    this.batchId,
    this.batchName,
    this.scheduledAt,
    this.sentAt,
    required this.seenStudents,
    required this.notSeenStudents,
    this.attachmentName,
    this.attachmentSize,
  });

  final String id;
  final String title;
  final String message;
  final _AnnouncementKind kind;
  final _AnnouncementAudience audience;
  final _AnnouncementStatus status;
  final String timeLabel;
  final String? batchId;
  final String? batchName;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String? attachmentName;
  final String? attachmentSize;
  final List<_StudentDelivery> seenStudents;
  final List<_StudentDelivery> notSeenStudents;

  String get audienceLabel {
    if (audience == _AnnouncementAudience.batch &&
        batchName != null &&
        batchName!.trim().isNotEmpty) {
      return batchName!.trim();
    }
    return audience.label;
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'title': title,
      'message': message,
      'kind': kind.name,
      'audience': audience.name,
      'batchId': audience == _AnnouncementAudience.batch ? batchId : null,
      'status': status.name,
      if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
      if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
      if (attachmentName != null && attachmentName!.isNotEmpty)
        'attachmentName': attachmentName,
      if (attachmentSize != null && attachmentSize!.isNotEmpty)
        'attachmentSize': attachmentSize,
      'seenStudents': seenStudents
          .map((_StudentDelivery item) => item.toMap())
          .toList(),
      'notSeenStudents': notSeenStudents
          .map((_StudentDelivery item) => item.toMap())
          .toList(),
    };
  }

  _AcademyAnnouncement copyWith({
    String? id,
    String? title,
    String? message,
    _AnnouncementKind? kind,
    _AnnouncementAudience? audience,
    _AnnouncementStatus? status,
    String? timeLabel,
    String? batchId,
    String? batchName,
    DateTime? scheduledAt,
    DateTime? sentAt,
    String? attachmentName,
    String? attachmentSize,
    List<_StudentDelivery>? seenStudents,
    List<_StudentDelivery>? notSeenStudents,
  }) {
    return _AcademyAnnouncement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      kind: kind ?? this.kind,
      audience: audience ?? this.audience,
      status: status ?? this.status,
      timeLabel: timeLabel ?? this.timeLabel,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      seenStudents: seenStudents ?? this.seenStudents,
      notSeenStudents: notSeenStudents ?? this.notSeenStudents,
    );
  }

  static _AcademyAnnouncement fromMap(Map<String, dynamic> map) {
    final String id = map['_id']?.toString() ?? map['id']?.toString() ?? '';
    final _AnnouncementKind kind = _AnnouncementKindX.fromApi(
      map['kind']?.toString(),
    );
    final _AnnouncementAudience audience = _AnnouncementAudienceX.fromApi(
      map['audience']?.toString(),
    );
    final _AnnouncementStatus status = _AnnouncementStatusX.fromApi(
      map['status']?.toString(),
    );
    final dynamic batchRef = map['batchId'];
    final String? batchId = batchRef is Map<String, dynamic>
        ? batchRef['_id']?.toString()
        : batchRef?.toString();
    final String? batchName =
        map['batchName']?.toString() ??
        (batchRef is Map<String, dynamic>
            ? batchRef['name']?.toString()
            : null);

    final DateTime? scheduledAt = DateTime.tryParse(
      map['scheduledAt']?.toString() ?? '',
    );
    final DateTime? sentAt = DateTime.tryParse(map['sentAt']?.toString() ?? '');
    final DateTime? createdAt = DateTime.tryParse(
      map['createdAt']?.toString() ?? '',
    );
    final DateTime timelineDate =
        scheduledAt ?? sentAt ?? createdAt ?? DateTime.now();

    return _AcademyAnnouncement(
      id: id,
      title: map['title']?.toString() ?? 'Announcement',
      message: map['message']?.toString() ?? '',
      kind: kind,
      audience: audience,
      status: status,
      timeLabel: _timelineDate(timelineDate),
      batchId: batchId,
      batchName: batchName,
      scheduledAt: scheduledAt,
      sentAt: sentAt,
      seenStudents: _StudentDelivery.fromAnyList(
        map['seenStudents'] as List<dynamic>?,
      ),
      notSeenStudents: _StudentDelivery.fromAnyList(
        map['notSeenStudents'] as List<dynamic>?,
      ),
      attachmentName: map['attachmentName']?.toString(),
      attachmentSize: map['attachmentSize']?.toString(),
    );
  }
}

class _StudentDelivery {
  const _StudentDelivery({required this.name, this.time});

  final String name;
  final String? time;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      if (time != null && time!.isNotEmpty) 'time': time,
    };
  }

  static List<_StudentDelivery> fromAnyList(List<dynamic>? raw) {
    return (raw ?? <dynamic>[])
        .whereType<Map>()
        .map(
          (Map item) => _StudentDelivery(
            name: item['name']?.toString() ?? 'Student',
            time: item['time']?.toString(),
          ),
        )
        .toList();
  }
}

extension _AnnouncementAudienceX on _AnnouncementAudience {
  static _AnnouncementAudience fromApi(String? value) {
    return _AnnouncementAudience.values.firstWhere(
      (_AnnouncementAudience item) => item.name == value,
      orElse: () => _AnnouncementAudience.all,
    );
  }
}

extension _AnnouncementKindX on _AnnouncementKind {
  static _AnnouncementKind fromApi(String? value) {
    return _AnnouncementKind.values.firstWhere(
      (_AnnouncementKind item) => item.name == value,
      orElse: () => _AnnouncementKind.general,
    );
  }
}

extension _AnnouncementStatusX on _AnnouncementStatus {
  static _AnnouncementStatus fromApi(String? value) {
    return _AnnouncementStatus.values.firstWhere(
      (_AnnouncementStatus item) => item.name == value,
      orElse: () => _AnnouncementStatus.sent,
    );
  }
}

class _AnnouncementDetailResult {
  const _AnnouncementDetailResult({required this.action, this.updated});

  final _AnnouncementDetailAction action;
  final _AcademyAnnouncement? updated;
}

enum _AnnouncementDetailAction { edit, resend, delete }

const List<String> _filters = <String>['All', 'Fees', 'Schedule'];

const List<_StudentDelivery> _seenStudents = <_StudentDelivery>[
  _StudentDelivery(name: 'Rahul Sharma', time: '10:30 AM'),
  _StudentDelivery(name: 'Ankit Verma', time: '10:31 AM'),
  _StudentDelivery(name: 'Lekhi', time: '10:32 AM'),
  _StudentDelivery(name: 'Gagii', time: '10:35 AM'),
  _StudentDelivery(name: 'Anand', time: '10:40 AM'),
  _StudentDelivery(name: 'Pardhan', time: '10:41 AM'),
  _StudentDelivery(name: 'Aman Verma', time: '10:45 AM'),
  _StudentDelivery(name: 'Yash', time: '10:47 AM'),
  _StudentDelivery(name: 'Nitin', time: '10:49 AM'),
  _StudentDelivery(name: 'Kushal', time: '10:50 AM'),
  _StudentDelivery(name: 'Piyush', time: '10:51 AM'),
  _StudentDelivery(name: 'Raman', time: '10:52 AM'),
  _StudentDelivery(name: 'Harsh', time: '10:53 AM'),
  _StudentDelivery(name: 'Karan', time: '10:54 AM'),
  _StudentDelivery(name: 'Naman', time: '10:56 AM'),
  _StudentDelivery(name: 'Bhuvan', time: '10:57 AM'),
  _StudentDelivery(name: 'Ravi', time: '10:58 AM'),
  _StudentDelivery(name: 'Gaurav', time: '10:59 AM'),
  _StudentDelivery(name: 'Ayush', time: '11:00 AM'),
  _StudentDelivery(name: 'Sumit', time: '11:01 AM'),
];

const List<_StudentDelivery> _notSeenStudents = <_StudentDelivery>[
  _StudentDelivery(name: 'Aman Verma'),
  _StudentDelivery(name: 'Lekhi'),
  _StudentDelivery(name: 'Pardhan'),
  _StudentDelivery(name: 'Gagii'),
  _StudentDelivery(name: 'Anand'),
  _StudentDelivery(name: 'Rahul Sharma'),
];

String _dateLabel(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String year = date.year.toString();
  return '$day-$month-$year';
}

String _timelineDate(DateTime dateTime) {
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

  final int hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  final String amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${months[dateTime.month - 1]} ${dateTime.day}, $hour:$minute $amPm';
}

String _initials(String name) {
  final List<String> parts = name
      .split(' ')
      .where((String p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'S';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}


