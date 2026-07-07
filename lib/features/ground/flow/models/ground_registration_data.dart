enum PitchType { cement, turf, matting, astroTurf }

enum UserRole { owner, player }

enum OfferType { cricketGround, academyCoaching, boxCricket, sportsNeo }

class AcademyFeePlan {
  AcademyFeePlan({required this.duration, required this.price});

  String duration;
  String price;
}

class DaySlotConfig {
  DaySlotConfig({
    required this.day,
    this.isEnabled = true,
    this.slotsPerDay = 3,
    this.startTime = '06:00 AM',
  });

  final String day;
  bool isEnabled;
  int slotsPerDay;
  String startTime;
}

class GroundRegistrationData {
  String ownerName = '';
  String contactNumber = '';
  String email = '';
  String address = '';
  String areaLocation = '';
  String landmark = '';

  bool otpVerified = false;
  UserRole role = UserRole.owner;
  OfferType? offerType;

  final List<String> groundImages = <String>[];

  PitchType pitchType = PitchType.cement;
  final Set<String> facilities = <String>{'Parking'};

  String state = 'Punjab';
  String city = 'Mohali';
  String groundName = 'Alexa Ground';
  String pinCode = '';
  final Set<String> selectedSports = <String>{'Cricket'};

  String academyBatchName = 'Morning Practice';
  String academyCoachName = 'Rahul Kumar';
  String academyPerBatchStudents = '40';
  String academyCategory = 'Beginner';
  final Set<String> academyRecurringDays = <String>{
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  };
  String academyStartTime = '06:00 AM';
  String academyEndTime = '08:00 AM';
  final List<AcademyFeePlan> academyFeePlans = <AcademyFeePlan>[
    AcademyFeePlan(duration: 'Monthly', price: '12000'),
    AcademyFeePlan(duration: '75 Days', price: '16000'),
  ];

  String ownershipProof = '';

  String openingTime = '06:00 AM';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  String slotSize = '3 hours';
  String gap = '30 Minutes';
  String matchType = 'T20';

  final List<DaySlotConfig> daySlots = <DaySlotConfig>[
    DaySlotConfig(day: 'Mon', slotsPerDay: 3),
    DaySlotConfig(day: 'Tue', slotsPerDay: 3),
    DaySlotConfig(day: 'Wed', slotsPerDay: 3),
    DaySlotConfig(day: 'Thu', isEnabled: false, slotsPerDay: 0),
    DaySlotConfig(day: 'Fri', slotsPerDay: 3),
    DaySlotConfig(day: 'Sat', slotsPerDay: 3),
    DaySlotConfig(day: 'Sun', slotsPerDay: 6),
  ];
}
