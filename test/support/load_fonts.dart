import 'package:flutter/services.dart';

Future<void> loadAppFonts() async {
  final loader = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto-Variable.ttf'));
  await loader.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('NotoSymbols')
        ..addFont(rootBundle.load('assets/fonts/NotoSansSymbols2-Regular.ttf')))
      .load();
}
