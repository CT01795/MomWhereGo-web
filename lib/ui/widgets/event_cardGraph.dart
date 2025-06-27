import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/ui/widgets/event_card.dart';
import 'package:mom_where_go/utils/graph_util.dart';
import 'package:mom_where_go/utils/utils.dart';

class EventCardGraph extends StatelessWidget {
  final Event event;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? trailing;

  const EventCardGraph({
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

    if (event.masterGraphUrl != null && event.masterGraphUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: buildAutoSizeImage(event.masterGraphUrl!),
              ),
            ),
          ],
        ),
      );
    }
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
                  if (event.city.isNotEmpty || event.location.isNotEmpty)
                    Text(
                      '${event.city}．${event.location}',
                      style: const TextStyle(fontSize: 20),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventImageDialog extends StatelessWidget {
  final Event event;
  const EventImageDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final hasMaster = event.masterGraphUrl != null && event.masterGraphUrl!.isNotEmpty;
    final hasSub = event.subGraphs.isNotEmpty;

    // ✅ 如果沒有圖片，回退顯示文字 EventCard
    if (!hasMaster && !hasSub) {
      return Dialog(
        insetPadding: const EdgeInsets.all(0),
        backgroundColor: Colors.white,
        child: EventCard(
          event: event,
          index: 0,
          onTap: () => Navigator.pop(context),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (event.masterGraphUrl != null &&
                event.masterGraphUrl!.isNotEmpty) 
                ...[
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrl: event.masterGraphUrl!,
                          ),
                        ),
                      ),
                      child: Image.network(
                        event.masterGraphUrl!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Divider(),
                ],
            if (event.subGraphs.isNotEmpty) 
              ...event.subGraphs.map((subGraph) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrl: subGraph.url,
                            ),
                          ),
                        ),
                        child: Image.network(
                          subGraph.url,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                );
              }),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('關閉'),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            imageUrl.replaceFirst('dl=0', 'raw=1'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}