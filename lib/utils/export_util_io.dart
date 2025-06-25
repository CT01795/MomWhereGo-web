import 'dart:io' as io;
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/utils/utils.dart';
import 'package:path_provider/path_provider.dart';

Future<void> exportEventsToExcel(BuildContext context, List<Event> events) async {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];

  sheet.appendRow([
    TextCellValue('活動名稱_______________________'), TextCellValue('關鍵字_______________________'),
    TextCellValue('縣市'), TextCellValue('地點____________________'), TextCellValue('費用 '),
    TextCellValue('開始日期__'), TextCellValue('開始時間'),
    TextCellValue('結束日期__'), TextCellValue('結束時間'),
    TextCellValue('描述______'), TextCellValue('相關單位'),
  ]);

  for (final e in events) {
    sheet.appendRow([
      TextCellValue(e.name), TextCellValue(e.type),
      TextCellValue(e.city), TextCellValue(e.location), TextCellValue(e.fee),
      TextCellValue(_formatDate(e.startDate)), TextCellValue(_formatTime(context, e.startTime)),
      TextCellValue(_formatDate(e.endDate)), TextCellValue(_formatTime(context, e.endTime)),
      TextCellValue(e.description), TextCellValue(e.unit),
    ]);

    for (final sub in e.subEvents) {
      sheet.appendRow([
        TextCellValue('  └ ${sub.name}'), TextCellValue(sub.type),
        TextCellValue(''), TextCellValue(sub.location), TextCellValue(sub.fee),
        TextCellValue(_formatDate(sub.startDate)), TextCellValue(_formatTime(context, sub.startTime)),
        TextCellValue(_formatDate(sub.endDate)), TextCellValue(_formatTime(context, sub.endTime)),
        TextCellValue(sub.description), TextCellValue(sub.unit),
      ]);
    }
  }

  final excelBytes = Uint8List.fromList(excel.encode()!);
  final filename = 'exported_events_${DateTime.now().millisecondsSinceEpoch}.xlsx';

  try {
    final file = await _saveToFile(filename, excelBytes);
    showSnackBar(context, '✅ 匯出成功：${file.path}');
  } catch (e) {
    showSnackBar(context, '❌ 匯出失敗：$e');
  }
}

Future<io.File> _saveToFile(String filename, Uint8List bytes) async {
  io.Directory dir;

  if (io.Platform.isAndroid) {
    dir = io.Directory('/storage/emulated/0/Download');
  } else if (io.Platform.isWindows) {
    dir = io.Directory('${io.Platform.environment['USERPROFILE']}\\Downloads');
  } else if (io.Platform.isMacOS) {
    dir = io.Directory('${io.Platform.environment['HOME']}/Downloads');
  } else {
    dir = await getApplicationDocumentsDirectory(); // iOS fallback
  }

  final file = io.File('${dir.path}/$filename');
  await file.create(recursive: true);
  return file.writeAsBytes(bytes);
}

String _formatDate(DateTime? date) {
  return date != null
      ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
      : '';
}

String _formatTime(BuildContext context, TimeOfDay? time) {
  return time != null ? time.format(context) : '';
}
