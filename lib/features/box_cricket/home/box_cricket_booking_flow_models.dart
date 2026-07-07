class BoxCricketBookingDraft {
  const BoxCricketBookingDraft({
    required this.slotId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.amount,
    this.teamName = '',
    this.captainName = '',
    this.captainPhone = '',
    this.playerCount = 0,
    this.paymentMethod = 'upi',
    this.notes = '',
  });

  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  final int amount;
  final String teamName;
  final String captainName;
  final String captainPhone;
  final int playerCount;
  final String paymentMethod;
  final String notes;

  BoxCricketBookingDraft copyWith({
    String? teamName,
    String? captainName,
    String? captainPhone,
    int? playerCount,
    String? paymentMethod,
    String? notes,
  }) {
    return BoxCricketBookingDraft(
      slotId: slotId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      amount: amount,
      teamName: teamName ?? this.teamName,
      captainName: captainName ?? this.captainName,
      captainPhone: captainPhone ?? this.captainPhone,
      playerCount: playerCount ?? this.playerCount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'slotId': slotId,
      'teamName': teamName,
      'captainName': captainName,
      'captainPhone': captainPhone,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'playerCount': playerCount,
    };
  }
}
