import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/utils/app_bar_action_util.dart';

class PlannedEventsPage extends StatefulWidget {
  const PlannedEventsPage({super.key});

  @override
  State<PlannedEventsPage> createState() => _PlannedEventsPageState();
}

class _PlannedEventsPageState extends State<PlannedEventsPage> {
  late AppBarActionsHandler handler;
  bool isGridView = true; 
  bool _showSearchPanel = false;
  String isPlanned = "Planned";

  // 儲存已勾選的活動 id
  final Set<String> selectedEventIds = {};
  final Set<String> removedEventIds = {};
  final PreferenceService _pref = PreferenceService(); // 加這行在 class 裡

  // 搜尋相關狀態
  String _searchKeywords = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  late final ScrollController _scrollController;
  List<Event> _events = [];
  final PageStorageBucket _bucket = PageStorageBucket();
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pref.getPrefEvents(isPlanned).then((eventList) {
      setState(() {
        _events = eventList;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    handler = AppBarActionsHandler(
      firestoreService: null,
      pref: _pref,
      context: context,
      refreshCallback: () => setState(() => {}), // 新增後重新載入,
      setState: setState,
      isGridViewGetter: () => isGridView,
      showSearchPanelGetter: () => _showSearchPanel,
      onToggleGridView: (val) => isGridView = val,
      onToggleShowSearch: (val) => _showSearchPanel = val,
    );

    final filteredEvents = filterEvents(
      events: _events,
      removedEventIds: removedEventIds,
      searchKeywords: _searchKeywords,
      startDate: _startDate,
      endDate: _endDate,
    );

    return PageStorage(
      bucket: _bucket,
      child: Scaffold(
        appBar: buildWhiteAppBar(
          isPlanned,
          '預計活動',
          enableSearchAndExport: true, // ✅ 僅此頁啟用
          isGridView: isGridView,
          handler: handler,
          setState: setState, // 必須傳入
          onAdd: () => handler.onAddEvent(context, isPlanned),
        ),
        body: Column(
          children: [
            if (_showSearchPanel)
              buildSearchPanel(
                searchController: _searchController,
                searchKeywords: _searchKeywords,
                startDate: _startDate,
                endDate: _endDate,
                onSearchKeywordsChanged: (value) => _searchKeywords = value,
                onStartDateChanged: (date) => _startDate = date,
                onEndDateChanged: (date) => _endDate = date,
                setState: setState,
                context: context,
              ),
            Expanded(
              child: _events.isEmpty
                  ? const Center(child: Text('目前沒有預計活動'))
                  : EventList(
                      events: filteredEvents,
                      isGridView: isGridView,
                      selectedEventIds: selectedEventIds,
                      removedEventIds: removedEventIds,
                      isEditable:
                          !kIsWeb && (Platform.isAndroid || Platform.isIOS),
                      isPlanned: isPlanned,
                      pref: _pref,
                      service: null,
                      setState: setState,
                      scrollController: _scrollController,
                    ),
            ),
          ],
        ),
        floatingActionButton: null,
      ),
    );
  }
}
