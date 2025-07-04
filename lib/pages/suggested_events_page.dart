import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/firestore_service.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/utils/app_bar_action_util.dart';
import 'package:mom_where_go/utils/utils.dart';

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

  late final ScrollController _scrollController;
  List<Event> _events = [];
  final PageStorageBucket _bucket = PageStorageBucket();

  String? androidID = ''; // 用來儲存載入的 android ID
  // 用來加載 Android ID 的函數，這是一個異步函數
  Future<void> _loadAndroidID() async {
    final id = await getAndroidID(); // 異步取得 Android ID
    setState(() {
      androidID = id; // 更新狀態，將取得的 ID 儲存
    });
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAndroidID(); // 在小部件初始化時就加載資料
    }
    _scrollController = ScrollController();
    _service.getSuggestedEvents().listen((eventList) {
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
      firestoreService: _service,
      context: context,
      refreshCallback: () => setState(() {}),
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
          '建議活動',
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
                  ? const Center(child: Text('目前沒有建議活動'))
                  : EventList(
                      androidID: androidID!,  // 把加載完成的 androidID 傳遞給 EventList 小部件
                      events: filteredEvents,
                      isGridView: isGridView,
                      selectedEventIds: selectedEventIds,
                      removedEventIds: removedEventIds,
                      isEditable:
                          !kIsWeb && (Platform.isAndroid || Platform.isIOS),
                      isPlanned: isPlanned,
                      pref: _pref,
                      service: _service,
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
