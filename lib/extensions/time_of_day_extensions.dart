import 'package:flutter/material.dart';

extension TimeOfDayExtension on TimeOfDay {
  String formatTimeString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

extension StringTimeOfDay on String {
  TimeOfDay parseToTimeOfDay() {
    final parts = split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
