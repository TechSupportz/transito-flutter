const Duration singaporeUtcOffset = Duration(hours: 8);

final RegExp _timeZoneSuffix = RegExp(r'(?:Z|[+-]\d{2}:\d{2})$', caseSensitive: false);

DateTime toSingaporeTime(DateTime time) => time.toUtc().add(singaporeUtcOffset);

DateTime? parseBusArrivalTime(String? arrivalTime) {
  if (arrivalTime == null || arrivalTime.isEmpty) {
    return null;
  }

  final String timestamp = _timeZoneSuffix.hasMatch(arrivalTime)
      ? arrivalTime
      : '$arrivalTime+08:00';
  return DateTime.tryParse(timestamp);
}

int? minutesUntilBusArrival(String? arrivalTime, {DateTime? now}) {
  final DateTime? arrival = parseBusArrivalTime(arrivalTime);
  if (arrival == null) {
    return null;
  }

  final Duration difference = arrival.difference(now ?? DateTime.now());
  return (difference.inSeconds / Duration.secondsPerMinute).floor();
}

String? formatBusArrivalTime(String? arrivalTime) {
  final DateTime? arrival = parseBusArrivalTime(arrivalTime);
  if (arrival == null) {
    return null;
  }

  final DateTime singaporeTime = toSingaporeTime(arrival);
  final String hour = singaporeTime.hour.toString().padLeft(2, '0');
  final String minute = singaporeTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
