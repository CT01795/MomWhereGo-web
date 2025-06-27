import 'package:flutter/material.dart';
import 'package:mom_where_go/extensions/time_of_day_extensions.dart';
import 'package:uuid/uuid.dart';

final _uuid = const Uuid(); // 僅限這個檔案使用

class Event {
  final String id;
  String? masterGraphUrl; // 圖片 URL 而非 Image widget
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
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      startTime: (json['startTime'] as String?)?.parseToTimeOfDay(),
      endTime: (json['endTime'] as String?)?.parseToTimeOfDay(),
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
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      startTime: (json['startTime'] as String?)?.parseToTimeOfDay(),
      endTime: (json['endTime'] as String?)?.parseToTimeOfDay(),
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
