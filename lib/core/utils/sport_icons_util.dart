import 'package:flutter/material.dart';

String sportIcon(String sport) {
  final String normalized = sport
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[-_]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  switch (normalized) {
    case 'archery':
      return '🎯';

    case 'arm wrestling':
      return '💪';

    case 'badminton':
      return '🏸';

    case 'baseball':
      return '⚾';

    case 'basketball':
      return '🏀';

    case 'billiards & snooker':
    case 'billiards':
    case 'snooker':
      return '🎱';

    case 'bodybuilding':
      return '🏋️';

    case 'box cricket':
      return '🏏';

    case 'boxing':
      return '🥊';

    case 'chess':
      return '♟️';

    case 'cricket':
      return '🏏';

    case 'cycling':
      return '🚴';

    case 'football':
      return '⚽';

    case 'futsal':
      return '⚽';

    case 'golf':
      return '⛳';

    case 'gymnastics':
      return '🤸';

    case 'hockey':
      return '🏑';

    case 'ice hockey':
      return '🏒';

    case 'kabaddi':
      return '🤼';

    case 'karate':
      return '🥋';

    case 'kho kho':
      return '🏃';

    case 'lawn tennis':
      return '🎾';

    case 'swimming':
      return '🏊';

    case 'table tennis':
      return '🏓';

    case 'taekwondo':
      return '🥋';

    case 'tennis':
      return '🎾';

    case 'volleyball':
      return '🏐';

    case 'wrestling':
      return '🤼';

    default:
      return '🏅';
  }
}