import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mom_where_go/extensions/time_of_day_extensions.dart';
import 'package:mom_where_go/utils/utils.dart';
import '../models/event.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 建立 Firestore 文件 ID（自定義格式）
  String _generateDocId(Event event) {
    final startIso = event.startDate?.toIso8601String() ?? 'unknown';
    final timeStr = event.startTime?.formatTimeString() ?? 'noTime';
    final city = event.city.trim().replaceAll(' ', '_');
    final location = event.location.trim().replaceAll(' ', '_');

    return 'activity_${startIso}_${city}_${timeStr}_${location}_${event.id}';
  }

  /// 儲存一筆建議活動至 Firestore（使用自定義 docId）
  Future<void> saveSuggestedEvent(Event event) async {
    final docId = _generateDocId(event);
    final docRef = _db.collection('events').doc(docId);
    await docRef.set(event.toJson());
  }

  /// 取得建議活動清單（依照 docId 排序）
  Stream<List<Event>> getSuggestedEvents() {
    return _db
        .collection('events')
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map((snapshot) {
          final events =
            snapshot.docs.map((doc) {
              final event = Event.fromJson(doc.data());
              sortSubEvents(event.subEvents); // ✅ 排序 subEvents
              return event;
            }).toList();
          return filterValidEvents(events); // ✅ 事件過濾
          //return events;
    });
  }

  /// 刪除指定活動
  Future<void> deleteEvent(Event event) async {
    final docId = _generateDocId(event);
    await _db.collection('events').doc(docId).delete();
  }
}
