import 'package:flutter/foundation.dart';

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

  void addSlots({
    required String groundId,
    required String groundName,
    required String location,
    required List<String> facilities,
    required List<SportsNeoBookingCartSlot> slots,
  }) {
    if (groundId.trim().isEmpty || slots.isEmpty) {
      return;
    }

    final List<SportsNeoBookingCartGround> next =
        List<SportsNeoBookingCartGround>.from(items);
    final int existingIndex = next.indexWhere(
      (SportsNeoBookingCartGround item) => item.groundId == groundId,
    );

    if (existingIndex == -1) {
      notifier.value = <SportsNeoBookingCartGround>[
        ...next,
        SportsNeoBookingCartGround(
          groundId: groundId,
          groundName: groundName,
          location: location,
          facilities: facilities,
          slots: _dedupeSlots(slots),
        ),
      ];
      return;
    }

    final SportsNeoBookingCartGround existing = next[existingIndex];
    final List<SportsNeoBookingCartSlot> merged = _dedupeSlots(
      <SportsNeoBookingCartSlot>[...existing.slots, ...slots],
    );

    next[existingIndex] = existing.copyWith(
      groundName: groundName,
      location: location,
      facilities: facilities,
      slots: merged,
    );
    notifier.value = next;
  }

  void removeGround(String groundId) {
    notifier.value = items
        .where((SportsNeoBookingCartGround item) => item.groundId != groundId)
        .toList();
  }

  void removeSlot(String groundId, String slotKey) {
    final List<SportsNeoBookingCartGround> next =
        <SportsNeoBookingCartGround>[];

    for (final SportsNeoBookingCartGround item in items) {
      if (item.groundId != groundId) {
        next.add(item);
        continue;
      }

      final List<SportsNeoBookingCartSlot> slots = item.slots
          .where((SportsNeoBookingCartSlot slot) => slot.key != slotKey)
          .toList();

      if (slots.isNotEmpty) {
        next.add(item.copyWith(slots: slots));
      }
    }

    notifier.value = next;
  }

  void clear() {
    notifier.value = const <SportsNeoBookingCartGround>[];
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
