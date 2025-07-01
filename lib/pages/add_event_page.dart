import 'dart:convert'; 
import 'dart:io';

import 'package:dropbox_client/dropbox_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/services/firestore_service.dart';
import 'package:mom_where_go/services/preference_service.dart';
import 'package:mom_where_go/utils/utils.dart';
import 'package:uuid/uuid.dart';

var logger = Logger();
final uuid = const Uuid();

class AddEventPage extends StatefulWidget {
  final bool saveToFirebase;
  final bool saveToPlannedEvent;
  final Event? existingEvent;

  const AddEventPage({
    super.key,
    required this.saveToFirebase,
    required this.saveToPlannedEvent,
    this.existingEvent,
  });

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  DateTime startDate = DateTime.now();
  DateTime? endDate;
  TimeOfDay startTime = TimeOfDay.fromDateTime(DateTime.now());
  TimeOfDay? endTime;
  String city = '';
  String location = '';
  String name = '';
  String type = '';
  String description = '';
  String fee = '';
  String unit = '';
  List<SubEventItem> subEvents = [];

  String? masterGraphUrl;
  List<SubGraph> subGraphs = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      final e = widget.existingEvent!;
      masterGraphUrl = e.masterGraphUrl;
      startDate = e.startDate!;
      endDate = e.endDate;
      startTime = e.startTime!;
      endTime = e.endTime;
      city = e.city;
      location = e.location;
      name = e.name;
      type = e.type;
      description = e.description;
      fee = e.fee;
      unit = e.unit;
      subEvents = List.from(e.subEvents);
      subGraphs = List.from(e.subGraphs);
    }
  }

  Future<void> _pickDate({required bool isStart, int? index}) async {
    final initial = isStart
        ? (index == null ? startDate : subEvents[index].startDate) ??
            DateTime.now()
        : (index == null ? endDate : subEvents[index].endDate) ??
            DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1800)),
      lastDate: DateTime.now().add(const Duration(days: 1800)),
    );

    if (picked != null) {
      setState(() {
        if (index == null) {
          isStart ? startDate = picked : endDate = picked;
        } else {
          isStart
              ? subEvents[index].startDate = picked
              : subEvents[index].endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart, int? index}) async {
    final initial = isStart
        ? (index == null ? startTime : subEvents[index].startTime) ??
            TimeOfDay.now()
        : (index == null ? endTime : subEvents[index].endTime) ??
            TimeOfDay.now();

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked != null) {
      setState(() {
        if (index == null) {
          isStart ? startTime = picked : endTime = picked;
        } else {
          isStart
              ? subEvents[index].startTime = picked
              : subEvents[index].endTime = picked;
        }
      });
    }
  }

  Widget _buildDateTimeRow({int? index}) {
    final dStart = index == null ? startDate : subEvents[index].startDate;
    final dEnd = index == null ? endDate : subEvents[index].endDate;
    final tStart = index == null ? startTime : subEvents[index].startTime;
    final tEnd = index == null ? endTime : subEvents[index].endTime;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildDateTile(
                    dStart, () => _pickDate(isStart: true, index: index), "S")),
            const Text(' ~ '),
            Expanded(
                child: _buildDateTile(
                    dEnd, () => _pickDate(isStart: false, index: index), "E")),
          ],
        ),
        Row(
          children: [
            Expanded(
                child: _buildTimeTile(
                    tStart, () => _pickTime(isStart: true, index: index), "S")),
            const Text(' ~ '),
            Expanded(
                child: _buildTimeTile(
                    tEnd, () => _pickTime(isStart: false, index: index), "E")),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTile(DateTime? date, VoidCallback onTap, String type) {
    final text = date != null
        ? '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}'
        : (type == "S" ? '開始日期' : '結束日期');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity(horizontal: -4, vertical: -2), // 減少間距
      subtitle: Text(text, textAlign: TextAlign.center),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  Widget _buildTimeTile(TimeOfDay? time, VoidCallback onTap, String type) {
    final text = time?.format(context) ?? (type == "S" ? '開始時間' : '結束時間');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity(horizontal: -4, vertical: -2), // 減少間距
      subtitle: Text(text, textAlign: TextAlign.center),
      trailing: const Icon(Icons.access_time),
      onTap: onTap,
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Widget _buildSubEventCard(int index) {
    final d = subEvents[index];
    return Card(
      key: ValueKey(d.id.isNotEmpty ? d.id : index), // <--- 加上這行
      color: index % 2 == 0 ? Colors.grey[300] : Colors.purple[100],
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            _buildDateTimeRow(index: index),
            _buildTextField(
                label: '地點',
                initialValue: d.location,
                onChanged: (v) => d.location = v),
            _buildTextField(
                label: '名稱',
                initialValue: d.name,
                onChanged: (v) => d.name = v),
            _buildTextField(
                label: '關鍵字',
                initialValue: d.type,
                onChanged: (v) => d.type = v),
            _buildTextField(
                label: '描述',
                initialValue: d.description,
                onChanged: (v) => d.description = v,
                maxLines: 2),
            _buildTextField(
                label: '費用', initialValue: d.fee, onChanged: (v) => d.fee = v),
            _buildTextField(
                label: '相關單位',
                initialValue: d.unit,
                onChanged: (v) => d.unit = v),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete,
                    size: 40, color: Colors.pinkAccent),
                onPressed: () => setState(() => subEvents.removeAt(index)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickAndUploadImage(String filename) async {
    // 先確保 Dropbox 已授權
    String? accessToken = await Dropbox.getAccessToken();
    logger.i("accessToken : $accessToken");
    if (accessToken == null) {
      try {
        await Dropbox.authorizePKCE(); // 觸發登入
        accessToken = await Dropbox.getAccessToken();
        if (accessToken == null) return null;
      } catch (e) {
        throw Exception("Dropbox 授權失敗: $e");
        //return null;
      }
    }

    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return null;

    setState(() => _isUploading = true);

    try {
      final dropboxPath = '/MomWhereGo/$filename';
      final uploadResult = await Dropbox.upload(img.path, dropboxPath);

      if (uploadResult == null) {
        throw Exception('Dropbox 上傳失敗');
      }

      // 取得分享連結
      final sharedLinkResult = await createSharedLink(dropboxPath, accessToken);

      setState(() => _isUploading = false);

      if (sharedLinkResult != null) {
        // Dropbox 分享連結會是 ?dl=0，換成直接可顯示的 raw 圖片連結 ?raw=1
        logger.i("最終圖片網址: ${sharedLinkResult.replaceFirst('dl=0', 'raw=1')}");
        final githubUrl =
            'https://ct01795.github.io/MomWhereGo-web/dropbox_files/$filename';
        //return sharedLinkResult.replaceFirst('dl=0', 'raw=1');
        return githubUrl;
      } else {
        return null;
      }
    } catch (e) {
      setState(() => _isUploading = false);
      throw Exception('Dropbox 上傳錯誤: $e');
      //return null;
    }
  }

  Future<String?> createSharedLink(String path, String accessToken) async {
    final url = Uri.parse(
        'https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings');
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'path': path,
      'settings': {
        'requested_visibility': 'public',
      },
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url']; // Dropbox 返回的分享連結
    } else {
      logger.i('Failed to create shared link: ${response.body}');
      return null;
    }
  }

  Widget _buildMasterImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (masterGraphUrl != null) Image.network(masterGraphUrl!, height: 300),
        ElevatedButton(
          onPressed: _isUploading
              ? null
              : () async {
                  final url = await _pickAndUploadImage('${uuid.v4()}.jpg');
                  if (url != null) setState(() => masterGraphUrl = url);
                },
          child: Text(masterGraphUrl == null ? '挑選主圖' : '更換主圖'),
        ),
      ],
    );
  }

  Widget _buildSubGraphPicker() {
    return Column(
      children: [
        for (int i = 0; i < subGraphs.length; i++)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.network(
                    subGraphs[i].url,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  Text('${i + 1}'),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => subGraphs.removeAt(i)),
                  ),
                ],
              ),
              SizedBox(
                height: 12,
              )
            ],
          ),
        ElevatedButton.icon(
          icon: const Icon(
            Icons.add, size: 40
          ),
          label: const Text('新增子圖'),
          onPressed: _isUploading
              ? null
              : () async {
                  final url = await _pickAndUploadImage('${uuid.v4()}.jpg');
                  if (url != null) {
                    setState(() => subGraphs.add(SubGraph(url: url)));
                  }
                },
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final event = Event(
      id: widget.existingEvent?.id ?? uuid.v4(),
      masterGraphUrl: masterGraphUrl,
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      city: city,
      location: location,
      name: name,
      type: type,
      description: description,
      fee: fee,
      unit: unit,
      subEvents: subEvents
          .map((d) => d.id.isEmpty ? d.copyWith(id: uuid.v4()) : d)
          .toList(),
      subGraphs: subGraphs,
    );

    if ((Platform.isAndroid || Platform.isIOS) && widget.saveToFirebase) {
      await FirestoreService().saveSuggestedEvent(event, widget.existingEvent == null);
      // ignore: use_build_context_synchronously
      showSnackBar(context, '建議活動已儲存至 Firebase');
    } else if (widget.saveToPlannedEvent) {
      await PreferenceService().savePrefEvent("Planned", event);
      // ignore: use_build_context_synchronously
      showSnackBar(context, '預計活動已儲存');
    } else {
      await PreferenceService().savePrefEvent("History", event);
      // ignore: use_build_context_synchronously
      showSnackBar(context, '歷史活動已儲存');
    }

    // ignore: use_build_context_synchronously
    Navigator.pop(context, widget.existingEvent == null ? event : null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增／編輯活動'),
        actions: [
          TextButton(onPressed: _submit, child: const Text('儲存')),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            children: [
              _buildDateTimeRow(),
              _buildTextField(
                  label: '縣市', initialValue: city, onChanged: (v) => city = v),
              _buildTextField(
                  label: '地點',
                  initialValue: location,
                  onChanged: (v) => location = v),
              _buildTextField(
                  label: '名稱', initialValue: name, onChanged: (v) => name = v),
              _buildTextField(
                  label: '關鍵字', initialValue: type, onChanged: (v) => type = v),
              _buildTextField(
                  label: '描述',
                  initialValue: description,
                  onChanged: (v) => description = v,
                  maxLines: 2),
              _buildTextField(
                  label: '費用', initialValue: fee, onChanged: (v) => fee = v),
              _buildTextField(
                  label: '相關單位',
                  initialValue: unit,
                  onChanged: (v) => unit = v),
              const SizedBox(height: 8),
              _buildMasterImagePicker(),
              const SizedBox(height: 8),
              _buildSubGraphPicker(),
              const Divider(),
              const Text('細項活動'),
              ...List.generate(subEvents.length, _buildSubEventCard),
              const SizedBox(height: 4),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => subEvents.add(SubEventItem(
                      startDate: startDate,
                      startTime: startTime,
                      city: city,
                      location: location)));
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                },
                icon: const Icon(
                  Icons.add, size: 40
                ),
                label: const Text('新增細項'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
