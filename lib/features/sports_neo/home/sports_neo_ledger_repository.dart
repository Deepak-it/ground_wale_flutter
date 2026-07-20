import 'package:flutter/foundation.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

const bool kUseSportsNeoLedgerMock = true;

class SportsNeoLedgerHomeData {
  const SportsNeoLedgerHomeData({
    required this.title,
    required this.netBalance,
    required this.netPositive,
    required this.addReceiptLabel,
    required this.addPaymentLabel,
    required this.entries,
  });

  final String title;
  final int netBalance;
  final bool netPositive;
  final String addReceiptLabel;
  final String addPaymentLabel;
  final List<SportsNeoLedgerEntry> entries;
}

class SportsNeoMatchLedgerData {
  const SportsNeoMatchLedgerData({
    required this.matchTitle,
    required this.netBalance,
    required this.netPositive,
    required this.bookingTitle,
    required this.bookingGround,
    required this.bookingDate,
    required this.bookingTime,
    required this.matchAmount,
    required this.paymentLines,
    required this.transactions,
  });

  final String matchTitle;
  final int netBalance;
  final bool netPositive;
  final String bookingTitle;
  final String bookingGround;
  final String bookingDate;
  final String bookingTime;
  final int matchAmount;
  final List<SportsNeoSummaryLine> paymentLines;
  final List<SportsNeoLedgerEntry> transactions;
}

class SportsNeoSummaryLine {
  const SportsNeoSummaryLine({required this.label, required this.amount});

  final String label;
  final int amount;
}

class SportsNeoLedgerEntry {
  const SportsNeoLedgerEntry({
    required this.id,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    this.phone = '',
    this.status = '',
    this.hasWhatsapp = false,
  });

  final String id;
  final int index;
  final String title;
  final String subtitle;
  final int amount;
  final bool isCredit;
  final String phone;
  final String status;
  final bool hasWhatsapp;
}

class SportsNeoAddMoneyPayload {
  const SportsNeoAddMoneyPayload({
    required this.amount,
    required this.playerId,
    required this.note,
    required this.method,
    required this.kind,
  });

  final int amount;
  final String playerId;
  final String note;
  final String method;
  final String kind;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'amount': amount,
      'playerId': playerId,
      'note': note,
      'method': method,
      'kind': kind,
    };
  }
}

abstract class SportsNeoLedgerRepository {
  Future<SportsNeoLedgerHomeData> loadLedgerHome(String groundId);

  Future<SportsNeoMatchLedgerData> loadMatchLedger(String groundId, String matchId);

  Future<SportsNeoLedgerHomeData> loadPendingLedger(String groundId);

  Future<SportsNeoLedgerHomeData> loadAdvanceLedger(String groundId);

  Future<SportsNeoMatchLedgerData> loadSarpanchLedger(String groundId);

  Future<void> addMoney(String groundId, SportsNeoAddMoneyPayload payload);

  Future<void> replacePlayer(String groundId, String fromPlayerId, String toPlayerId, String handlingType);

  Future<void> sendPendingReminder(String groundId);

  Future<void> sendAdvanceUpdate(String groundId);

  static SportsNeoLedgerRepository create() {
    if (kUseSportsNeoLedgerMock) {
      return _MockSportsNeoLedgerRepository();
    }
    return _ApiSportsNeoLedgerRepository();
  }
}

class _ApiSportsNeoLedgerRepository implements SportsNeoLedgerRepository {
  final GroundWaleApi _api = GroundWaleApi.instance;

  @override
  Future<void> addMoney(String groundId, SportsNeoAddMoneyPayload payload) async {
    await _api.sportsNeoAddLedgerMoney(groundId, payload.toJson());
  }

  @override
  Future<SportsNeoLedgerHomeData> loadAdvanceLedger(String groundId) async {
    final Map<String, dynamic> json = await _api.sportsNeoGetAdvanceLedger(groundId);
    return _decodeHome(json, fallbackTitle: 'Advance Payment');
  }

  @override
  Future<SportsNeoLedgerHomeData> loadLedgerHome(String groundId) async {
    final Map<String, dynamic> json = await _api.sportsNeoGetLedgerHome(groundId);
    return _decodeHome(json, fallbackTitle: 'Ledger & Payment');
  }

