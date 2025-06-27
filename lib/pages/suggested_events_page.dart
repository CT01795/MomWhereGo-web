import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/firestore_service.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/ui/widgets/event_card.dart';
import 'package:mom_where_go/ui/widgets/event_card_graph.dart';
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

  // 搜尋相關狀態
  String _searchKeywords = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

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

  void _showSearchPanel() {
    _searchController.text = _searchKeywords; // 同步文字控制器
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 讓 BottomSheet 可推上鍵盤高度
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '關鍵字搜尋(空白分隔)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchKeywords.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchKeywords = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchKeywords = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_startDate == null
                            ? '開始日期'
                            : "${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.day.toString().padLeft(2, '0')}"),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: _endDate ?? DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                              if (_endDate != null && _startDate!.isAfter(_endDate!)) {
                                _endDate = null;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: '清除開始日期',
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                          });
                        },
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_endDate == null
                            ? '結束日期'
                            : "${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}"),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _endDate = picked;
                              if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                                _startDate = null;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    if (_endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: '清除結束日期',
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('關閉搜尋'),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
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
            icon: const Icon(Icons.search, size: 50),
            tooltip: '搜尋',
            onPressed: _showSearchPanel,
          ),
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
          final filteredEvents = events.where((e) {
              if (removedEventIds.contains(e.id)) return false;

            // 多關鍵字過濾
            final keywords = _searchKeywords
                .toLowerCase()
                .split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .toList();

            bool matchesKeywords = false || _searchKeywords.replaceAll(" ","").isEmpty;
            for (final word in keywords) {
              if (e.name.toLowerCase().contains(word) || 
                e.type.toLowerCase().contains(word) ||
                e.city.toLowerCase().contains(word)) {
                matchesKeywords = true;
                break;
              }
            }

            // 日期範圍過濾 (假設 event.startDate 是 DateTime)
            bool matchesDate = true;
            if (_startDate != null) {
              if (e.startDate!.isBefore(_startDate!)) matchesDate = false;
            }
            if (_endDate != null && e.startDate != null) {
              if (e.startDate!.isAfter(_endDate!)) matchesDate = false;
            }

            return matchesKeywords && matchesDate;
          }).toList();

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
