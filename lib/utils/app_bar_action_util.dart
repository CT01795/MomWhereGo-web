import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/pages/add_event_page.dart';
import 'package:mom_where_go/services/firestore_service.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/ui/widgets/event_card.dart';
import 'package:mom_where_go/ui/widgets/event_card_graph.dart';
import 'package:mom_where_go/utils/export_util.dart';
import 'package:mom_where_go/utils/utils.dart';

List<Widget> buildAppBarActions({
  required String isPlanned,
  required bool enableSearchAndExport,
  required bool isGridView,
  required AppBarActionsHandler handler,
  required void Function(VoidCallback fn) setState,
  VoidCallback? onAdd,
}) {
  return [
    if (enableSearchAndExport)
      IconButton(
        icon: const Icon(Icons.search, size: 40),
        tooltip: '搜尋',
        onPressed: () => handler.onSearchToggle(),
      ),
    IconButton(
      icon: Icon(isGridView ? Icons.view_agenda : Icons.view_list, size: 40),
      tooltip: '切換檢視模式',
      onPressed: () => handler.onToggleView(),
    ),
    if (enableSearchAndExport)
      IconButton(
        icon: const Icon(Icons.download, size: 40),
        tooltip: '匯出 Excel',
        onPressed: () => handler.onExport(isPlanned),
      ),
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && onAdd != null)
      IconButton(
        icon: const Icon(Icons.add, size: 40),
        tooltip: '新增活動',
        onPressed: onAdd,
      ),
  ];
}

AppBar buildWhiteAppBar(
  String isPlanned,
  String title, {
  bool enableSearchAndExport = false,
  required bool isGridView,
  required AppBarActionsHandler handler,
  required void Function(void Function()) setState, // 這裡改
  VoidCallback? onAdd,
}) {
  return AppBar(
    title: Text(title),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    actions: buildAppBarActions(
      isPlanned: isPlanned,
      enableSearchAndExport: enableSearchAndExport,
      isGridView: isGridView,
      handler: handler,
      setState: setState,
      onAdd: onAdd,
    ),
  );
}

class AppBarActionsHandler {
  final BuildContext context;
  FirestoreService? firestoreService;
  PreferenceService? pref;
  bool isGridView = true;
  bool showSearchPanel = false;
  final VoidCallback refreshCallback;
  final void Function(void Function()) setState;

  // 直接從外面拿狀態，不要放內部變數
  bool Function() isGridViewGetter;
  bool Function() showSearchPanelGetter;

  final void Function(bool) onToggleGridView;
  final void Function(bool) onToggleShowSearch;

  AppBarActionsHandler({
    required this.context,
    this.firestoreService,
    this.pref,
    required this.refreshCallback,
    required this.setState,
    required this.isGridViewGetter,
    required this.showSearchPanelGetter,
    required this.onToggleGridView,
    required this.onToggleShowSearch,
  });

  void onSearchToggle() {
    setState(() {
      onToggleShowSearch(!showSearchPanelGetter());
    });
  }

  Future<void> onExport(String isPlanned) async {
    try {
      final events = isPlanned == "Suggested"
          ? await firestoreService?.getSuggestedEvents().first
          : await pref?.getPrefEvents(isPlanned);
      if (events!.isEmpty) {
        // ignore: use_build_context_synchronously
        showSnackBar(context, "❌ 沒有可匯出的活動");
        return;
      }
      // ignore: use_build_context_synchronously
      await exportEventsToExcel(context, events, isPlanned);
    } catch (e) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, "❌ 匯出失敗：$e");
    }
  }

  void onToggleView() {
    setState(() {
      onToggleGridView(!isGridViewGetter());
    });
  }

  Future<Event?> onAddEvent(BuildContext context, String isPlanned) {
    return Navigator.push<Event?>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(
          saveToFirebase: isPlanned == "Suggested",
          saveToPlannedEvent: isPlanned == "Planned",
        ),
      ),
    ).then((newEvent) {
      refreshCallback();  // 先刷新頁面
      return newEvent;     // 回傳新增的事件 (可能是 null)
    });
  }
}

Widget buildSearchPanel({
  required TextEditingController searchController,
  required String searchKeywords,
  required DateTime? startDate,
  required DateTime? endDate,
  required void Function(String) onSearchKeywordsChanged,
  required void Function(DateTime?) onStartDateChanged,
  required void Function(DateTime?) onEndDateChanged,
  required void Function(void Function()) setState,
  required BuildContext context,
}) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: '關鍵字搜尋(空白分隔)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchKeywords.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        onSearchKeywordsChanged('');
                        searchController.clear();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) {
            setState(() {
              onSearchKeywordsChanged(value.trim());
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(startDate == null
                    ? '開始日期'
                    : "${startDate.month.toString().padLeft(2, '0')}/${startDate.day.toString().padLeft(2, '0')}"),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: endDate ?? DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      onStartDateChanged(picked);
                      if (endDate != null && picked.isAfter(endDate)) {
                        onEndDateChanged(null);
                      }
                    });
                  }
                },
              ),
            ),
            if (startDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: '清除開始日期',
                onPressed: () {
                  setState(() {
                    onStartDateChanged(null);
                  });
                },
              ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(endDate == null
                    ? '結束日期'
                    : "${endDate.month.toString().padLeft(2, '0')}/${endDate.day.toString().padLeft(2, '0')}"),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      onEndDateChanged(picked);
                      if (startDate != null && picked.isBefore(startDate)) {
                        onStartDateChanged(null);
                      }
                    });
                  }
                },
              ),
            ),
            if (endDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: '清除結束日期',
                onPressed: () {
                  setState(() {
                    onEndDateChanged(null);
                  });
                },
              ),
          ],
        ),
      ],
    ),
  );
}

