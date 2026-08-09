import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../bookings/bookings_turf_screen.dart';
import 'profile_turf_ui.dart';

class OwnerNotificationsTurfScreen extends StatefulWidget {
  const OwnerNotificationsTurfScreen({super.key});

  @override
  State<OwnerNotificationsTurfScreen> createState() =>
      _OwnerNotificationsTurfScreenState();
}

class _OwnerNotificationsTurfScreenState
    extends State<OwnerNotificationsTurfScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;

  bool _isLoading = true;
  int _selectedTab = 0;
  List<_OwnerNotificationItem> _items = <_OwnerNotificationItem>[];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _items = <_OwnerNotificationItem>[];
        _isLoading = false;
      });
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
        _items = <_OwnerNotificationItem>[];
        _isLoading = false;
      });
    }
  }

  List<_OwnerNotificationItem> get _filteredItems {
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
        _items = _items.map((_OwnerNotificationItem existing) {
          if (existing.id != item.id) {
            return existing;
          }
          return existing.copyWith(isRead: true);
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _openBookingRequests(_OwnerNotificationItem item) async {
    await _markRead(item);
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BookingsTurfScreen(initialTab: 'request'),
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
      await _loadNotifications();
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
    final List<_OwnerNotificationItem> visible = _filteredItems;

    return TurfPageScaffold(
      title: 'Notifications',
      subtitle: '$_unreadCount unread',
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            )
          : Column(
              children: <Widget>[
                _FilterTabs(
                  selectedIndex: _selectedTab,
                  onChanged: (int index) {
                    setState(() => _selectedTab = index);
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF00C9A7),
                          onRefresh: _loadNotifications,
                          child: ListView.builder(
                            itemCount: visible.length,
                            itemBuilder: (_, int index) {
                              final _OwnerNotificationItem item = visible[index];
                              final bool isBooking = item.type == 'booking';

                              return TurfCard(
                                child: InkWell(
                                  onTap: () => isBooking
                                      ? _openBookingRequests(item)
                                      : _markRead(item),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead)
                                              const Icon(
                                                Icons.brightness_1,
                                                size: 10,
                                                color: Color(0xFF00C9A7),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.relativeTime,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          item.message,
                                          style: const TextStyle(
                                            color: Colors.white,
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
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: Color(
                                                            0xFFE3220D,
                                                          ),
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF08B36A,
                                                            ),
                                                        foregroundColor:
                                                            const Color(
                                                              0xFF06271F,
                                                            ),
                                                      ),
                                                  child: const Text('Accept'),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          TextButton(
                                            onPressed: () =>
                                                _openBookingRequests(item),
                                            child: const Text('Open Requests'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['All', 'Requests', 'Updates'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x30FFFFFF)),
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (int index) {
          final bool selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF00C9A7)
                      : const Color(0x10FFFFFF),
                  borderRadius: index == 0
                      ? const BorderRadius.horizontal(left: Radius.circular(11))
                      : index == labels.length - 1
                      ? const BorderRadius.horizontal(right: Radius.circular(11))
                      : BorderRadius.zero,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selected ? const Color(0xFF06271F) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
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
