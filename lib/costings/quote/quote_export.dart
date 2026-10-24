import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the quote behind [boundaryKey] to PNG and hands it to the share
/// sheet or the gallery.
abstract final class QuoteExport {
  static const _pixelRatio = 3.0;

  static Future<Uint8List> capture(GlobalKey boundaryKey) async {
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    try {
      // PNG encoding runs on the engine's worker threads, not the UI thread.
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static Future<void> share(
    Uint8List png, {
    required String fileName,
    required String text,
    Rect? origin,
  }) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName.png';
    // Writing a multi-megabyte file is moved off the UI isolate so the
    // share button's animation never stutters.
    await Isolate.run(() => File(path).writeAsBytesSync(png, flush: true));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path, mimeType: 'image/png')],
      text: text,
      sharePositionOrigin: origin,
    ));
  }

  static Future<bool> saveToGallery(Uint8List png,
      {required String name}) async {
    final result = await ImageGallerySaverPlus.saveImage(
      png,
      quality: 100,
      name: name,
    );
    return result is Map && result['isSuccess'] == true;
  }

  /// A filesystem-safe name for the exported image.
  static String fileName(String sariName, int? designNo) {
    final base = sariName.trim().isEmpty ? 'costing' : sariName.trim();
    final safe = base.replaceAll(RegExp(r'[^\w઀-૿-]+'), '_');
    return designNo == null ? safe : '${safe}_$designNo';
  }
}
