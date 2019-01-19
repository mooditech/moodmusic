import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audiometadata/audiometadata.dart';
import 'package:flutter/material.dart';
import 'package:moodi_music/utils/songs.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'play_screen.dart';

class MusicLibrary extends StatefulWidget {
  @override
  _MusicLibraryState createState() => _MusicLibraryState();
}

class _MusicLibraryState extends State<MusicLibrary>
    with TickerProviderStateMixin {

  Track track;
  Playlist playlist = new Playlist();
  static final List<FileSystemEntity> files = List<FileSystemEntity>();
  Future<List> _metadata;
  static Directory parent;
  TabController _tabController;
  final Audiometadata audioMetadata = new Audiometadata();
  final Image noArt = new Image.asset("assets/images/noart.jpg");
  ImageProvider musicBG = new Image.asset("assets/images/musicbg.jpg").image;
  PaletteGenerator paletteGenerator;
  int rand;

  Future<String> get localPath async {
    final dir = await getExternalStorageDirectory();
    return dir.path + "/Music/";
  }

  @override
  initState() {
    super.initState();
    initPermissions();
    initTabController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  initTabController() {
    _tabController = new TabController(length: 3, vsync: this);
  }

  Future initPermissions() async {
    // setState(() {
    if (parent == null) {
      SimplePermissions.requestPermission(Permission.WriteExternalStorage)
          .then((value) {
        if (value == PermissionStatus.authorized) {
          localPath.then((String value) {
            Directory dir = Directory(value);
            parent = dir;
            addToLibrary().whenComplete(() {
              rand = Random().nextInt(playlist.length());
              print("num: $rand");

              setState(() {
                musicBG = playlist
                    .get(rand)
                    .albumArt;
              });
            });
          });
        }
        else
          SimplePermissions.openSettings();
      });
    }
    // });
  }


  Future<List> initMetadata(String trackPath) async {
    List metadata;
    //("path: ${track.trackPath}");
    try {
      metadata = await audioMetadata.getMetadata(trackPath);
    } on Exception {
      metadata[0] = 'Failed to get metadata';
    }
    return metadata;
  }


  Future addToLibrary() async {
    for (var file in parent.listSync(recursive: true)) {
      if ((file is File) &&
          (file.path.endsWith(".mp3") || file.path.endsWith(".m4a"))) {
        final track = new Track(trackPath: file.path);
        _metadata = initMetadata(track.trackPath);
        await _metadata.then((metadata) {
          track.trackTitle = metadata?.elementAt(0) ??
              p.basenameWithoutExtension(track.trackPath);
          print(track.trackTitle);
          track.albumTitle =
              metadata?.elementAt(1) ?? "Unknown Album";
          track.trackArtist =
              metadata?.elementAt(2) ?? "Unknown Artist";
          track.trackGenre =
              metadata?.elementAt(3) ?? "No embedded genre information";
          track.trackNumber = metadata?.elementAt(4) ?? "NA";
          track.trackYear = metadata?.elementAt(5) ?? "NA";
          if (metadata.elementAt(6) == null)
            track.albumArt = noArt.image;
          else
            track.albumArt = (Image
                .memory(
                metadata.elementAt(6))
                .image);
        });
        playlist.add(track);
      }
    }
  }


  navigateToPlay(int index) {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (context) =>
                PlaybackScreen(trackIndex: index, playlist: playlist,)));
  }


  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    return MediaQuery(
      data: media,
      child: Scaffold(
        backgroundColor: Color(0xFFE1E2E1),
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              backgroundColor: Color(0xFFa6bfcc),
              expandedHeight: 300,
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                  background: Image(image: musicBG, fit: BoxFit.cover,)),
              bottom: TabBar(
                controller: _tabController,
                tabs: <Widget>[
                  IconButton(icon: Icon(Icons.music_note), onPressed: null),
                  IconButton(icon: Icon(Icons.person), onPressed: null),
                  IconButton(icon: Icon(Icons.album), onPressed: null)
                ],),
            ),
            SliverFixedExtentList(
              itemExtent: 95,
              delegate: SliverChildBuilderDelegate((BuildContext context,
                  int index) {
                return Card(
                  shape: BeveledRectangleBorder(),
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  elevation: 8,
                  child: MaterialButton(
                      onPressed: () =>
                          navigateToPlay(index),
                      child: new ListTile(
                        title: new Text(
                          playlist
                              .get(index)
                              .trackTitle,
                        ),
                        leading: SizedBox(
                            child: Container(decoration: BoxDecoration(
                                image: DecorationImage(image: playlist
                                    .get(index)
                                    .albumArt)),
                              width: 50,
                              height: 50,
                            )),
                        subtitle: new Text(playlist
                            .get(index)
                            .trackArtist),
                      )
                  ),
                );
              },
                childCount: playlist.length(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.library_music), title: Text("Library")),
            BottomNavigationBarItem(
                icon: Icon(Icons.music_note), title: Text("Now Playing")),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite), title: Text("Favorites")),
          ],
        ),
      ),
    );
  }
}


