import 'package:flutter/foundation.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class SportsNeoBookingCartSlot {
  const SportsNeoBookingCartSlot({
    required this.slotId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.amount,
  });

  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  final int amount;

  String get key => '$slotId|$date';
}

class SportsNeoBookingCartGround {
  const SportsNeoBookingCartGround({
    required this.groundId,
    required this.groundName,
    required this.location,
    required this.facilities,
    required this.slots,
  });

  final String groundId;
  final String groundName;
  final String location;
  final List<String> facilities;
  final List<SportsNeoBookingCartSlot> slots;

  int get totalAmount =>
      slots.fold<int>(0, (int sum, SportsNeoBookingCartSlot slot) {
        return sum + slot.amount;
      });

  SportsNeoBookingCartGround copyWith({
    String? groundId,
    String? groundName,
    String? location,
    List<String>? facilities,
    List<SportsNeoBookingCartSlot>? slots,
  }) {
    return SportsNeoBookingCartGround(
      groundId: groundId ?? this.groundId,
      groundName: groundName ?? this.groundName,
      location: location ?? this.location,
      facilities: facilities ?? this.facilities,
      slots: slots ?? this.slots,
    );
  }
}

class SportsNeoBookingCartStore {
  SportsNeoBookingCartStore._();

  static final SportsNeoBookingCartStore instance =
      SportsNeoBookingCartStore._();

  final GroundWaleApi _api = GroundWaleApi.instance;

  final ValueNotifier<List<SportsNeoBookingCartGround>> notifier =
      ValueNotifier<List<SportsNeoBookingCartGround>>(
        const <SportsNeoBookingCartGround>[],
      );

  List<SportsNeoBookingCartGround> get items => notifier.value;

  int get totalSlots =>
      items.fold<int>(0, (int sum, SportsNeoBookingCartGround item) {
        return sum + item.slots.length;
      });

  int get totalAmount =>
      items.fold<int>(0, (int sum, SportsNeoBookingCartGround item) {
        return sum + item.totalAmount;
      });

  Future<void> refreshFromServer() async {
    final String ownerId = (ApiSession.instance.ownerId ?? '').trim();
    if (ownerId.isEmpty) {
      notifier.value = const <SportsNeoBookingCartGround>[];
      return;
    }

    final Map<String, dynamic> response = await _api.getBookingCart(ownerId);
    notifier.value = _mapItemsFromApi(response['items']);
  }

  Future<void> addSlots({
    required String groundId,
    required String groundName,
    required String location,
    required List<String> facilities,
    required List<SportsNeoBookingCartSlot> slots,
  }) async {
    if (groundId.trim().isEmpty || slots.isEmpty) {
      return;
    }

    final String ownerId = (ApiSession.instance.ownerId ?? '').trim();
    if (ownerId.isEmpty) {
      return;
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'groundId': groundId,
      'groundName': groundName,
      'location': location,
      'facilities': facilities,
      'slots': slots
          .map(
            (SportsNeoBookingCartSlot slot) => <String, dynamic>{
              'slotId': slot.slotId,
              'date': slot.date,
              'startTime': slot.startTime,
              'endTime': slot.endTime,
              'amount': slot.amount,
            },
          )
          .toList(),
    };

    final Map<String, dynamic> response = await _api.addBookingCartSlots(
      ownerId,
      payload,
    );
    notifier.value = _mapItemsFromApi(response['items']);
  }

  Future<void> removeGround(String groundId) async {
    final String ownerId = (ApiSession.instance.ownerId ?? '').trim();
    if (ownerId.isEmpty || groundId.trim().isEmpty) {
      return;
    }

    final Map<String, dynamic> response = await _api.removeBookingCartGround(
      ownerId,
      groundId,
    );
    notifier.value = _mapItemsFromApi(response['items']);
  }

  Future<void> removeSlot(String groundId, String slotKey) async {
    final String ownerId = (ApiSession.instance.ownerId ?? '').trim();
    if (ownerId.isEmpty || groundId.trim().isEmpty || slotKey.trim().isEmpty) {
      return;
    }

    final Map<String, dynamic> response = await _api.removeBookingCartSlot(
      ownerId,
      groundId,
      Uri.encodeComponent(slotKey),
    );
    notifier.value = _mapItemsFromApi(response['items']);
  }

  Future<void> clear() async {
    final String ownerId = (ApiSession.instance.ownerId ?? '').trim();
    if (ownerId.isEmpty) {
      notifier.value = const <SportsNeoBookingCartGround>[];
      return;
    }

    final Map<String, dynamic> response = await _api.clearBookingCart(ownerId);
    notifier.value = _mapItemsFromApi(response['items']);
  }

  static List<SportsNeoBookingCartGround> _mapItemsFromApi(dynamic rawItems) {
    if (rawItems is! List) {
      return const <SportsNeoBookingCartGround>[];
    }

    return rawItems
        .whereType<Map>()
        .map((Map item) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item);
          final List<SportsNeoBookingCartSlot> slots = _mapSlotsFromApi(
            map['slots'],
          );

          return SportsNeoBookingCartGround(
            groundId: map['groundId']?.toString() ?? '',
            groundName: map['groundName']?.toString() ?? 'Ground',
            location: map['location']?.toString() ?? '',
            facilities: _mapFacilitiesFromApi(map['facilities']),
            slots: slots,
          );
        })
        .where((SportsNeoBookingCartGround ground) {
          return ground.groundId.trim().isNotEmpty && ground.slots.isNotEmpty;
        })
        .toList();
  }

  static List<SportsNeoBookingCartSlot> _mapSlotsFromApi(dynamic rawSlots) {
    if (rawSlots is! List) {
      return const <SportsNeoBookingCartSlot>[];
    }

    final List<SportsNeoBookingCartSlot> slots = rawSlots
        .whereType<Map>()
        .map((Map item) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item);
          final dynamic amountValue = map['amount'];
          final int amount = amountValue is num
              ? amountValue.toInt()
              : int.tryParse(amountValue?.toString() ?? '') ?? 0;

          return SportsNeoBookingCartSlot(
            slotId: map['slotId']?.toString() ?? '',
            date: map['date']?.toString() ?? '',
            startTime: map['startTime']?.toString() ?? '',
            endTime: map['endTime']?.toString() ?? '',
            amount: amount,
          );
        })
        .where((SportsNeoBookingCartSlot slot) {
          return slot.slotId.trim().isNotEmpty && slot.date.trim().isNotEmpty;
        })
        .toList();

    return _dedupeSlots(slots);
  }

  static List<String> _mapFacilitiesFromApi(dynamic rawFacilities) {
    if (rawFacilities is! List) {
      return const <String>[];
    }

    return rawFacilities
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  static List<SportsNeoBookingCartSlot> _dedupeSlots(
    List<SportsNeoBookingCartSlot> slots,
  ) {
    final Map<String, SportsNeoBookingCartSlot> unique =
        <String, SportsNeoBookingCartSlot>{};

    for (final SportsNeoBookingCartSlot slot in slots) {
      unique[slot.key] = slot;
    }

    return unique.values.toList();
  }
}
