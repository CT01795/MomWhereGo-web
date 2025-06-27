import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/firestore_service.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/ui/widgets/event_card.dart';
import 'package:mom_where_go/ui/widgets/event_cardGraph.dart';
import 'package:mom_where_go/utils/export_util.dart';
import 'package:mom_where_go/utils/utils.dart';

import 'add_event_page.dart';

class SuggestedEventsPage extends StatefulWidget {
  const SuggestedEventsPage({super.key});

  @override
  State<SuggestedEventsPage> createState() => _SuggestedEventsPageState();
}

class _SuggestedEventsPageState extends State<SuggestedEventsPage> {
  final FirestoreService _service = FirestoreService();
  bool isGridView = true; // 預設為 GridView 模式
  
  // 儲存已勾選的活動 id
  final Set<String> selectedEventIds = {};
  final Set<String> removedEventIds = {};
  final PreferenceService _pref = PreferenceService(); // 加這行在 class 裡

  void _onCheckboxChanged(bool? value, Event event) async {
    await handleCheckboxChanged(
      context: context,
      pref: _pref,
      value: value,
      event: event,
      selectedEventIds: selectedEventIds,
      setState: setState,
      prefKey: "Planned",
      addedMessage: '已加入預計活動',
      duplicateMessage: '此活動已在預計活動中',
      confirmTitle: '預計活動',
    );
  }

  void _onEditEvent(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(
          saveToFirebase: true,
          saveToPlannedEvent: false,
          existingEvent: event,
        ),
      ),
    );
    setState(() {}); // 回來時刷新資料
  }

  void _removeEvent(Event event) async {
    await handleRemoveEvent(
      context: context,
      event: event,
      dialogTitle: '建議活動',
      onDelete: () async {
        await _service.deleteEvent(event);
      },
      onSuccessSetState: () {
        setState(() {
          removedEventIds.add(event.id);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('建議活動'),
        actions: [
          IconButton(
            icon: Icon(isGridView ?  Icons.view_agenda : Icons.view_list, size: 50),
            tooltip: '切換檢視模式',
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 50),
            tooltip: '匯出 Excel',
            onPressed: () async {
              try {
                // 從 Stream 取一次最新資料
                final events = await _service.getSuggestedEvents().first;
                // 過濾被刪除的活動
                final filteredEvents = events
                    .where((e) => !removedEventIds.contains(e.id))
                    .toList();

                if (filteredEvents.isEmpty) {
                  // ignore: use_build_context_synchronously
                  showSnackBar(context, "❌ 沒有可匯出的活動");
                  return;
                }

                // ignore: use_build_context_synchronously
                await exportEventsToExcel(context, filteredEvents);
              } catch (e) {
                // ignore: use_build_context_synchronously
                showSnackBar(context, "❌ 匯出失敗：$e");
              }
            },
          ),
          if(!kIsWeb && (Platform.isAndroid || Platform.isIOS))
            IconButton(
              icon: const Icon(Icons.add, size: 50),
              tooltip: '新增活動',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEventPage(
                      saveToFirebase: true,
                      saveToPlannedEvent: false,
                    ),
                  ),
                ).then((_) {
                  setState(() {}); // 回來後刷新畫面
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: _service.getSuggestedEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('目前沒有建議活動'));
          }

          final events = snapshot.data!;
          // 過濾被刪除的活動
          final filteredEvents =
              events.where((e) => !removedEventIds.contains(e.id)).toList();
          if (isGridView) {
            return ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return EventCardGraph(
                  event: event,
                  index: index,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => EventImageDialog(event: event),
                    );
                  },
                );
              },
            );
          } else {
            return ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return EventCard(
                  event: event,
                  index: index,
                  onTap: !kIsWeb && (Platform.isAndroid || Platform.isIOS) ? () => _onEditEvent(event) : null,
                  onDelete: !kIsWeb && (Platform.isAndroid || Platform.isIOS) ? () => _removeEvent(event) : null,
                    trailing: !kIsWeb && (Platform.isAndroid || Platform.isIOS)
                      ? Transform.scale(
                        scale: 1.5,
                        child: Checkbox(
                          value: selectedEventIds.contains(event.id),
                          onChanged: (value) => _onCheckboxChanged(value, event),
                        ),
                      ): null,
                );
              },
            );
          }
        },
      ),
      floatingActionButton: null,
    );
  }
}
