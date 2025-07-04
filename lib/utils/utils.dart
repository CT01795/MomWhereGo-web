import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:uuid/uuid.dart';

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

Future<void> handleCheckboxChanged({
  required BuildContext context,
  required PreferenceService pref,
  required bool? value,
  required Event event,
  required Set<String> selectedEventIds,
  required void Function(void Function()) setState,
  required String isPlanned,
  required String addedMessage,
  required String duplicateMessage,
  required String confirmTitle,
}) async {
  if (value == true) {
    final existingEvents = await pref.getPrefEvents(isPlanned);

    final isAlreadyAdded = existingEvents.any((e) => e.id == event.id);

    /*if (isAlreadyAdded) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, duplicateMessage);
      return;
    }*/

    final shouldAdd = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
            '${isAlreadyAdded ? "$duplicateMessage，要重複新增嗎" : "新增$confirmTitle「${event.name}」"}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('新增', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldAdd != true) {
      return;
    }

    setState(() {
      selectedEventIds.add(event.id);
    });

    if (isAlreadyAdded) {
      //如果已經存在，處理 subEvents 和 startDate
      List<SubEventItem> sortedSubEvents = List.from(event.subEvents);

      //根據 startDate 排序 subEvents
      sortedSubEvents.sort((a, b) => a.startDate!.compareTo(b.startDate!));

      //移除所有 startDate <= event.startDate 的 subEvents
      sortedSubEvents.removeWhere((subEvent) =>
          subEvent.startDate != null &&
          !subEvent.startDate!.isAfter(event.startDate!));

      // 創建一個新的 Event 實例，並且使用新的 id 和更新後的 startDate
      Event updatedEvent = Event(
        id: Uuid().v4(), // 新的 id
        masterGraphUrl: event.masterGraphUrl,
        startDate: !event.startDate!.isAfter(DateTime.now().add(Duration(days: -1))) ? DateTime.now() : event.startDate, // 將 event.startDate 更新為今天
        endDate: event.endDate,
        startTime: event.startTime,
        endTime: event.endTime,
        city: event.city,
        location: event.location,
        name: event.name,
        type: event.type,
        description: event.description,
        fee: event.fee,
        unit: event.unit,
        subEvents: sortedSubEvents, // 更新後的 subEvents
        subGraphs: event.subGraphs,
      );
      await pref.savePrefEvent(isPlanned, updatedEvent);
      // ignore: use_build_context_synchronously
      showSnackBar(context, addedMessage);
      return;
    }

    if (!event.startDate!.isAfter(DateTime.now().add(Duration(days: -1)))) {
      // 創建一個新的 Event 實例，並且使用新的 id 和更新後的 startDate
      event.startDate = DateTime.now().add(Duration(days: -1));
    }
    await pref.savePrefEvent(isPlanned, event);
    // ignore: use_build_context_synchronously
    showSnackBar(context, addedMessage);
  } else {
    setState(() {
      selectedEventIds.remove(event.id);
    });
  }
}

/// 共用刪除事件函式
/// [context] BuildContext
/// [event] 要刪除的 Event
/// [onDelete] 刪除時執行的 async 函式（例如刪除資料庫或 Preference）
Future<void> handleRemoveEvent({
  required BuildContext context,
  required Event event,
  required Future<void> Function() onDelete,
  required VoidCallback onSuccessSetState,
  String dialogTitle = '活動',
}) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text('刪除$dialogTitle「${event.name}」？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('刪除', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (shouldDelete == true) {
    try {
      await onDelete();

      onSuccessSetState();

      // ignore: use_build_context_synchronously
      showSnackBar(context, '已刪除$dialogTitle：${event.name}');
    } catch (e) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, '刪除失敗: $e');
    }
  }
}

/// 過濾掉已過期的活動（根據 endDate 或 startDate）
List<Event> filterValidEvents(List<Event> events) {
  final day = DateTime.now().add(Duration(days: -1));
  final dayDate = DateTime(day.year, day.month, day.day);

  return events.where((event) {
    if (event.endDate != null) {
      return !event.endDate!.isBefore(dayDate);
    } else if (event.startDate != null) {
      return !event.startDate!.isBefore(dayDate);
    } else {
      return false; // 沒有日期就不顯示
    }
  }).toList();
}

List<SubEventItem> sortSubEvents(List<SubEventItem> list) {
  list.sort((a, b) {
    final aStart = a.startDate ?? DateTime(9999);
    final bStart = b.startDate ?? DateTime(9999);
    final cmpStartDate = aStart.compareTo(bStart);
    if (cmpStartDate != 0) return cmpStartDate;

    final aStartTime = a.startTime ?? const TimeOfDay(hour: 23, minute: 59);
    final bStartTime = b.startTime ?? const TimeOfDay(hour: 23, minute: 59);
    final cmpStartTime = _compareTimeOfDay(aStartTime, bStartTime);
    if (cmpStartTime != 0) return cmpStartTime;

    final aEnd = a.endDate ?? DateTime(9999);
    final bEnd = b.endDate ?? DateTime(9999);
    final cmpEndDate = aEnd.compareTo(bEnd);
    if (cmpEndDate != 0) return cmpEndDate;

    final aEndTime = a.endTime ?? const TimeOfDay(hour: 23, minute: 59);
    final bEndTime = b.endTime ?? const TimeOfDay(hour: 23, minute: 59);
    return _compareTimeOfDay(aEndTime, bEndTime);
  });
  return list;
}

int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
  final aMinutes = a.hour * 60 + a.minute;
  final bMinutes = b.hour * 60 + b.minute;
  return aMinutes.compareTo(bMinutes);
}

/// 顯示提示
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<String?> getAndroidID() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

  // Android ID
  return androidInfo
      .id; // This is the correct way to get the Android ID in the updated version
}
