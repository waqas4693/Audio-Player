import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class MusicPlayer extends StatefulWidget {
  SongInfo songInfo;
  Function changeTrack;
  final GlobalKey<MusicPlayerState> key;
  MusicPlayer({this.songInfo, this.changeTrack, this.key}) : super(key: key);
  MusicPlayerState createState() => MusicPlayerState();
}

class MusicPlayerState extends State<MusicPlayer> {
  double minimumValue = 0.0, maximumValue = 0.0, currentValue = 0.0;
  String currentTime = '', endTime = '';
  bool isPlaying = false;
  final AudioPlayer player = AudioPlayer();

  void initState() {
    super.initState();
    setSong(widget.songInfo);
  }

  void dispose() {
    super.dispose();
    player?.dispose();
  }

  void setSong(SongInfo songInfo) async {
    widget.songInfo = songInfo;
    await player.setUrl(widget.songInfo.uri);
    currentValue = minimumValue;
    maximumValue = player.duration.inMilliseconds.toDouble();

    setState(() {
      currentTime = getDuration(currentValue);
      endTime = getDuration(maximumValue);
    });
    isPlaying = false;

    changeStatus();

    player.positionStream.listen((duration) {
      currentValue = duration.inMilliseconds.toDouble();
      setState(() {
        currentTime = getDuration(currentValue);
      });
    });
  }

  void changeStatus() {
    setState(() {
      isPlaying = !isPlaying;
    });
    if (isPlaying) {
      player.play();
    } else {
      player.pause();
    }
  }

  String percentageModifier(double value) {
    value = value / maximumValue * 100;

    final roundedValue = value.ceil().toInt().toString();
    return '$roundedValue %';
  }

  String getDuration(double value) {
    Duration duration = Duration(milliseconds: value.round());
    return [duration.inMinutes, duration.inSeconds].map((element) => element.remainder(60).toString().padLeft(2, '0')).join(':');
  }

  Widget build(context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xffffffff),
                const Color(0xffE0F3ED),
                const Color(0xffE1F1EE),
                const Color(0xffE1F1EE),
                const Color(0xffE1F1EE),
              ],
            ),
          ),
          margin: EdgeInsets.fromLTRB(5, 25, 5, 0),
          child: Column(children: <Widget>[
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.arrow_back_ios_sharp, color: Colors.black)),
                Column(
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: Text(
                        widget.songInfo.title,
                        style: TextStyle(color: Colors.black, fontSize: 14.0, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 33),
                      child: Text(
                        widget.songInfo.artist,
                        style: TextStyle(color: Colors.grey, fontSize: 12.0, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    backgroundImage: widget.songInfo.albumArtwork == null
                        ? AssetImage('assets/images/music_gradient.jpg')
                        : FileImage(File(widget.songInfo.albumArtwork)),
                    radius: 95,
                  ),
                ),
                SleekCircularSlider(
                  min: minimumValue,
                  max: maximumValue,
                  initialValue: currentValue,
                  appearance: CircularSliderAppearance(
                      angleRange: 360,
                      size: 200,
                      customColors: CustomSliderColors(
                          dotColor: Colors.amber, shadowMaxOpacity: 1, shadowColor: Colors.amber, progressBarColor: Colors.amber),
                      customWidths: CustomSliderWidths(progressBarWidth: 5, handlerSize: 10, trackWidth: null),
                      infoProperties: InfoProperties(modifier: percentageModifier)),
                  onChange: (double value) {
                    currentValue = value;
                    if (currentValue >= maximumValue) {
                      widget.changeTrack(true);
                    }
                    player.seek(Duration(milliseconds: currentValue.round()));
                  },
                  onChangeStart: (double startValue) {
                    // callback providing a starting value (when a pan gesture starts)
                  },
                  onChangeEnd: (double endValue) {},
                  innerWidget: (double value) {
                    return null;
                  },
                ),
              ],
            ),
//          Slider(
//            inactiveColor: Colors.black12,
//            activeColor: Colors.black,
//            min: minimumValue,
//            max: maximumValue,
//            value: currentValue,
//            onChanged: (value) {
//              currentValue = value;
//              player.seek(Duration(milliseconds: currentValue.round()));
//            },
//          ),

            Container(
              transform: Matrix4.translationValues(0, -15, 0),
              margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currentTime, style: TextStyle(color: Colors.grey, fontSize: 12.5, fontWeight: FontWeight.w500)),
                  Text(endTime, style: TextStyle(color: Colors.grey, fontSize: 12.5, fontWeight: FontWeight.w500))
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    child: Icon(Icons.skip_previous, color: Colors.black, size: 55),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      widget.changeTrack(false);
                    },
                  ),

                  GestureDetector(
                    child: Container(height: 40, width: 40, child: new Image.asset("assets/icons/skip15secback.png")),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() {
                        player.seek(Duration(seconds: player.position.inSeconds - 15));
                      });
                    },
                  ),

                  GestureDetector(
                    child: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: Colors.black, size: 85),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      changeStatus();
                    },
                  ),

                  GestureDetector(
                    child: Container(height: 40, width: 40, child: new Image.asset("assets/icons/skip15secforward.png")),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() {
                        player.seek(Duration(seconds: player.position.inSeconds + 15));
                      });
                    },
                  ),

                  GestureDetector(
                    child: Icon(Icons.skip_next, color: Colors.black, size: 55),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      widget.changeTrack(true);
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
