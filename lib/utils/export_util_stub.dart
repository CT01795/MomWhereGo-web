import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';

Future<void> exportEventsToExcel(BuildContext context, List<Event> events) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('⚠️ 此平台尚未支援匯出 Excel')),
  );
}