String istGreetingMessage(String name, {DateTime? now}) {
  final DateTime istNow = (now ?? DateTime.now())
      .toUtc()
      .add(const Duration(hours: 5, minutes: 30));

  final int hour = istNow.hour;
  final String salutation;
  if (hour >= 5 && hour < 12) {
    salutation = 'Good Morning';
  } else if (hour >= 12 && hour < 17) {
    salutation = 'Good Afternoon';
  } else {
    salutation = 'Good Evening';
  }

  final String trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return salutation;
  }

  return '$salutation, $trimmedName';
}
