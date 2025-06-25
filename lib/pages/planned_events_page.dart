import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/ui/widgets/event_card.dart';
import 'package:mom_where_go/utils/utils.dart';
import 'add_event_page.dart';

class PlannedEventsPage extends StatefulWidget {
  const PlannedEventsPage({super.key});

  @override
  State<PlannedEventsPage> createState() => _PlannedEventsPageState();
}

class _PlannedEventsPageState extends State<PlannedEventsPage> {
  final PreferenceService _pref = PreferenceService();

  List<Event> _events = []; // ← 儲存讀進來的資料
  final Set<String> selectedEventIds = {}; // 儲存已勾選的活動 id

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _pref.getPrefEvents("Planned"); 
    setState(() => _events = events);
  }

  Future<void> _onCheckboxChanged(bool? value, Event event) async {
    await handleCheckboxChanged(
      context: context,
      pref: _pref,
      value: value,
      event: event,
      selectedEventIds: selectedEventIds,
      setState: setState,
      prefKey: "History",
      addedMessage: '已加入歷史活動',
      duplicateMessage: '此活動已在歷史活動中',
      confirmTitle: '歷史活動',
    );
  }

  void _onEditEvent(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(
          saveToFirebase: false,
          saveToPlannedEvent: true,
          existingEvent: event,
        ),
      ),
    );
    await _loadEvents(); // ⬅️ 編輯回來後重新讀資料
  }

  Future<void> _removeEvent(Event event) async {
    await handleRemoveEvent(
      context: context,
      event: event,
      dialogTitle: '預計活動',
      onDelete: () async {
        _events.removeWhere((e) => e.id == event.id);
        await _pref.deletePrefEvent("Planned", event);
      },
      onSuccessSetState: () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('預計活動'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 50),
            tooltip: '新增活動',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AddEventPage(saveToFirebase: false, saveToPlannedEvent: true,),
                ),
              );
              await _loadEvents(); // 新增後重新載入
            },
          ),
        ],
      ),
      body: _events.isEmpty
          ? const Center(child: Text('目前沒有預計活動'))
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return EventCard(
                  event: event,
                  index: index,
                  onTap: () => _onEditEvent(event),
                  onDelete: () => _removeEvent(event),
                  trailing: Transform.scale(
                    scale: 1.5,
                    child: Checkbox(
                      value: selectedEventIds.contains(event.id),
                      onChanged: (value) => _onCheckboxChanged(value, event),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: null
    );
  }
}