import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/firestore_service.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/utils/app_bar_action_util.dart';

class SuggestedEventsPage extends StatefulWidget {
  const SuggestedEventsPage({super.key});

  @override
  State<SuggestedEventsPage> createState() => _SuggestedEventsPageState();
}

class _SuggestedEventsPageState extends State<SuggestedEventsPage> {
  late AppBarActionsHandler handler;
  bool isGridView = true; // 預設為 GridView 模式
  bool _showSearchPanel = false;
  String isPlanned = "Suggested";
  final FirestoreService _service = FirestoreService();
  
  // 儲存已勾選的活動 id
  final Set<String> selectedEventIds = {};
  final Set<String> removedEventIds = {};
  final PreferenceService _pref = PreferenceService(); // 加這行在 class 裡

  // 搜尋相關狀態
  String _searchKeywords = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
      handler = AppBarActionsHandler(
      firestoreService: _service,
      context: context,
      refreshCallback: () => setState(() {}),
      setState: setState,
      isGridViewGetter: () => isGridView,
      showSearchPanelGetter: () => _showSearchPanel,
      onToggleGridView: (val) => isGridView = val,
      onToggleShowSearch: (val) => _showSearchPanel = val,
    );
    return Scaffold(
      appBar: buildWhiteAppBar(
        isPlanned,
        '建議活動',
        enableSearchAndExport: true, // ✅ 僅此頁啟用
        isGridView: isGridView,
        handler: handler,
        setState: setState,  // 必須傳入
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
            child: StreamBuilder<List<Event>>(
              stream: _service.getSuggestedEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('目前沒有建議活動'));
                }

                // 過濾被刪除的活動
                final filteredEvents = filterEvents(
                  events: snapshot.data!,
                  removedEventIds: removedEventIds,
                  searchKeywords: _searchKeywords,
                  startDate: _startDate,
                  endDate: _endDate,
                );

                return EventList(
                  events: filteredEvents,
                  isGridView: isGridView,
                  selectedEventIds: selectedEventIds,
                  removedEventIds: removedEventIds,
                  isEditable: !kIsWeb && (Platform.isAndroid || Platform.isIOS),
                  isPlanned: isPlanned,
                  pref: _pref,
                  service: _service,
                  setState: setState,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}
