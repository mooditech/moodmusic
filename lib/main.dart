import 'package:flutter/material.dart';
import 'package:moodi_music/pages/music_library.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //showPerformanceOverlay: true,
      checkerboardRasterCacheImages: true,
      title: "Mood Music",
      theme: ThemeData(
          primarySwatch: Colors.lightBlue
      ),
      home: MusicLibrary(),
    );
  }
}


