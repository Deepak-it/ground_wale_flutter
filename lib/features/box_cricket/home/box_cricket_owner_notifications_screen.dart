import 'package:flutter/material.dart';
import 'package:ground_wale/features/box_cricket/home/box_cricket_dashboard_screen.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_upcoming_bookings_screen.dart';

class BoxCricketOwnerNotificationsScreen extends StatefulWidget {
  const BoxCricketOwnerNotificationsScreen({
    super.key,
    this.showBottomNav = true,
    this.onBack,
    this.onOpenBookings,
    this.onNotificationsChanged,
  });

  final bool showBottomNav;
  final VoidCallback? onBack;
  final VoidCallback? onOpenBookings;
  final VoidCallback? onNotificationsChanged;
  @override
  State<BoxCricketOwnerNotificationsScreen> createState() =>
      _BoxCricketOwnerNotificationsScreenState();
}

class _BoxCricketOwnerNotificationsScreenState
    extends State<BoxCricketOwnerNotificationsScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;

  bool _isLoading = true;
  int _selectedTab = 0;
  List<_OwnerNotificationItem> _items = <_OwnerNotificationItem>[];

  // ── colour tokens ─────────────────────────────────────────────
  static const Color _bg       = Color(0xFF1B1F1B);
  static const Color _green    = Color(0xFF08B36A);
  static const Color _yellow   = Color(0xFFDDF730);
  static const Color _red      = Color(0xFFE3220D);
  static const Color _dark     = Color(0xFF1C333B);
  static const Color _card     = Color(0xFF232823);
  static const Color _border   = Color(0xFF2E342E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── EXACT SAME LOGIC ──────────────────────────────────────────

  Future<void> _load() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _items = <_OwnerNotificationItem>[];
        });
      }
      return;
    }
    try {
      final List<Map<String, dynamic>> raw =
          await _api.listNotifications(ownerId);
      if (!mounted) return;
      setState(() {
        _items = raw.map(_OwnerNotificationItem.fromMap).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _items = <_OwnerNotificationItem>[];
      });
    }
  }

  List<_OwnerNotificationItem> get _visibleItems {
    if (_selectedTab == 1) {
      return _items.where((item) => item.type == 'booking').toList();
    }
    if (_selectedTab == 2) {
      return _items.where((item) => item.type != 'booking').toList();
    }
    return _items;
  }

  int get _unreadCount => _items.where((item) => !item.isRead).length;

  Future<void> _markRead(_OwnerNotificationItem item) async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty || item.id.isEmpty || item.isRead) {
      return;
    }
    try {
      await _api.markNotificationRead(ownerId, item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.map((existing) {
          if (existing.id != item.id) return existing;
          return existing.copyWith(isRead: true);
        }).toList();
      });
      widget.onNotificationsChanged?.call();
    } catch (_) {}
  }

    Future<void> _openRequests(_OwnerNotificationItem item) async {

      widget.onOpenBookings?.call();
    }
  Future<void> _handleAction(
      _OwnerNotificationItem item, bool accept) async {
    if (item.bookingId.isEmpty) return;
    try {
      if (accept) {
        await _api.acceptBooking(item.bookingId);
      } else {
        await _api.rejectBooking(item.bookingId, reason: 'Not Available');
      }
      await _markRead(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Request accepted' : 'Request rejected'),
        ),
      );
      await _load();
      widget.onNotificationsChanged?.call();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final List<_OwnerNotificationItem> items = _visibleItems;

    return Container(
      color: _bg,
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _green),
              )
            : Column(
                children: <Widget>[
                  // ── Header ──────────────────────────────────
                  _buildHeader(),

                  const SizedBox(height: 4),

                  // ── Tabs ────────────────────────────────────
                  _Tabs(
                    selectedIndex: _selectedTab,
                    onChanged: (int v) => setState(() => _selectedTab = v),
                  ),

                  const SizedBox(height: 12),

                  // ── List ────────────────────────────────────
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: _green,
                            backgroundColor: _card,
                            onRefresh: _load,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, int i) =>
                                  _NotificationCard(
                                item: items[i],
                                onTap: items[i].type == 'booking'
                                    ? () => _openRequests(items[i])
                                    : () => _markRead(items[i]),
                                onAccept: () =>
                                    _handleAction(items[i], true),
                                onReject: () =>
                                    _handleAction(items[i], false),
                                onOpenRequests: () =>
                                    _openRequests(items[i]),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _yellow,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    if (_unreadCount > 0) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _green.withOpacity(0.4)),
                        ),
                        child: Text(
                          '$_unreadCount unread',
                          style: const TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else
                      const Text(
                        'All caught up',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // refresh icon
          IconButton(
            onPressed: _load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0x99FFFFFF),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: _green,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Color(0x66FFFFFF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Card ────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
    required this.onOpenRequests,
    this.onBack,
  });

  final _OwnerNotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onOpenRequests;
  final VoidCallback? onBack;
  static const Color _green  = Color(0xFF08B36A);
  static const Color _red    = Color(0xFFE3220D);
  static const Color _dark   = Color(0xFF1C333B);
  static const Color _card   = Color(0xFF232823);
  static const Color _border = Color(0xFF2E342E);

  IconData get _icon {
    switch (item.type) {
      case 'booking':
        return Icons.bookmark_add_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'cancellation':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _accentColor {
    switch (item.type) {
      case 'booking':
        return _green;
      case 'payment':
        return const Color(0xFF52B8E0);
      case 'cancellation':
        return _red;
      default:
        return const Color(0xFFAAAAAA);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBooking = item.type == 'booking';
    final Color accent = _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: item.isRead ? _card : _card.withOpacity(0.98),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead ? _border : accent.withOpacity(0.4),
            width: item.isRead ? 1 : 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Top row ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // icon badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: accent, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: _green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.relativeTime,
                          style: const TextStyle(
                            color: Color(0x66FFFFFF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Message ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Text(
                item.message,
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),

            // ── Booking actions ──────────────────────────────
            if (isBooking) ...<Widget>[
              Divider(
                  height: 1,
                  color: accent.withOpacity(0.15)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _red,
                              side: const BorderSide(color: _red),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onAccept,
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: _dark,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: onOpenRequests,
                        icon: const Icon(Icons.open_in_new_rounded,
                            size: 18),
                        label: const Text('Open Requests'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0x99FFFFFF),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
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
  }
}

// ── Tabs ─────────────────────────────────────────────────────────

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const Color _green = Color(0xFF08B36A);
  static const Color _dark  = Color(0xFF1C333B);

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['All', 'Requests', 'Updates'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF232823),
          border: Border.all(color: const Color(0xFF2E342E)),
        ),
        child: Row(
          children: List<Widget>.generate(labels.length, (int index) {
            final bool active = selectedIndex == index;
            final bool isFirst = index == 0;
            final bool isLast = index == labels.length - 1;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: active ? _green : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? _dark : const Color(0x99FFFFFF),
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Model (unchanged) ─────────────────────────────────────────────

class _OwnerNotificationItem {
  const _OwnerNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.bookingId,
    required this.relativeTime,
    required this.isRead,
  });

  factory _OwnerNotificationItem.fromMap(Map<String, dynamic> map) {
    final String type =
        map['type']?.toString().trim().toLowerCase() ?? 'system';
    final String title =
        map['title']?.toString().trim().isNotEmpty == true
            ? map['title'].toString().trim()
            : (type == 'booking' ? 'Booking Request' : 'Notification');

    return _OwnerNotificationItem(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      title: title,
      message: map['message']?.toString().trim().isNotEmpty == true
          ? map['message'].toString().trim()
          : 'No details available.',
      type: type,
      bookingId: _extractBookingId(map),
      relativeTime: _relativeTime(map['createdAt']?.toString()),
      isRead: map['isRead'] == true,
    );
  }

  final String id;
  final String title;
  final String message;
  final String type;
  final String bookingId;
  final String relativeTime;
  final bool isRead;

  _OwnerNotificationItem copyWith({bool? isRead}) {
    return _OwnerNotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      bookingId: bookingId,
      relativeTime: relativeTime,
      isRead: isRead ?? this.isRead,
    );
  }

  static String _extractBookingId(Map<String, dynamic> map) {
    final dynamic metadata = map['metadata'];
    if (metadata is Map<String, dynamic>) {
      return metadata['bookingId']?.toString() ?? '';
    }
    if (metadata is Map) {
      return metadata['bookingId']?.toString() ?? '';
    }
    return '';
  }

  static String _relativeTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final DateTime? stamp = DateTime.tryParse(raw)?.toLocal();
    if (stamp == null) return '--';
    final Duration diff = DateTime.now().difference(stamp);
    if (diff.inMinutes < 60) {
      final int mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return '$mins min ago';
    }
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}