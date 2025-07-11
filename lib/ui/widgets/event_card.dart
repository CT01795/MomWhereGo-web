import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/utils/date_util.dart';
import 'package:mom_where_go/utils/utils.dart';
import 'package:mom_where_go/utils/widgets_util.dart';
import 'package:url_launcher/url_launcher.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? trailing;

  const EventCard({
    super.key,
    required this.event,
    required this.index,
    required this.onTap,
    this.onDelete,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.grey.shade100;
    //index % 2 == 0 ? Colors.grey.shade100 : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: cardColor,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  Text(
                    '${formatEventDateTime(event, "S")} - ${formatEventDateTime(event, "E")}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (event.fee.isNotEmpty || event.type.isNotEmpty)
                    Text(
                      '${event.fee == '' ? '' : '${event.fee}．'}${event.type}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  if (event.city.isNotEmpty || event.location.isNotEmpty)
                    Text(
                      '${event.city}．${event.location}',
                      style: const TextStyle(fontSize: 20),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.masterUrl != null && event.masterUrl!.isNotEmpty)
                        InkWell(
                          onTap: () async {
                            final Uri url = Uri.parse(event.masterUrl!);
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                            // ignore: use_build_context_synchronously
                            showSnackBar(context, '網址: $url');
                            /*if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              // 你可以加一個錯誤提示
                              // ignore: use_build_context_synchronously
                              showSnackBar(context,'無法開啟網址: $url');
                            }*/
                          },
                          child: Text(
                            event.masterUrl == null || event.masterUrl!.isEmpty
                                ? ''
                                : '點我看更多',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        SizedBox(width: 8,),
                      if (event.fee.isNotEmpty) 
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: buildTypeTags(event.fee),
                        ),
                        SizedBox(width: 8,),
                      if (event.type.isNotEmpty) 
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: buildTypeTags(event.type),
                        ),
                    ],
                  ),
                  ...event.subEvents.asMap().entries.map(
                    (entry) {
                      //final subIndex = entry.key;
                      final sub = entry.value;
                      //final bgColor = Colors.grey.shade300;
                      //subIndex % 2 == 0 ? Colors.deepPurple.shade100 : Colors.deepPurple.shade50;

                      return SizedBox(
                        width: double.infinity,
                        child: Card(
                          color: Colors.transparent, // ✅ 背景透明
                          elevation: 0, // ✅ 無陰影
                          margin: const EdgeInsets.only(
                              left: 20, right: 0, top: 6, bottom: 0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "👉 ${sub.name}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54),
                                ),
                                Text(
                                    '${formatEventDateTime(sub, "S")} - ${formatEventDateTime(sub, "E")}',
                                    style: const TextStyle(fontSize: 20)),
                                if (sub.fee.isNotEmpty || sub.type.isNotEmpty)
                                  Text(
                                    '${sub.fee == '' ? '' : '${sub.fee}．'}${sub.type}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                if ((sub.city.isNotEmpty ||
                                        sub.location.isNotEmpty) &&
                                    event.location != sub.location)
                                  Text(
                                    '${sub.city}．${sub.location}',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                if (sub.subUrl != null &&
                                    sub.subUrl!.isNotEmpty)
                                  InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse(sub.subUrl!);
                                      await launchUrl(url,
                                          mode: LaunchMode.externalApplication);
                                      // ignore: use_build_context_synchronously
                                      showSnackBar(context, '網址: $url');
                                      /*if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        // 你可以加一個錯誤提示
                                        // ignore: use_build_context_synchronously
                                        showSnackBar(context,'無法開啟網址: $url');
                                      }*/
                                    },
                                    child: Text(
                                      sub.subUrl == null || sub.subUrl!.isEmpty
                                          ? ''
                                          : '點我看更多',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (onDelete != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: '刪除活動',
              ),
            ),
        ],
      ),
    );
  }
}
