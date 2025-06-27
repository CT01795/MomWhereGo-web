import 'dart:async';

import 'package:flutter/material.dart';

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