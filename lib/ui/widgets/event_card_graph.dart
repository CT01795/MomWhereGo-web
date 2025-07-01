import 'package:flutter/material.dart';
import 'package:mom_where_go/models/event.dart';
import 'package:mom_where_go/ui/widgets/event_card.dart';
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
    final cardColor = Colors.grey.shade100;
    //index % 2 == 0 ? Colors.grey.shade100 : Colors.grey.shade300;

    /*if (event.masterGraphUrl != null && event.masterGraphUrl!.isNotEmpty) {
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
    }*/
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
                      style: const TextStyle(fontSize: 20)),
                  if (event.city.isNotEmpty || event.location.isNotEmpty)
                    Text(
                      '${event.city}．${event.location}',
                      style: const TextStyle(fontSize: 20),
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

class EventImageDialog extends StatelessWidget {
  final Event event;
  const EventImageDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final hasMaster =
        event.masterGraphUrl != null && event.masterGraphUrl!.isNotEmpty;
    //final hasSub = event.subGraphs.isNotEmpty;

    // ✅ 如果沒有圖片，回退顯示文字 EventCard
    if (!hasMaster) {
      return Dialog(
        backgroundColor: Colors.transparent, // ✅ 將 Dialog 本體透明
        insetPadding: const EdgeInsets.symmetric(horizontal: 6), // ✅ 整體左右間距
        child: Stack(
          children: [
            // 可滾動內容
            SingleChildScrollView(
              child: EventCard(
                event: event,
                index: 0,
                onTap: () => Navigator.pop(context),
              ),
            ),

            // 右上角浮動的關閉按鈕（白底）
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  tooltip: '關閉',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          // 可滾動內容
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.masterGraphUrl != null &&
                    event.masterGraphUrl!.isNotEmpty) ...[
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
                  //const Divider(),
                ],
                if (event.subGraphs.isNotEmpty)
                  ...event.subGraphs.map((subGraph) {
                    return Column(
                      children: [
                        const Divider(),
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
                      ],
                    );
                  }),
                //const SizedBox(height: 12),
              ],
            ),
          ),

          // 右上角浮動的關閉按鈕（白底）
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                tooltip: '關閉',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
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
