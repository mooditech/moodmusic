import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:moodi_music/utils/songs.dart';

enum PlayerState { stopped, playing, paused }

class PlaybackScreen extends StatefulWidget {

  final int trackIndex;
  final Playlist playlist;

  PlaybackScreen({
    @required this.trackIndex,
    @required this.playlist
  });

  @override
  PlaybackScreenState createState() => PlaybackScreenState();
}

class PlaybackScreenState extends State<PlaybackScreen>
    with SingleTickerProviderStateMixin {
  AudioPlayer player;
  AnimationController _animationController;
  Duration duration;
  Duration position;
  double imageHeight;
  PageController _pageController;
  PlayerState playerState = PlayerState.stopped;

  get isPaused => playerState == PlayerState.paused;

  get isPlaying => playerState == PlayerState.playing;
  static int playlistIndex;

  @override
  void initState() {
    super.initState();
    initAnimate();
    initPlayer();
    playlistIndex = widget.trackIndex;
    initPageController();
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
    _pageController.dispose();
  }

  Future initPlayer() async {
    if (player == null) {
      player = new AudioPlayer();
    }

    player.durationHandler = (Duration d) => setState(() => duration = d);
    player.positionHandler = (Duration p) => setState(() => position = p);

    player.completionHandler = () {
      onComplete();
      setState(() => position = duration);
    };

    player.errorHandler = (msg) {
      print("player error: :$msg");
      setState(() {
        playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    };
    play(widget.trackIndex);
  }

  initAnimate() {
    _animationController = new AnimationController(
        vsync: this,
        duration: new Duration(milliseconds: 500)
    );
  }

  initPageController() {
    _pageController = new PageController(
        initialPage: widget.trackIndex,
        viewportFraction: 1);
  }

  Future playPause() async {
    if (isPlaying) {
      await player.pause();
      _animationController.reverse();
      setState(() {
        playerState = PlayerState.paused;
      });
    } else {
      await player.resume();
      _animationController.forward();
      setState(() {
        playerState = PlayerState.playing;
      });
    }
  }

  Future play(int index) async {
    await player.play(widget.playlist
        .get(index)
        .trackPath, isLocal: true);
    _animationController.forward();
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future stop() async {
    await player.stop();
    setState(() {
      playerState = PlayerState.stopped;
      position = new Duration();
    });
  }

  onComplete() {
    player.stop();
    _pageController.nextPage(
        duration: Duration(
            milliseconds: 200),
        curve: Curves.linear);
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  forward10() => player.seek(position + Duration(seconds: 10));

  reverse10() {
    if (position.inSeconds < 10.0)
      player.seek(Duration(seconds: 0));
    else {
      player.seek(position - Duration(seconds: 10));
    }
  }

  next() {
    playlistIndex++;
    play(playlistIndex);
  }

  prev() {
    playlistIndex--;
    play(playlistIndex);
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    return MediaQuery(
      data: media,
      child: new Scaffold(
          body: Stack(
            children: <Widget>[
              new Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: widget.playlist
                              .get(playlistIndex)
                              .albumArt,
                          fit: BoxFit.fill
                      )
                  ),
                  child: new BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 20.0,
                        sigmaY: 20.0
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5)),
                      child: new Column(
                        children: <Widget>[
                          AspectRatio(
                            aspectRatio: 1.0 / 1.0,
                            child: Container(
                              width: media.size.width,
                              child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (int idx) {
                                    print("index: $idx");
                                    print("page: ${_pageController.page}");
                                    if (idx < _pageController.page)
                                      prev();
                                    else
                                      next();
                                  },
                                  itemCount: widget.playlist.length(),
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: media.padding.add(
                                          EdgeInsets.all(40)),
                                      child: DecoratedBox(
                                        decoration: new BoxDecoration(
                                            image: DecorationImage(
                                              image: widget.playlist
                                                  .get(index)
                                                  .albumArt,
                                              fit: BoxFit.fill,
                                            ),
                                            boxShadow: [
                                              new BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(
                                                      0.5),
                                                  offset: new Offset(2.0, 2.0),
                                                  blurRadius: 5.0,
                                                  spreadRadius: 5.0)
                                            ]
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ),
                          new Expanded(
                            flex: 1,
                            child: Material(
                              color: Colors.transparent,
                              child: new Column(
                                children: <Widget>[
                                  Expanded(
                                    child: new Container(
                                      //padding: EdgeInsets.only(top: 30),
                                      width: double.infinity,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: RichText(
                                              textAlign: TextAlign.center,
                                              text: new TextSpan(
                                                  text: "",
                                                  children: [
                                                    new TextSpan(
                                                      text: "${widget.playlist
                                                          .get(playlistIndex)
                                                          .trackTitle}\n",
                                                      style: new TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18.0,
                                                        fontWeight: FontWeight
                                                            .normal,
                                                        letterSpacing: 4.0,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                    new TextSpan(
                                                        text: widget.playlist
                                                            .get(playlistIndex)
                                                            .trackArtist,
                                                        style: new TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(
                                                              0.75),
                                                          fontSize: 14.0,
                                                          fontWeight: FontWeight
                                                              .normal,
                                                          letterSpacing: 3.0,
                                                          height: 1.5,
                                                        ))
                                                  ])),
                                        ),
                                      ),
                                    ),
                                  ),
                                  new Expanded(
                                    child: new Container(
                                      width: double.infinity,
                                      child: new Row(
                                        children: <Widget>[
                                          new Expanded(
                                            child: new IconButton(
                                                icon: new Icon(
                                                  Icons.replay_10,
                                                  size: 40.0,
                                                  color: Colors.white
                                                      .withOpacity(
                                                      0.7),),
                                                onPressed: reverse10
                                            ),
                                          ),
                                          new Expanded(
                                            child: new IconButton(
                                                icon: new AnimatedIcon(
                                                  icon: AnimatedIcons
                                                      .play_pause,
                                                  progress: _animationController,
                                                  size: 40.0,
                                                  color: Colors.white,),
                                                onPressed: playPause
                                            ),
                                          ),
                                          new Expanded(
                                            child: new IconButton(
                                                icon: new Icon(
                                                  Icons.forward_10,
                                                  size: 40.0,
                                                  color: Colors.white
                                                      .withOpacity(
                                                      0.7),),
                                                onPressed: forward10
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  new Expanded(
                                    child: GestureDetector(
                                      onHorizontalDragUpdate: (
                                          DragUpdateDetails update) {
                                        if (update.delta.dx < -5) {
                                          _pageController.nextPage(
                                              duration: Duration(
                                                  milliseconds: 200),
                                              curve: Curves.linear);
                                          // playlistIndex++;
                                        }
                                        else if (update.delta.dx > 5) {
                                          _pageController.previousPage(
                                              duration: Duration(
                                                  milliseconds: 200),
                                              curve: Curves.linear);
                                          // playlistIndex--;
                                        }
                                      },
                                      // onHorizontalDragEnd: ,
                                      child: new Container(
                                        width: double.infinity,
                                        child: new DecoratedBox(
                                          decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                  0.05)),),
                                      ),
                                    ),
                                  ),
                                  new Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceEvenly,
                                      children: <Widget>[
                                        new Container(
                                          width: 45,
                                          padding: EdgeInsets.only(left: 8),
                                          child: new Text(
                                            position?.toString()?.substring(
                                                2, 7) ??
                                                "00.00",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),),
                                        ),
                                        Expanded(
                                          child: new Slider(
                                            value: position?.inMilliseconds
                                                ?.toDouble() ??
                                                00.00,
                                            onChanged: (double value) {
                                              player.seek(Duration(
                                                  seconds: (value ~/
                                                      1000)));
                                            },
                                            divisions: 200000,
                                            min: 0,
                                            max: duration?.inMilliseconds
                                                ?.toDouble() ??
                                                00.00,
                                            activeColor: Colors.white,
                                            inactiveColor: Colors.white
                                                .withOpacity(
                                                0.5),
                                          ),
                                        ),
                                        Container(
                                          width: 45,
                                          padding: EdgeInsets.only(right: 8),
                                          child: new Text(
                                            duration?.toString()?.substring(
                                                2, 7) ??
                                                "00.00",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),),
                                        ),
                                      ],
                                    ),
                                  ),
                                  new Expanded(
                                    child: new Container(
                                      width: double.infinity,
                                      child: new Row(
                                        children: <Widget>[
                                          new Expanded(
                                            child: new IconButton(
                                                icon: new Icon(
                                                  Icons.favorite_border,
                                                  size: 30.0,
                                                  color: Colors.white
                                                      .withOpacity(
                                                      0.7),),
                                                onPressed: () =>
                                                    print("fave")),
                                          ),
                                          new Container(width: 20,),
                                          new Expanded(
                                            child: new IconButton(
                                                icon: new Icon(
                                                  Icons.playlist_add,
                                                  size: 30.0,
                                                  color: Colors.white
                                                      .withOpacity(
                                                      0.7),),
                                                onPressed: () =>
                                                    print("add")),
                                          ),
                                          new Expanded(
                                              child: new Container()),
                                          new Expanded(
                                            child: new IconButton(
                                                icon: new Icon(
                                                  Icons.repeat, size: 30.0,
                                                  color: Colors.white
                                                      .withOpacity(
                                                      0.7),),
                                                onPressed: () =>
                                                    print("repeat")),
                                          ),
                                          new Container(width: 20,),
                                          new Expanded(
                                            child: new IconButton(
                                                icon: new Icon(
                                                  Icons.shuffle, size: 30.0,
                                                  color: Colors.white
                                                      .withOpacity(
                                                      0.7),),
                                                onPressed: () =>
                                                    print("shuffle")),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
              ),
              Positioned(
                top: 0.0,
                left: 0.0,
                right: 0.0,
                child: new AppBar(
                    elevation: 0.0,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                ),
              ),
            ],
          )


      ),
    );
  }
}
