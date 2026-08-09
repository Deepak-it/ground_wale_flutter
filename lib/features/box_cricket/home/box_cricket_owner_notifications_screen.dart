import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'box_cricket_upcoming_bookings_screen.dart';

class BoxCricketOwnerNotificationsScreen extends StatefulWidget {
  const BoxCricketOwnerNotificationsScreen({super.key});

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
          _items = <_OwnerNotificationItem>[];
        });
      }
      return;
    }

    try {
      final List<Map<String, dynamic>> raw = await _api.listNotifications(ownerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = raw.map(_OwnerNotificationItem.fromMap).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      setState(() {
        _items = _items.map((existing) {
          if (existing.id != item.id) {
            return existing;
          }
          return existing.copyWith(isRead: true);
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _openRequests(_OwnerNotificationItem item) async {
    await _markRead(item);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BoxCricketUpcomingBookingsScreen(
          showBottomNav: false,
          initialTabIndex: 0,
        ),
      ),
    );
  }

  Future<void> _handleAction(_OwnerNotificationItem item, bool accept) async {
    if (item.bookingId.isEmpty) {
      return;
    }
    try {
      if (accept) {
        await _api.acceptBooking(item.bookingId);
      } else {
        await _api.rejectBooking(item.bookingId, reason: 'Not Available');
      }
      await _markRead(item);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Request accepted' : 'Request rejected')),
      );
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

  @override
  Widget build(BuildContext context) {
    final List<_OwnerNotificationItem> items = _visibleItems;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF08B36A)),
              )
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFDDF730),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Owner Notifications',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$_unreadCount unread',
                                style: const TextStyle(
                                  color: Color(0x99FFFFFF),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Tabs(
                    selectedIndex: _selectedTab,
                    onChanged: (int value) {
                      setState(() => _selectedTab = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF08B36A),
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: items.length,
                              itemBuilder: (_, int index) {
                                final _OwnerNotificationItem item = items[index];
                                final bool isBooking = item.type == 'booking';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0x0AFFFFFF),
                                    border: Border.all(color: const Color(0x1FFFFFFF)),
                                  ),
                                  child: InkWell(
                                    onTap: isBooking
                                        ? () => _openRequests(item)
                                        : () => _markRead(item),
                                    borderRadius: BorderRadius.circular(10),
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
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead)
                                              const Icon(
                                                Icons.brightness_1,
                                                size: 10,
                                                color: Color(0xFF08B36A),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.relativeTime,
                                          style: const TextStyle(
                                            color: Color(0x99FFFFFF),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          item.message,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            height: 1.35,
                                          ),
                                        ),
                                        if (isBooking) ...<Widget>[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () =>
                                                      _handleAction(item, false),
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(
                                                      color: Color(0xFFE3220D),
                                                    ),
                                                  ),
                                                  child: const Text('Reject'),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _handleAction(item, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF08B36A),
                                                    foregroundColor:
                                                        const Color(0xFF1C333B),
                                                  ),
                                                  child: const Text('Accept'),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton(
                                              onPressed: () => _openRequests(item),
                                              child: const Text('Open Requests'),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['All', 'Requests', 'Updates'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Row(
          children: List<Widget>.generate(labels.length, (int index) {
            final bool active = selectedIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF08B36A)
                        : const Color(0x0AFFFFFF),
                    borderRadius: index == 0
                        ? const BorderRadius.horizontal(left: Radius.circular(12))
                        : index == labels.length - 1
                        ? const BorderRadius.horizontal(right: Radius.circular(12))
                        : BorderRadius.zero,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? const Color(0xFF1C333B) : Colors.white,
                      fontWeight: FontWeight.w600,
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
    final String type = map['type']?.toString().trim().toLowerCase() ?? 'system';
    final String title = map['title']?.toString().trim().isNotEmpty == true
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
    if (raw == null || raw.isEmpty) {
      return '--';
    }
    final DateTime? stamp = DateTime.tryParse(raw)?.toLocal();
    if (stamp == null) {
      return '--';
    }
    final Duration diff = DateTime.now().difference(stamp);
    if (diff.inMinutes < 60) {
      final int mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return '$mins min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    }
    return '${diff.inDays} days ago';
  }
}
