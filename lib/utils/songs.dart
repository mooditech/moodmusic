import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class Track {
  final String trackPath;
  //final File trackFile;
  String trackArtist;
  String trackTitle;
  String albumTitle;
  String trackGenre;
  String trackNumber;
  String trackYear;
  ImageProvider albumArt;
  Track({
    @required this.trackPath,
  }) {
    //noArt.load("assets/images/No-album-art.png");
  }

}

class Playlist {
  static final List<Track> _playlist  = new List<Track>();
  add(Track track)=>_playlist.add(track);
  length()=> _playlist.length;

  get(int index){return _playlist.elementAt(index);}
  index(Track track)=>_playlist.indexOf(track);
}

