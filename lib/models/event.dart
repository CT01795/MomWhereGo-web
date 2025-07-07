import 'package:flutter/material.dart';
import 'package:mom_where_go/extensions/time_of_day_extensions.dart';
import 'package:uuid/uuid.dart';

final _uuid = const Uuid(); // 僅限這個檔案使用

// 公用日期格式化函數
DateTime? fromIso8601StringOrNull(String? date) =>
    date != null ? DateTime.parse(date) : null;

// 公用時間處理函數
TimeOfDay? parseTimeOfDay(String? time) => time?.parseToTimeOfDay();

class Event {
  String id;
  String? masterGraphUrl; // 圖片 URL 而非 Image widget
  String? masterUrl;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String city;
  String location;
  String name;
  String type;
  String description;
  String fee;
  String unit;
  List<SubEventItem> subEvents;
  List<SubGraph> subGraphs;

  Event({
    String? id,
    this.masterGraphUrl,
    this.masterUrl,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.city = '',
    this.location = '',
    this.name = '',
    this.type = '',
    this.description = '',
    this.fee = '',
    this.unit = '',
    List<SubEventItem>? subEvents,
    List<SubGraph>? subGraphs,
  })  : id = id ?? _uuid.v4(),
        subEvents = subEvents ?? [],
        subGraphs = subGraphs ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'masterGraphUrl': masterGraphUrl,
      'masterUrl': masterUrl,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime': startTime?.formatTimeString(),
      'endTime': endTime?.formatTimeString(),
      'city': city,
      'location': location,
      'name': name,
      'type': type,
      'description': description,
      'fee': fee,
      'unit': unit,
      'subEvents': subEvents.map((e) => e.toJson()).toList(),
      'subGraphs': subGraphs.map((e) => e.toJson()).toList(),
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      masterGraphUrl: json['masterGraphUrl'],
      masterUrl: json['masterUrl'],
      startDate: fromIso8601StringOrNull(json['startDate']),
      endDate: fromIso8601StringOrNull(json['endDate']),
      startTime: parseTimeOfDay(json['startTime']),
      endTime: parseTimeOfDay(json['endTime']),
      city: json['city'] ?? '',
      location: json['location'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      fee: json['fee'] ?? '',
      unit: json['unit'] ?? '',
      subEvents: (json['subEvents'] as List<dynamic>?)
              ?.map((e) => SubEventItem.fromJson(e))
              .toList() ??
          [],
      subGraphs: (json['subGraphs'] as List<dynamic>?)
              ?.map((e) => SubGraph.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SubEventItem {
  final String id;
  String? subUrl;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String city;
  String location;
  String name;
  String type;
  String description;
  String fee;
  String unit;

  SubEventItem({
    String? id,
    this.subUrl,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.city = '',
    this.location = '',
    this.name = '',
    this.type = '',
    this.description = '',
    this.fee = '',
    this.unit = '',
  }) : id = id ?? _uuid.v4();

  SubEventItem copyWith({
    String? id,
    String? subUrl,
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? city,
    String? location,
    String? name,
    String? type,
    String? description,
    String? fee,
    String? unit,
  }) {
    return SubEventItem(
      id: id ?? this.id,
      subUrl:subUrl ?? this.subUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      city: city ?? this.city,
      location: location ?? this.location,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      fee: fee ?? this.fee,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subUrl': subUrl,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime': startTime?.formatTimeString(),
      'endTime': endTime?.formatTimeString(),
      'city': city,
      'location': location,
      'name': name,
      'type': type,
      'description': description,
      'fee': fee,
      'unit': unit,
    };
  }

  factory SubEventItem.fromJson(Map<String, dynamic> json) {
    return SubEventItem(
      id: json['id'],
      subUrl: json['subUrl'],
      startDate: fromIso8601StringOrNull(json['startDate']),
      endDate: fromIso8601StringOrNull(json['endDate']),
      startTime: parseTimeOfDay(json['startTime']),
      endTime: parseTimeOfDay(json['endTime']),
      city: json['city'] ?? '',
      location: json['location'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      fee: json['fee'] ?? '',
      unit: json['unit'] ?? '',
    );
  }
}

class SubGraph {
  final String url;

  SubGraph({required this.url});

  factory SubGraph.fromJson(Map<String, dynamic> json) =>
      SubGraph(url: json['url']);

  Map<String, dynamic> toJson() => {'url': url};
}
