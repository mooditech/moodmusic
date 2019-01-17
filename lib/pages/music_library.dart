import 'dart:async';
import 'dart:io';

import 'package:audiometadata/audiometadata.dart';
import 'package:flutter/material.dart';
import 'package:moodi_music/utils/songs.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'play_screen.dart';

class MusicLibrary extends StatefulWidget {
  @override
  _MusicLibraryState createState() => _MusicLibraryState();
}

class _MusicLibraryState extends State<MusicLibrary> {

  Track track;
  Playlist playlist = new Playlist();
  final List<FileSystemEntity> files = List<FileSystemEntity>();
  Future<List> _metadata;
  Directory parent;
  Audiometadata audioMetadata = new Audiometadata();
  Image noArt = new Image.asset("assets/images/noart.jpg");

  Future<String> get localPath async {
    final dir = await getExternalStorageDirectory();
    return dir.path + "/Music/";
  }

  @override
  initState() {
    super.initState();
    initPermissions();
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
            addToLibrary();
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
    setState(() {});
    return metadata;
  }


  Future addToLibrary() async {
    for (var file in parent.listSync(recursive: true)) {
      if ((file is File) &&
          (file.path.endsWith(".mp3") || file.path.endsWith(".m4a"))) {
        final track = new Track(trackPath: file.path);
        _metadata = initMetadata(track.trackPath);
        _metadata.then((metadata) {
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
                .memory(metadata.elementAt(6))
                .image);
        });
        playlist.add(track);
      }
    }
    setState(() {});
  }

  navigateToPlay(int index) {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (context) =>
                PlaybackScreen(trackIndex: index, playlist: playlist,)));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return MaterialButton(
            onPressed: () =>
                navigateToPlay(index),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(3),
              child: new ListTile(
                title: new Text(
                  playlist
                      .get(index)
                      .trackTitle,
                ),
                leading: CircleAvatar(backgroundImage: playlist
                    .get(index)
                    .albumArt,),
                subtitle: new Text(playlist.get(index).trackArtist),
              ),
            ),
          );
        },
        itemCount: playlist.length(),
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
    );
  }
}


