import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';

class PlayerWidget extends StatefulWidget {
  final String url;
  final Color color;

  const PlayerWidget({Key? key, required this.url, required this.color})
      : super(key: key);

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  final FlutterSoundPlayer _myPlayer = FlutterSoundPlayer(logLevel: Level.off);
  final StreamController<PlaybackDisposition> _localController =
      StreamController<PlaybackDisposition>.broadcast();
  final _sliderPosition = _SliderPosition();
  late Stream<PlaybackDisposition> playerStream;

  @override
  void initState() {
    super.initState();
    setupPlayer();
    playerStream = _localController.stream;
  }

  @override
  void dispose() {
    closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [_buildPlayPauseButton(), _buildPlayBar(), _buildDuration()],
    );
  }

  Widget _buildPlayPauseButton() => IconButton(
        key: const Key('play_button'),
        onPressed: () => buttonClick(),
        icon: Icon(_myPlayer.isPlaying
            ? Icons.pause_circle_outline
            : Icons.play_circle_outline),
        iconSize: 35,
        color: widget.color,
      );

  Widget _buildPlayBar() => Expanded(
        child: StreamBuilder<PlaybackDisposition>(
          stream: playerStream,
          initialData: PlaybackDisposition.zero(),
          builder: (context, snapshot) {
            var disposition = snapshot.data!;
            return SliderTheme(
              data: SliderThemeData(
                  trackShape: CustomTrackShape(),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  thumbColor: widget.color,
                  activeTrackColor: widget.color,
                  inactiveTrackColor: Colors.grey.shade400,
                  disabledThumbColor: widget.color),
              child: Slider(
                onChanged: (value) {
                  Duration position = Duration(milliseconds: value.toInt());
                  _sliderPosition.position = position;
                  if (_myPlayer.isPlaying || _myPlayer.isPaused) {
                    _myPlayer.seekToPlayer(position);
                  }
                },
                max: disposition.duration.inMilliseconds.toDouble(),
                value: disposition.position.inMilliseconds.toDouble(),
              ),
            );
          },
        ),
      );

  Widget _buildDuration() => StreamBuilder<PlaybackDisposition>(
      stream: playerStream,
      initialData: PlaybackDisposition.zero(),
      builder: (context, snapshot) {
        var disposition = snapshot.data!;
        var durationDate = DateTime.fromMillisecondsSinceEpoch(
            disposition.duration.inMilliseconds,
            isUtc: true);
        var positionDate = DateTime.fromMillisecondsSinceEpoch(
            disposition.position.inMilliseconds,
            isUtc: true);
        return Text(
          '${positionDate.minute.toString().padLeft(2, '0')}:${positionDate.second.toString().padLeft(2, '0')} / ${durationDate.minute.toString().padLeft(2, '0')}:${durationDate.second.toString().padLeft(2, '0')}',
          style: TextStyle(fontSize: 14.0, color: widget.color),
        );
      });

  /// Call [resume] to resume playing the audio.
  Future<void> resume() async =>
      await _myPlayer.resumePlayer().catchError((dynamic e) async {
        await _myPlayer.stopPlayer();
      });

  /// Call [pause] to pause playing the audio.
  Future<void> pause() async =>
      await _myPlayer.pausePlayer().catchError((dynamic e) async {
        await _myPlayer.stopPlayer();
      });

  Future<void> start() async => await _myPlayer.startPlayer(
      fromURI: widget.url,
      codec: Codec.defaultCodec,
      whenFinished: () {
        setState(() {
          // _sliderPosition.position = Duration(seconds: 0);
          _localController.add(PlaybackDisposition.zero());
        });
      });

  buttonClick() async {
    if (_myPlayer.isPaused) {
      debugPrint('_PlayerWidgetState.buttonClick isPaused');
      await resume();
    } else if (_myPlayer.isPlaying) {
      debugPrint('_PlayerWidgetState.buttonClick isPlaying');
      await pause();
    } else {
      debugPrint('_PlayerWidgetState.buttonClick starting');
      if (!_myPlayer.isOpen()) {
        await _myPlayer.openPlayer();
      }
      await start();
    }
    setState(() {});
  }

  setupPlayer() async {
    await Future.delayed(const Duration(seconds: 1), () async {
      await _myPlayer.openPlayer();
      _sliderPosition.position = const Duration(seconds: 0);
      _sliderPosition.maxPosition = const Duration(seconds: 0);
      _myPlayer.dispositionStream()!.listen(_localController.add);
      _myPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
    });
  }

  closePlayer() async {
    await _localController.close();
    await _myPlayer.closePlayer();
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 0.0;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 10;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

//
// ///
class _SliderPosition extends ChangeNotifier {
  /// The current position of the slider.
  Duration _position = Duration.zero;

  /// The max position of the slider.
  Duration maxPosition = Duration.zero;

  bool _disposed = false;

  ///
  set position(Duration position) {
    _position = position;

    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  ///
  Duration get position {
    return _position;
  }
}
