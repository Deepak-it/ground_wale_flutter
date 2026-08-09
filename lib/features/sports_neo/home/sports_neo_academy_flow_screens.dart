import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class SportsNeoAcademyDetailScreen extends StatefulWidget {
  const SportsNeoAcademyDetailScreen({
    super.key,
    this.selectedCity,
  });

  final String? selectedCity;

  @override
  State<SportsNeoAcademyDetailScreen> createState() =>
      _SportsNeoAcademyDetailScreenState();
}

class _SportsNeoAcademyDetailScreenState
    extends State<SportsNeoAcademyDetailScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _enrollments = <Map<String, dynamic>>[];

  String? get _playerId => ApiSession.instance.ownerId;
  String? get _cityFilter {
    final String explicit = widget.selectedCity?.trim() ?? '';
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final String sessionCity = ApiSession.instance.city?.trim() ?? '';
    return sessionCity.isEmpty ? null : sessionCity;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String? playerId = _playerId;
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        _api.discoverAcademies(
          playerId: playerId,
          city: _cityFilter,
        ),
        if (playerId != null && playerId.isNotEmpty)
          _api.listPlayerAcademyEnrollments(playerId)
        else
          Future<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _academies = (results[0] as List<dynamic>)
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();
        _enrollments = (results[1] as List<dynamic>)
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();
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
            final Map<String, dynamic> normalized =
                Map<String, dynamic>.from(academy);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF121C3E),
        foregroundColor: Colors.white,
        title: const Text('Academies'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            : _error != null
            ? _AcademyErrorState(message: _error!, onRetry: _load)
            : RefreshIndicator(
                color: const Color(0xFF2563EB),
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: <Widget>[
                    _AcademySectionHeader(
                      title: 'Academies',
                      subtitle: _cityFilter == null
                          ? 'Discover academies across all cities'
                          : 'Discover academies in ${_cityFilter!}',
                      actionText: 'See all',
                      onTap: _academies.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _AcademyListScreen(
                                    academies: _academies,
                                    cityLabel: _cityFilter,
                                    onOpenAcademy: _openAcademy,
                                  ),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 12),
                    if (_academies.isEmpty)
                      const _AcademyEmptyCard(
                        message: 'No academies found for the selected city.',
                      )
                    else
                      SizedBox(
                        height: 360,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _academies.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, int index) {
                            final Map<String, dynamic> academy = _academies[index];
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
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, int index) {
                            final Map<String, dynamic> academy = enrolledAcademies[index];
                            return _MyAcademyCard(
                              academy: academy,
                              onTap: () => _openAcademy(academy),
                            );
                          },
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
    required this.onOpenAcademy,
  });

  final List<Map<String, dynamic>> academies;
  final String? cityLabel;
  final Future<void> Function(Map<String, dynamic> academy) onOpenAcademy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121C3E),
        foregroundColor: Colors.white,
        title: Text(cityLabel == null ? 'All Academies' : '$cityLabel Academies'),
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

  List<Map<String, dynamic>> get _feePlans => _mapList(_selectedBatch['feePlans']);

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
      final Map<String, dynamic> student = await _api.joinAcademy(
        playerId,
        <String, dynamic>{
          'academyId': _text(_academy['_id']),
          if (_text(_selectedBatch['_id']).isNotEmpty)
            'batchId': _text(_selectedBatch['_id']),
          'batchName': _text(_selectedBatch['name']),
          'planIndex': 0,
          'fullName': widget.playerName,
          'phone': widget.playerPhone,
        },
      );

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
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
                for (final Map<String, dynamic> plan in plans) ...<Widget>[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          _text(plan['duration']).isEmpty
                              ? 'Plan'
                              : _text(plan['duration']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _priceLabel(plan['price']),
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
    final Map<String, dynamic> primaryPlan =
        _feePlans.isNotEmpty ? _feePlans.first : <String, dynamic>{};

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
                    children: List<Widget>.generate(_batches.length, (int index) {
                      final Map<String, dynamic> item = _batches[index];
                      final bool active = index == _selectedBatchIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBatchIndex = index),
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
                _InfoRow(
                  label: 'Coaching Days',
                  value: _daysLabel(batch),
                ),
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
          TextButton(
            onPressed: onTap,
            child: Text(actionText!),
          ),
      ],
    );
  }
}

class _MyAcademyCard extends StatelessWidget {
  const _MyAcademyCard({
    required this.academy,
    required this.onTap,
  });

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
              _text(academy['name']).isEmpty ? 'Academy' : _text(academy['name']),
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
    final Map<String, dynamic> firstBatch =
        batches.isNotEmpty ? batches.first : <String, dynamic>{};
    final List<Map<String, dynamic>> feePlans = _mapList(firstBatch['feePlans']);
    final Map<String, dynamic> firstPlan =
        feePlans.isNotEmpty ? feePlans.first : <String, dynamic>{};
    final List<String> facilities = _academyFacilities(academy, firstBatch);
    final String headerLabel = _academyHeaderLabel(academy, firstBatch);
    final String statusLabel = _academyStatusLabel(academy, firstBatch, enrolled);
    final String location = _locationLabel(academy);
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 176,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _AcademyImage(imageUrl: _coverImage(academy)),
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
                      border: Border(
                        top: BorderSide(color: Color(0x1FFFFFFF)),
                      ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 18),
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
              child: _AcademyImage(imageUrl: _coverImage(academy)),
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
                  children: _textList(academy['sports'])
                      .map((String sport) => _MiniChip(label: sport))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyImage extends StatelessWidget {
  const _AcademyImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
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

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF1E293B),
          alignment: Alignment.center,
          child: const Icon(
            Icons.school_rounded,
            color: Color(0xFF93C5FD),
            size: 52,
          ),
        );
      },
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
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

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
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
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

String _coverImage(Map<String, dynamic> academy) {
  final String primary = _text(academy['image']);
  if (primary.isNotEmpty) {
    return primary;
  }
  final List<String> images = _textList(academy['groundImages']);
  if (images.isNotEmpty) {
    return images.first;
  }
  return '';
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
  return city.isNotEmpty ? city : (state.isNotEmpty ? state : 'Location unavailable');
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