Future<void> onCheckboxChanged({
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
  await handleCheckboxChanged(
    context: context,
    pref: pref,
    value: value,
    event: event,
    selectedEventIds: selectedEventIds,
    setState: setState,
    isPlanned: isPlanned,
    addedMessage: addedMessage,
    duplicateMessage: duplicateMessage,
    confirmTitle: confirmTitle,
  );
}

Future<void> onEditEvent({
  required BuildContext context,
  required String isPlanned,
  required Event event,
  required void Function(void Function()) setState,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddEventPage(
        saveToFirebase: isPlanned == "Suggested" ? true : false,
        saveToPlannedEvent: isPlanned == "Suggested"
            ? false
            : (isPlanned == "Planned" ? true : false),
        existingEvent: event,
      ),
    ),
  );
  setState(() {});
}

Future<void> onRemoveEvent({
  required BuildContext context,
  required Event event,
  required String isPlanned,
  FirestoreService? service,
  PreferenceService? pref,
  required Set<String> removedEventIds,
  required void Function(void Function()) setState,
  String dialogTitle = '活動',
}) async {
  await handleRemoveEvent(
    context: context,
    event: event,
    dialogTitle: dialogTitle,
    onDelete: () async {
      isPlanned == "Suggested"
          ? await service?.deleteEvent(event)
          : await pref?.deletePrefEvent(isPlanned, event);
    },
    onSuccessSetState: () {
      setState(() {
        removedEventIds.add(event.id);
      });
    },
  );
}

List<Event> filterEvents({
  required List<Event> events,
  required Set<String> removedEventIds,
  required String searchKeywords,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final keywords = searchKeywords.toLowerCase().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

  return events.where((e) {
    if (removedEventIds.contains(e.id)) return false;

    bool matchesKeywords = searchKeywords.trim().isEmpty;
    for (final word in keywords) {
      if (e.name.toLowerCase().contains(word) ||
          e.type.toLowerCase().contains(word) ||
          e.city.toLowerCase().contains(word)) {
        matchesKeywords = true;
        break;
      }
    }

    bool matchesDate = true;
    if (startDate != null && e.startDate != null && e.startDate!.isBefore(startDate)) {
      matchesDate = false;
    }
    if (endDate != null && e.startDate != null && e.startDate!.isAfter(endDate)) {
      matchesDate = false;
    }

    return matchesKeywords && matchesDate;
  }).toList();
}

class EventList extends StatelessWidget {
  final List<Event> events;
  final bool isGridView;
  final Set<String> selectedEventIds;
  final Set<String> removedEventIds;
  final bool isEditable;
  final String isPlanned;
  final PreferenceService? pref;
  final FirestoreService? service;
  final void Function(void Function()) setState;
  final ScrollController scrollController;

  const EventList({
    super.key,
    required this.events,
    required this.isGridView,
    required this.selectedEventIds,
    required this.removedEventIds,
    required this.isEditable,
    required this.isPlanned,
    this.pref,
    this.service,
    required this.setState,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return ListView.builder(
        key: PageStorageKey('event_list_$isPlanned'), // ✅ 加這行
        controller: scrollController,
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCardGraph(
            event: event,
            index: index,
            onTap: () {
              showDialog(
                context: context,
                // ignore: deprecated_member_use
                barrierColor: Colors.black.withOpacity(0.4),
                builder: (_) => EventImageDialog(event: event),
              );
            },
          );
        },
      );
    } else {
      return ListView.builder(
        key: PageStorageKey('event_list_$isPlanned'), // ✅ 加這行
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCard(
            event: event,
            index: index,
            onTap: isEditable
                ? () async => await onEditEvent(
                      context: context,
                      isPlanned: isPlanned,
                      event: event,
                      setState: setState,
                    )
                : null,
            onDelete: isEditable
                ? () async => await onRemoveEvent(
                      context: context,
                      isPlanned: isPlanned,
                      event: event,
                      service: service,
                      pref: pref,
                      removedEventIds: removedEventIds,
                      setState: setState,
                      dialogTitle: isPlanned == "Planned" ? '預計活動' : (isPlanned == "History" ? '歷史活動' : '建議活動'),
                    )
                : null,
            trailing: isEditable && isPlanned != "History"
              ? StatefulBuilder(
                  builder: (context, localSetState) {
                    final isChecked = selectedEventIds.contains(event.id);
                    return Transform.scale(
                      scale: 1.5,
                      child: Checkbox(
                        value: isChecked,
                        onChanged: (value) async {
                          await onCheckboxChanged(
                            context: context,
                            pref: pref!,
                            value: value,
                            event: event,
                            selectedEventIds: selectedEventIds,
                            setState: (fn) {
                              fn();
                              // ✅ 單獨更新 checkbox 狀態
                              localSetState(() {});
                            },
                            isPlanned: isPlanned == "Planned" ? "History" : "Planned",
                            addedMessage: isPlanned == "Planned"
                                ? '已加入歷史活動'
                                : '已加入預計活動',
                            duplicateMessage: isPlanned == "Planned"
                                ? '此活動已在歷史活動中'
                                : '此活動已在預計活動中',
                            confirmTitle: isPlanned == "Planned"
                                ? '歷史活動'
                                : '預計活動',
                          );
                        },
                      ),
                    );
                  },
                )
              : null,
          );
        },
      );
    }
  }
}

void scrollToEventById({
  required List<Event> events,
  required ScrollController scrollController,
  required String eventId,
  double itemHeight = 120.0, // 預設高度，可調
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final index = events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final position = index * itemHeight;

      if (scrollController.hasClients) {
        scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  });
}