  @override
  Future<SportsNeoMatchLedgerData> loadMatchLedger(String groundId, String matchId) async {
    final Map<String, dynamic> json = await _api.sportsNeoGetMatchLedger(groundId, matchId);
    return _decodeMatch(json, fallbackTitle: 'Match');
  }

  @override
  Future<SportsNeoLedgerHomeData> loadPendingLedger(String groundId) async {
    final Map<String, dynamic> json = await _api.sportsNeoGetPendingLedger(groundId);
    return _decodeHome(json, fallbackTitle: 'Pending Payment');
  }

  @override
  Future<SportsNeoMatchLedgerData> loadSarpanchLedger(String groundId) async {
    final Map<String, dynamic> json = await _api.sportsNeoGetSarpanchLedger(groundId);
    return _decodeMatch(json, fallbackTitle: 'Sarpanch');
  }

  @override
  Future<void> replacePlayer(String groundId, String fromPlayerId, String toPlayerId, String handlingType) async {
    await _api.sportsNeoReplaceLedgerPlayer(
      groundId,
      <String, dynamic>{
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'handlingType': handlingType,
      },
    );
  }

  @override
  Future<void> sendAdvanceUpdate(String groundId) async {
    await _api.sportsNeoSendAdvanceUpdate(groundId);
  }

  @override
  Future<void> sendPendingReminder(String groundId) async {
    await _api.sportsNeoSendPendingReminder(groundId);
  }

