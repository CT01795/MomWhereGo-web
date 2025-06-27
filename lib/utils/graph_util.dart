import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Widget buildAutoSizeImage(String imageUrl) {
  return FutureBuilder<Size>(
    future: getImageSize(imageUrl),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (!snapshot.hasData || snapshot.hasError) {
        return const SizedBox(
          height: 300,
          child: Center(child: Icon(Icons.broken_image, size: 50)),
        );
      }

      final aspectRatio = snapshot.data!.width / snapshot.data!.height;

      return AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image));
          },
        ),
      );
    },
  );
}

Future<Size> getImageSize(String url) async {
  final Completer<Size> completer = Completer();
  final Image image = Image.network(url);
  image.image.resolve(const ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      final size = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      completer.complete(size);
    }),
  );
  return completer.future;
}

// 取得 GitHub 優先顯示的圖片 URL（若存在）
Future<String?> getPreferredImageUrl(String dropboxUrl) async {
  final filename = Uri.parse(dropboxUrl).pathSegments.last;
  final githubUrl = 'https://ct01795.github.io/MomWhereGo-web/dropbox_files/$filename';

  try {
    final response = await http.head(Uri.parse(githubUrl));
    if (response.statusCode == 200) {
      return githubUrl; // GitHub 上的圖存在
    }
  } catch (_) {
    // ignore error, fallback to dropbox
  }

  return null; // fallback to Dropbox 圖片
}