import 'package:flutter/material.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'sports_neo_booking_cart_screen.dart';
import 'sports_neo_reply_screen.dart';

class SportsNeoNotificationsScreen extends StatefulWidget {
  const SportsNeoNotificationsScreen({super.key});

  @override
  State<SportsNeoNotificationsScreen> createState() =>
      _SportsNeoNotificationsScreenState();
}

class _SportsNeoNotificationsScreenState
    extends State<SportsNeoNotificationsScreen> {
  final GroundWaleApi _api = GroundWaleApi.instance;
  int _selectedTab = 0;
  bool _isLoading = true;
  List<_SportsNeoNotificationItem> _notifications =
      <_SportsNeoNotificationItem>[];

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
      setState(() => _isLoading = false);
      return;
    }

    try {
      final List<Map<String, dynamic>> items = await _api.listNotifications(
        ownerId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = items
            .map(_SportsNeoNotificationItem.fromMap)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = _fallbackNotifications;
        _isLoading = false;
      });
    }
  }

  List<_SportsNeoNotificationItem> get _filteredNotifications {
    if (_selectedTab == 1) {
      return _notifications
          .where((item) => item.type == 'booking' || item.type == 'match')
          .toList();
    }
    if (_selectedTab == 2) {
      return _notifications.where((item) => item.type == 'payment').toList();
    }
    return _notifications;
  }

  int get _pendingCount =>
      _notifications.where((item) => !item.isRead).length;

  Future<void> _markRead(_SportsNeoNotificationItem item) async {
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
        _notifications = _notifications.map((existing) {
          if (existing.id != item.id) {
            return existing;
          }
          return existing.copyWith(isRead: true);
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _openReply(_SportsNeoNotificationItem item) async {
    await _markRead(item);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SportsNeoReplyScreen(
          title: item.title,
          time: item.relativeTime,
          message: item.message,
          isPayment: item.type == 'payment',
          amount: item.amount,
        ),
      ),
    );
  }

  Future<void> _openPayment(_SportsNeoNotificationItem item) async {
    await _markRead(item);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SportsNeoBookingCartScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_SportsNeoNotificationItem> items = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _SportsNeoTopHeader(
              title: 'Notifications',
              subtitle: '$_pendingCount Pending',
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _NotificationsTabBar(
                            selectedIndex: _selectedTab,
                            onChanged: (int index) {
                              setState(() => _selectedTab = index);
                            },
                          ),
                          const SizedBox(height: 24),
                          if (items.isEmpty)
                            const _EmptyStateCard(
                              title: 'No notifications yet',
                              subtitle: 'Updates about matches and payments will show here.',
                            )
                          else
                            ...items.map(
                              (_SportsNeoNotificationItem item) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _NotificationCard(
                                  item: item,
                                  onReply: () => _openReply(item),
                                  onPrimaryTap: () => _markRead(item),
                                  onPaymentTap: () => _openPayment(item),
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
    );
  }
}

class _SportsNeoTopHeader extends StatelessWidget {
  const _SportsNeoTopHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121C3E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
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

class _NotificationsTabBar extends StatelessWidget {
  const _NotificationsTabBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['All', 'Match', 'Payment'];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (int index) {
          final bool active = index == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Container(
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: <Color>[Color(0xFF1354E3), Color(0xFF5C8FFF)],
                        )
                      : null,
                  color: active ? null : const Color(0x0AFFFFFF),
                  borderRadius: index == 0
                      ? const BorderRadius.horizontal(left: Radius.circular(12))
                      : index == labels.length - 1
                      ? const BorderRadius.horizontal(right: Radius.circular(12))
                      : BorderRadius.zero,
                  border: index != labels.length - 1
                      ? const Border(
                          right: BorderSide(color: Color(0x1FFFFFFF)),
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onReply,
    required this.onPrimaryTap,
    required this.onPaymentTap,
  });

  final _SportsNeoNotificationItem item;
  final VoidCallback onReply;
  final VoidCallback onPrimaryTap;
  final VoidCallback onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final bool isPayment = item.type == 'payment';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0AFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  isPayment ? Icons.payments_outlined : Icons.sports_cricket,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.relativeTime,
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          if (item.amount != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              item.amount!,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              if (!isPayment) ...<Widget>[
                _StatusButton(
                  label: item.primaryLabel,
                  foreground: const Color(0xFF08B36A),
                  background: item.primaryFilled
                      ? const Color(0xFF08B36A)
                      : const Color(0x1408B36A),
                  border: const Color(0xFF08B36A),
                  textColor: item.primaryFilled
                      ? Colors.white
                      : const Color(0xFF08B36A),
                  onTap: onPrimaryTap,
                ),
                const SizedBox(width: 12),
                _StatusButton(
                  label: item.secondaryLabel,
                  foreground: const Color(0xFFE3220D),
                  background: const Color(0x14E3220D),
                  border: const Color(0xFFE3220D),
                  textColor: const Color(0xFFE3220D),
                  onTap: onPrimaryTap,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: InkWell(
                  onTap: isPayment ? onPaymentTap : onReply,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: isPayment ? 42 : 38,
                    decoration: BoxDecoration(
                      color: isPayment ? const Color(0xFF2563EB) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPayment
                            ? const Color(0xFF2563EB)
                            : const Color(0x3DFFFFFF),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isPayment ? 'Pay Now' : 'Reply',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0AFFFFFF),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SportsNeoNotificationItem {
  const _SportsNeoNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.relativeTime,
    required this.isRead,
    required this.primaryLabel,
    required this.primaryFilled,
    required this.secondaryLabel,
    this.amount,
  });

  factory _SportsNeoNotificationItem.fromMap(Map<String, dynamic> map) {
    final String type = map['type']?.toString().trim().toLowerCase() ?? 'system';
    final String title = map['title']?.toString().trim().isNotEmpty == true
        ? map['title'].toString().trim()
        : type == 'payment'
        ? 'Payment Request'
        : 'Match Invitation';

    return _SportsNeoNotificationItem(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      title: title,
      message: map['message']?.toString().trim().isNotEmpty == true
          ? map['message'].toString().trim()
          : 'No details provided.',
      type: type,
      relativeTime: _relativeTime(map['createdAt']?.toString()),
      isRead: map['isRead'] == true,
      amount: _extractAmount(map['message']?.toString() ?? ''),
      primaryLabel: type == 'payment' ? 'Available' : 'Available',
      primaryFilled: false,
      secondaryLabel: type == 'payment' ? 'Not available' : 'Not available',
    );
  }

  final String id;
  final String title;
  final String message;
  final String type;
  final String relativeTime;
  final bool isRead;
  final String primaryLabel;
  final bool primaryFilled;
  final String secondaryLabel;
  final String? amount;

  _SportsNeoNotificationItem copyWith({bool? isRead}) {
    return _SportsNeoNotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      relativeTime: relativeTime,
      isRead: isRead ?? this.isRead,
      primaryLabel: primaryLabel,
      primaryFilled: primaryFilled,
      secondaryLabel: secondaryLabel,
      amount: amount,
    );
  }

  static String _relativeTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '2 hours ago';
    }
    final DateTime? timestamp = DateTime.tryParse(raw)?.toLocal();
    if (timestamp == null) {
      return '2 hours ago';
    }
    final Duration diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      final int mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return '$mins min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    }
    return '${diff.inDays} days ago';
  }

  static String? _extractAmount(String text) {
    final RegExpMatch? match = RegExp(r'₹\s*([0-9]+(?:\.[0-9]+)?)').firstMatch(text);
    if (match == null) {
      return null;
    }
    return '₹${match.group(1)}';
  }
}

const List<_SportsNeoNotificationItem> _fallbackNotifications =
    <_SportsNeoNotificationItem>[
  _SportsNeoNotificationItem(
    id: '',
    title: 'Match Invitation',
    message:
        'Thunderbolts XI VS Manu Xi\nSector 118, Mohali (1.8 km)\nApr 8, 6:00 AM - 8:00 AM\nWhite Ball\nOne team one dress code',
    type: 'booking',
    relativeTime: '2 hours ago',
    isRead: false,
    primaryLabel: 'Available',
    primaryFilled: true,
    secondaryLabel: 'Not available',
  ),
  _SportsNeoNotificationItem(
    id: '',
    title: 'Payment Request',
    message: 'Split Payment for victory cricket stadium',
    type: 'payment',
    relativeTime: '1 hours ago',
    isRead: false,
    primaryLabel: 'Available',
    primaryFilled: false,
    secondaryLabel: 'Not available',
    amount: '₹350',
  ),
];