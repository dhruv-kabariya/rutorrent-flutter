import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VlcStream extends StatefulWidget {
  final String streamUrl;
  final String playingMediaName;

  VlcStream(this.streamUrl, this.playingMediaName);
  @override
  _VlcStreamState createState() => _VlcStreamState();
}

class _VlcStreamState extends State<VlcStream> {
  // state of media player while playing
  bool isPlaying = true;

  // controller of vlc player
  VlcPlayerController _videoViewController;

  // slider value for media player seek slider
  double sliderValue = 0.0;

  // hide control buttons {play/pause and seek slider} while playing media
  bool showControls = true;

  _initVlcPlayer() async {
    _videoViewController = new VlcPlayerController(onInit: () {
      _videoViewController.play();
    });
    _videoViewController.addListener(() {
      setState(() {});
    });

    int stopCounter = 0;
    bool checkForError = true;
    while (this.mounted) {
      PlayingState state = _videoViewController.playingState;
      if (state == PlayingState.PLAYING &&
          sliderValue < _videoViewController.duration.inSeconds) {
        checkForError=false;
        sliderValue = _videoViewController.position.inSeconds.toDouble();
      }
      else if (state==PlayingState.STOPPED){
        stopCounter++;
        if(checkForError && stopCounter>2){
          Fluttertoast.showToast(msg: 'Error in playing file');
          Navigator.pop(context);
        }
      }
      setState(() {});
      await Future.delayed(Duration(seconds: 1), () {});
    }
  }

  playOrPauseVideo() {
    PlayingState state = _videoViewController.playingState;

    if (state == PlayingState.PLAYING) {
      _videoViewController.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      _videoViewController.play();
      setState(() {
        isPlaying = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initVlcPlayer();
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: VlcPlayer(
              aspectRatio: 16 / 9,
              url: widget.streamUrl,
              controller: _videoViewController,
              placeholder: Container(
                height: 250.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).accentColor),
                ),
              ),
            ),
          ),

          showControls
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => showControls = !showControls);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          SizedBox(
                            height: 20,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 8),
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.playingMediaName,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: IconButton(
                                color: Colors.black,
                                iconSize: 40,
                                icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow),
                                onPressed: () => playOrPauseVideo()),
                          ),
                          Slider(
                            inactiveColor: Colors.grey,
                            activeColor: Colors.white,
                            value: sliderValue,
                            min: 0.0,
                            max: _videoViewController.duration == null
                                ? 1.0
                                : _videoViewController.duration.inSeconds
                                    .toDouble(),
                            onChanged: (progress) {
                              setState(() {
                                sliderValue = progress.floor().toDouble();
                              });
                              //convert to Milliseconds since VLC requires MS to set time
                              _videoViewController
                                  .setTime(sliderValue.toInt() * 1000);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => showControls = !showControls);
                  },
                  child: SizedBox(
                    height: double.infinity,
                    width: double.infinity,
                  ))
        ],
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }
}
