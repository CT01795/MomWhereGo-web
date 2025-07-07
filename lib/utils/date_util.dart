import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatEventDateTime(var event, String type) {
  DateTime? date;

  if (type == "S" && event.startDate != null && event.startTime != null) {
    date = DateTime(event.startDate!.year, event.startDate!.month,
        event.startDate!.day, event.startTime!.hour, event.startTime!.minute);
  } else if (type == "S" && event.startDate != null) {
    date = DateTime(
        event.startDate!.year, event.startDate!.month, event.startDate!.day);
  } else if (type == "E" && event.endDate != null && event.endTime != null) {
    date = DateTime(event.endDate!.year, event.endDate!.month,
        event.endDate!.day, event.endTime!.hour, event.endTime!.minute);
    if (_isSameDay(event.startDate, event.endDate)) {
      return DateFormat('HH:mm').format(date);
    } else if (_isSameYear(event.startDate, event.endDate)) {
      return DateFormat('MM/dd HH:mm').format(date);
    }
  } else if (type == "E" && event.endDate != null) {
    date =
        DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day);
    if (_isSameDay(event.startDate, event.endDate)) {
      return '';
    } else if (_isSameYear(event.startDate, event.endDate)) {
      return DateFormat('MM/dd HH:mm').format(date);
    }
  } else if (type == "E" && event.endTime != null && event.startDate != null) {
    date = DateTime(event.startDate!.year, event.startDate!.month,
        event.startDate!.day, event.endTime!.hour, event.endTime!.minute);
    return DateFormat('HH:mm').format(date);
  }

  if (date == null) return '';
  return date.year == DateTime.now().year
      ? DateFormat('MM/dd HH:mm').format(date)
      : DateFormat('yyyy/MM/dd HH:mm').format(date);
}

bool _isSameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

bool _isSameYear(DateTime? a, DateTime? b) =>
    a != null && b != null && a.year == b.year;

int compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
  final aMinutes = a.hour * 60 + a.minute;
  final bMinutes = b.hour * 60 + b.minute;
  return aMinutes.compareTo(bMinutes);
}