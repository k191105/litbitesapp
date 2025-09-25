import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../quote.dart';

Future<void> shareQuoteAsImage(
  BuildContext context,
  Quote quote,
  bool isDarkMode,
) async {
  final screenshotController = ScreenshotController();

  final image = await screenshotController.captureFromWidget(
    _buildSharableQuoteCard(quote, isDarkMode),
    pixelRatio: MediaQuery.of(context).devicePixelRatio,
    context: context,
  );

  final directory = await getApplicationDocumentsDirectory();
  final imagePath = await File('${directory.path}/quote.png').create();
  await imagePath.writeAsBytes(image);

  await Share.shareXFiles([XFile(imagePath.path)]);
}

Widget _buildSharableQuoteCard(Quote quote, bool isDarkMode) {
  return Material(
    color: isDarkMode ? Colors.black : const Color.fromARGB(255, 240, 234, 225),
    child: Container(
      padding: const EdgeInsets.all(32.0),
      child: _buildQuoteCard(quote, isDarkMode),
    ),
  );
}

Widget _buildQuoteCard(Quote quote, bool isDarkMode) {
  // This is a simplified version of the quote card for sharing.
  // It's not interactive, so we don't need all the callbacks.
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Text(
        quote.text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          fontFamily: "EBGaramond",
          color: isDarkMode ? Colors.white : Colors.black,
          height: 1.4,
        ),
        textAlign: TextAlign.left,
      ),
      const SizedBox(height: 20.0),
      Text(
        '— ${quote.authorInfo}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          color: const Color.fromARGB(255, 166, 165, 165),
          fontFamily: "EBGaramond",
        ),
        textAlign: TextAlign.right,
      ),
      if (quote.displaySource.isNotEmpty) ...[
        const SizedBox(height: 8.0),
        Text(
          quote.displaySource,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: const Color.fromARGB(255, 140, 140, 140),
            fontFamily: "EBGaramond",
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    ],
  );
}
