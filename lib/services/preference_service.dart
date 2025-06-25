import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mom_where_go/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class PreferenceService {
  static const String _plannedKey = 'planned_events';
  static const String _historyKey = 'history_events';

  // ------------------- 儲存單筆活動 -------------------
  Future<void> savePrefEvent(String isPlanned, Event event) async {
    final events = await getPrefEvents(isPlanned);
    _replaceOrAdd(events, event);
    await _saveEvents(isPlanned, events);
  }

  // ------------------- 儲存整體清單 -------------------
  Future<void> savePrefEvents(String isPlanned, List<Event> events) async {
    await _saveEvents(isPlanned, events);
  }

  // ------------------- 取得清單 -------------------
  Future<List<Event>> getPrefEvents(String isPlanned) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr =
        prefs.getString(isPlanned == "Planned" ? _plannedKey : _historyKey);
    if (jsonStr == null) return [];

    final List<dynamic> decoded = json.decode(jsonStr);
    
    var events = decoded.map((e) {
      final event = Event.fromJson(e);
      sortSubEvents(event.subEvents); // ✅ 排序 subEvents
      return event;
    }).toList();
    
    if (isPlanned == "Planned") { // 🧠 過濾已過期活動
      events = filterValidEvents(events);
    }
    events = _sortEvents(events);
    return (isPlanned == "Planned"
        ? events
        : events.reversed.toList()).take(30).toList(); // ✅ 只取前 30 筆; // 升序 / 降序
  }

  // ------------------- 刪除單筆活動 -------------------
  Future<void> deletePrefEvent(String isPlanned, Event event) async {
    final events = await getPrefEvents(isPlanned);
    events.removeWhere((e) => e.id == event.id);
    await savePrefEvents(isPlanned, events);
  }

  // ------------------- 私有方法：取代或新增 -------------------
  void _replaceOrAdd(List<Event> events, Event event) {
    events.removeWhere((e) => e.id == event.id);
    events.add(event);
  }

  // ------------------- 私有方法：儲存與讀取 -------------------
  Future<void> _saveEvents(String isPlanned, List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = events.map((e) => e.toJson()).toList();
    await prefs.setString(isPlanned == "Planned" ? _plannedKey : _historyKey,
        json.encode(jsonList));
  }

  // ------------------- 私有方法：排序邏輯 -------------------
  List<Event> _sortEvents(List<Event> events) {
    events.sort((a, b) {
      final aStart = _toDateTime(a.startDate, a.startTime);
      final bStart = _toDateTime(b.startDate, b.startTime);

      final startCompare = aStart.compareTo(bStart);
      if (startCompare != 0) return startCompare;

      final aEnd = _toDateTime(a.endDate, a.endTime);
      final bEnd = _toDateTime(b.endDate, b.endTime);

      final endCompare = aEnd.compareTo(bEnd);
      if (endCompare != 0) return endCompare;

      final cityCompare = a.city.compareTo(b.city);
      if (cityCompare != 0) return cityCompare;

      return a.name.compareTo(b.name);
    });

    return events;
  }

  DateTime _toDateTime(DateTime? date, TimeOfDay? time) {
    return DateTime(
      date?.year ?? 0,
      date?.month ?? 0,
      date?.day ?? 0,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
  }
}
