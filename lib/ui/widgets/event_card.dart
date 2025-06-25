import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/utils/utils.dart';

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
    final cardColor =
        index % 2 == 0 ? Colors.grey.shade100 : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          '${formatEventDateTime(event, "S")} - ${formatEventDateTime(event, "E")}',
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  Text(
                    event.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                  if (event.fee.isNotEmpty || event.type.isNotEmpty)
                    Text(
                      '${event.fee == '' ? '' : '${event.fee}．'}${event.type}',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  if (event.city.isNotEmpty || event.location.isNotEmpty)
                    Text(
                      '${event.city}．${event.location}',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ...event.subEvents.asMap().entries.map(
                    (entry) {
                      final subIndex = entry.key;
                      final sub = entry.value;
                      final bgColor = subIndex % 2 == 0
                          ? Colors.deepPurple.shade100
                          : Colors.deepPurple.shade50;

                      return SizedBox(
                        width: double.infinity,
                        child: Card(
                          color: bgColor,
                          margin:
                              const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${formatEventDateTime(sub, "S")} - ${formatEventDateTime(sub, "E")}'),
                                Text(
                                  sub.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple),
                                ),
                                if (sub.fee.isNotEmpty || sub.type.isNotEmpty)
                                  Text(
                                    '${sub.fee == '' ? '' : '${sub.fee}．'}${sub.type}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                if (sub.city.isNotEmpty ||
                                    sub.location.isNotEmpty)
                                  Text(
                                    '${sub.city}．${sub.location}',
                                    style: const TextStyle(fontSize: 20),
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