  SportsNeoLedgerHomeData _decodeHome(Map<String, dynamic> json, {required String fallbackTitle}) {
    final List<SportsNeoLedgerEntry> entries = (json['entries'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .map(_decodeEntry)
        .toList();

    return SportsNeoLedgerHomeData(
      title: (json['title']?.toString() ?? fallbackTitle),
      netBalance: (json['netBalance'] as num?)?.round() ?? 0,
      netPositive: json['netPositive'] != false,
      addReceiptLabel: (json['addReceiptLabel']?.toString() ?? 'Add Receipt'),
      addPaymentLabel: (json['addPaymentLabel']?.toString() ?? 'Add Payment'),
      entries: entries,
    );
  }

  SportsNeoMatchLedgerData _decodeMatch(Map<String, dynamic> json, {required String fallbackTitle}) {
    final List<SportsNeoSummaryLine> lines = (json['paymentLines'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .map(
          (Map<String, dynamic> item) => SportsNeoSummaryLine(
            label: item['label']?.toString() ?? 'Line',
            amount: (item['amount'] as num?)?.round() ?? 0,
          ),
        )
        .toList();

    final List<SportsNeoLedgerEntry> tx = (json['transactions'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .map(_decodeEntry)
        .toList();

    return SportsNeoMatchLedgerData(
      matchTitle: json['matchTitle']?.toString() ?? fallbackTitle,
      netBalance: (json['netBalance'] as num?)?.round() ?? 0,
      netPositive: json['netPositive'] != false,
      bookingTitle: json['bookingTitle']?.toString() ?? 'Booking Details',
      bookingGround: json['bookingGround']?.toString() ?? 'Ground',
      bookingDate: json['bookingDate']?.toString() ?? '--',
      bookingTime: json['bookingTime']?.toString() ?? '--',
      matchAmount: (json['matchAmount'] as num?)?.round() ?? 0,
      paymentLines: lines,
      transactions: tx,
    );
  }

  SportsNeoLedgerEntry _decodeEntry(Map<String, dynamic> item) {
    return SportsNeoLedgerEntry(
      id: item['id']?.toString() ?? '',
      index: (item['index'] as num?)?.toInt() ?? 1,
      title: item['title']?.toString() ?? 'Entry',
      subtitle: item['subtitle']?.toString() ?? '',
      amount: (item['amount'] as num?)?.round() ?? 0,
      isCredit: item['isCredit'] == true,
      phone: item['phone']?.toString() ?? '',
      status: item['status']?.toString() ?? '',
      hasWhatsapp: item['hasWhatsapp'] == true,
    );
  }
}

class _MockSportsNeoLedgerRepository implements SportsNeoLedgerRepository {
  const _MockSportsNeoLedgerRepository();

  @override
  Future<void> addMoney(String groundId, SportsNeoAddMoneyPayload payload) async {
    debugPrint('Mock addMoney for $groundId -> ${payload.toJson()}');
  }

  @override
  Future<SportsNeoLedgerHomeData> loadAdvanceLedger(String groundId) async {
    return SportsNeoLedgerHomeData(
      title: 'Advance Payment',
      netBalance: 3500,
      netPositive: true,
      addReceiptLabel: 'Share',
      addPaymentLabel: 'WhatsApp',
      entries: _mockPlayers().map((SportsNeoLedgerEntry e) => SportsNeoLedgerEntry(
            id: e.id,
            index: e.index,
            title: e.title,
            subtitle: e.phone,
            amount: 500,
            isCredit: true,
            phone: e.phone,
            hasWhatsapp: true,
          )).toList(),
    );
  }

  @override
  Future<SportsNeoLedgerHomeData> loadLedgerHome(String groundId) async {
    return SportsNeoLedgerHomeData(
      title: 'Ledger & Payment',
      netBalance: -3,
      netPositive: false,
      addReceiptLabel: 'Add Receipt',
      addPaymentLabel: 'Add Payment',
      entries: <SportsNeoLedgerEntry>[
        const SportsNeoLedgerEntry(
          id: 'captain',
          index: 1,
          title: 'Rakesh Sharma (Captain)',
          subtitle: 'Settled',
          amount: 5150,
          isCredit: true,
        ),
        const SportsNeoLedgerEntry(
          id: 'team',
          index: 2,
          title: 'Manu XI (Opponent Team)',
          subtitle: 'Rahul Singh (Captain)',
          amount: 2575,
          isCredit: false,
        ),
        const SportsNeoLedgerEntry(
          id: 'sarpanch',
          index: 3,
          title: 'Sarpanch',
          subtitle: 'Advance 750',
          amount: 250,
          isCredit: false,
        ),
        const SportsNeoLedgerEntry(
          id: 'gagi',
          index: 4,
          title: 'Gagi Jassal',
          subtitle: 'Total Pending 300',
          amount: 250,
          isCredit: false,
        ),
      ],
    );
  }

  @override
  Future<SportsNeoMatchLedgerData> loadMatchLedger(String groundId, String matchId) async {
    return SportsNeoMatchLedgerData(
      matchTitle: 'Manu Xi vs Thunderbolt XI',
      netBalance: -3,
      netPositive: false,
      bookingTitle: 'Booking Details',
      bookingGround: 'Green Valley Cricket Ground',
      bookingDate: 'Wednesday, Apr 8, 2026',
      bookingTime: '6:00 AM - 8:00 AM',
      matchAmount: 5000,
      paymentLines: const <SportsNeoSummaryLine>[
        SportsNeoSummaryLine(label: 'Ground Fee', amount: 5000),
        SportsNeoSummaryLine(label: 'Red ball (1)', amount: 150),
        SportsNeoSummaryLine(label: 'Discount', amount: 0),
      ],
      transactions: <SportsNeoLedgerEntry>[
        const SportsNeoLedgerEntry(
          id: 'captain',
          index: 1,
          title: 'Rakesh Sharma (Captain)',
          subtitle: '',
          amount: 5150,
          isCredit: true,
        ),
        const SportsNeoLedgerEntry(
          id: 'opponent',
          index: 2,
          title: 'Manu XI',
          subtitle: 'Settled',
          amount: 2575,
          isCredit: false,
        ),
        const SportsNeoLedgerEntry(
          id: 'sarpanch',
          index: 3,
          title: 'Sarpanch',
          subtitle: 'Advance 750',
          amount: 250,
          isCredit: false,
        ),
      ],
    );
  }

  @override
  Future<SportsNeoLedgerHomeData> loadPendingLedger(String groundId) async {
    return SportsNeoLedgerHomeData(
      title: 'Pending Payment',
      netBalance: 3500,
      netPositive: false,
      addReceiptLabel: 'Share',
      addPaymentLabel: 'WhatsApp',
      entries: _mockPlayers().map((SportsNeoLedgerEntry e) => SportsNeoLedgerEntry(
            id: e.id,
            index: e.index,
            title: e.title,
            subtitle: e.phone,
            amount: 500,
            isCredit: false,
            phone: e.phone,
            hasWhatsapp: true,
          )).toList(),
    );
  }

  @override
  Future<SportsNeoMatchLedgerData> loadSarpanchLedger(String groundId) async {
    return SportsNeoMatchLedgerData(
      matchTitle: 'Sarpanch',
      netBalance: 2900,
      netPositive: true,
      bookingTitle: 'Transaction History',
      bookingGround: 'Sector 22 Turf',
      bookingDate: '30-12-2026',
      bookingTime: '6:00 AM - 8:00 AM',
      matchAmount: 100,
      paymentLines: const <SportsNeoSummaryLine>[
        SportsNeoSummaryLine(label: 'Total Paid', amount: 700),
        SportsNeoSummaryLine(label: 'Total Expense', amount: 200),
        SportsNeoSummaryLine(label: 'Matches Played', amount: 5),
      ],
      transactions: const <SportsNeoLedgerEntry>[
        SportsNeoLedgerEntry(
          id: 'fee',
          index: 1,
          title: 'Match Fee vs Manu XI',
          subtitle: '30-12-2026',
          amount: 100,
          isCredit: false,
        ),
        SportsNeoLedgerEntry(
          id: 'added1',
          index: 2,
          title: 'Amount Added',
          subtitle: 'UPI',
          amount: 1000,
          isCredit: true,
        ),
        SportsNeoLedgerEntry(
          id: 'dues',
          index: 3,
          title: 'Dues Added',
          subtitle: '01-12-2026',
          amount: 500,
          isCredit: false,
        ),
      ],
    );
  }

  @override
  Future<void> replacePlayer(String groundId, String fromPlayerId, String toPlayerId, String handlingType) async {
    debugPrint('Mock replacePlayer $fromPlayerId -> $toPlayerId ($handlingType)');
  }

  @override
  Future<void> sendAdvanceUpdate(String groundId) async {
    debugPrint('Mock sendAdvanceUpdate $groundId');
  }

  @override
  Future<void> sendPendingReminder(String groundId) async {
    debugPrint('Mock sendPendingReminder $groundId');
  }

  List<SportsNeoLedgerEntry> _mockPlayers() {
    return const <SportsNeoLedgerEntry>[
      SportsNeoLedgerEntry(
        id: '1',
        index: 1,
        title: 'Rakesh Sharma (Captain)',
        subtitle: '',
        amount: 500,
        isCredit: false,
        phone: '+91 9876543210',
        hasWhatsapp: true,
      ),
      SportsNeoLedgerEntry(
        id: '2',
        index: 2,
        title: 'Lekhi Raja',
        subtitle: '',
        amount: 500,
        isCredit: false,
        phone: '+91 9876543210',
        hasWhatsapp: true,
      ),
      SportsNeoLedgerEntry(
        id: '3',
        index: 3,
        title: 'Pritam Sarpanch',
        subtitle: '',
        amount: 500,
        isCredit: false,
        phone: '+91 9876543210',
        hasWhatsapp: true,
      ),
      SportsNeoLedgerEntry(
        id: '4',
        index: 4,
        title: 'Manu XI',
        subtitle: '',
        amount: 500,
        isCredit: false,
        phone: '+91 9876543210',
        hasWhatsapp: true,
      ),
    ];
  }
}

Future<String?> resolveGroundIdForLedger() async {
  if (kUseSportsNeoLedgerMock) {
    final String? currentMockGroundId = ApiSession.instance.groundId;
    if (currentMockGroundId != null && currentMockGroundId.isNotEmpty) {
      return currentMockGroundId;
    }

    const String mockGroundId = 'sports-neo-mock-ground';
    ApiSession.instance.setGroundId(mockGroundId);
    return mockGroundId;
  }

  final String? currentGroundId = ApiSession.instance.groundId;
  if (currentGroundId != null && currentGroundId.isNotEmpty) {
    return currentGroundId;
  }

  final String? ownerId = ApiSession.instance.ownerId;
  if (ownerId == null || ownerId.isEmpty) {
    return null;
  }

  final String? resolved = await GroundWaleApi.instance.ensureGroundIdForOwner(ownerId);
  if (resolved != null && resolved.isNotEmpty) {
    ApiSession.instance.setGroundId(resolved);
  }
  return resolved;
}
