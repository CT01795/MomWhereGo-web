import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/firestore_service.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/utils/app_bar_action_util.dart';
import 'package:mom_where_go/utils/device_util.dart';

class EventPage extends StatefulWidget {
  final String pageTitle;
  final String eventType; // 'Suggested' 或 'History' 或 'Planned'
  final FirestoreService?
      firestoreService; // FirestoreService 會傳入 Suggestion 頁面
  final PreferenceService?
      preferenceService; // PreferenceService 會傳入 History 頁面

  const EventPage({
    required this.pageTitle,
    required this.eventType,
    this.firestoreService,
    this.preferenceService,
    super.key,
  });

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late AppBarActionsHandler handler;
  bool isGridView = true;
  bool _showSearchPanel = false;

  Set<String> selectedEventIds = {};
  Set<String> removedEventIds = {};
  late final PreferenceService _pref;
  late final FirestoreService _service;

  String _searchKeywords = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  late final ScrollController _scrollController;
  List<Event> _events = [];
  final PageStorageBucket _bucket = PageStorageBucket();

  String? androidID = ''; // 用來儲存載入的 android ID
  bool _isAndroidIDLoaded = false; // 新增的 flag 用來判斷是否已經完成 androidID 加載
  // 用來加載 Android ID 的函數，這是一個異步函數
  Future<void> _loadAndroidID() async {
    final id = await getAndroidID(); // 異步取得 Android ID
    setState(() {
      androidID = id; // 更新狀態，將取得的 ID 儲存
      _isAndroidIDLoaded = true; // 加載完成後標記為 true
    });
  }

  @override
  void initState() {
    super.initState();
    _pref = widget.preferenceService ?? PreferenceService();
    _service = widget.firestoreService ?? FirestoreService();

    _scrollController = ScrollController();
    if (!kIsWeb) {
      _loadAndroidID(); // 在小部件初始化時就加載資料
    }
    else{
      _isAndroidIDLoaded = true; // 加載完成後標記為 true
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 清空搜尋條件
  void _clearSearchFilters() {
    setState(() {
      _searchController.clear();
      _searchKeywords = '';
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 如果還在加載 Android ID，則顯示 loading 螢幕
    if (!_isAndroidIDLoaded) {
      return Scaffold(
        appBar: AppBar(
          title: Text("載入中..."),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.eventType == 'Suggested') {
      _service.getSuggestedEvents().listen((eventList) {
        setState(() {
          _events = eventList;
        });
      });
    } else {
      _pref.getPrefEvents(widget.eventType).then((eventList) {
        setState(() {
          _events = eventList;
        });
      });
    }

    selectedEventIds = {};
    removedEventIds = {};

    handler = AppBarActionsHandler(
      firestoreService: _service,
      pref: _pref,
      context: context,
      refreshCallback: () => setState(() {}),
      setState: setState,
      isGridViewGetter: () => isGridView,
      showSearchPanelGetter: () => _showSearchPanel,
      onToggleGridView: (val) => setState(() => isGridView = val),
      onToggleShowSearch: (val) {
        setState(() {
          _showSearchPanel = val;
          if (!_showSearchPanel) {
            // 如果搜尋面板關閉，清空搜尋條件
            _clearSearchFilters();
          }
        });
      },
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
          androidID!,
          widget.eventType,
          widget.pageTitle,
          enableSearchAndExport: true,
          isGridView: isGridView,
          handler: handler,
          setState: setState,
          onAdd: () => handler.onAddEvent(context, widget.eventType),
        ),
        body: Column(
          children: [
            if (_showSearchPanel)
              buildSearchPanel(
                searchController: _searchController,
                searchKeywords: _searchKeywords,
                startDate: _startDate,
                endDate: _endDate,
                onSearchKeywordsChanged: (value) =>
                    setState(() => _searchKeywords = value),
                onStartDateChanged: (date) => setState(() => _startDate = date),
                onEndDateChanged: (date) => setState(() => _endDate = date),
                setState: setState,
                context: context,
              ),
            Expanded(
              child: _events.isEmpty
                  ? Center(child: Text('目前沒有 ${widget.pageTitle}'))
                  : EventList(
                      androidID:
                          androidID!, // 把加載完成的 androidID 傳遞給 EventList 小部件
                      events: filteredEvents,
                      isGridView: isGridView,
                      selectedEventIds: selectedEventIds,
                      removedEventIds: removedEventIds,
                      isEditable:
                          !kIsWeb && (Platform.isAndroid || Platform.isIOS),
                      isPlanned: widget.eventType,
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
