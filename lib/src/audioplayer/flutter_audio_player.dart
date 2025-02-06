import 'dart:async';

import 'package:media_kit/media_kit.dart';

class FlutterAudioPlayer {
  late Player _player;

  //监听播放器是否正在播放
  StreamSubscription? _playingSubscription;

  //监听播放器播放进度
  StreamSubscription? _playerDurationSubscription;

  StreamSubscription? _durationSubscription;

  final StreamController<bool> _playingStateStreamVC =
      StreamController.broadcast();

  Stream<bool> get playingStateStream => _playingStateStreamVC.stream;

  final StreamController<int> _positonStreamVC = StreamController.broadcast();

  Stream<int> get positonStream => _positonStreamVC.stream;

  final StreamController<Duration> _durationStateStreamVC =
      StreamController.broadcast();

  Stream<Duration> get durationStateStream => _durationStateStreamVC.stream;

  int totalInMilliseconds = 0;

  void init() {
    _player = Player();
    _addAudioListen();
  }

  Future<void> play() async {
    _playingStateStreamVC.add(true);
    return _player.play();
  }

  Future<void> stop() async {
    return _player.stop();
  }

  Future<void> pause() async {
    return _player.pause();
  }

  Future<void> open(Media media, {String? package, bool play = true}) async {
    if (play) {
      _playingStateStreamVC.add(true);
    }
    return await _player.open(media, play: play);
  }

  Future<void> addPlayPkgSources(String sources, {String? package}) {
    return _player.open(Media(sources), play: false);
  }

  Future<Duration> getAudioDuration() async {
    return _player.state.duration;
  }

  void dispose() {
    _playingSubscription?.cancel();
    _playerDurationSubscription?.cancel();
    _durationSubscription?.cancel();
    _player.dispose();
  }

  void _addAudioListen() {
    _playingSubscription = _player.stream.playing.listen((event) {
      _playingStateStreamVC.add(event);
    });

    _durationSubscription = _player.stream.duration.listen((event) {
      _durationStateStreamVC.add(event);
      totalInMilliseconds = event.inMilliseconds;
    });

    _playerDurationSubscription = _player.stream.position.listen((event) {
      int inMilliseconds = event.inMilliseconds;
      if (inMilliseconds < totalInMilliseconds) {
        _positonStreamVC.add(inMilliseconds);
      } else {
        _positonStreamVC.add(totalInMilliseconds);
      }
      if ((totalInMilliseconds > 0 &&
          (totalInMilliseconds - inMilliseconds).abs() < 0.001)) {
        _playingStateStreamVC.add(false);
      }
    });
  }

  Future<void> setPlayPosition(int position) {
    _playingStateStreamVC.add(true);
    return _player.seek(Duration(milliseconds: position));
  }

  Future<Duration?> addPlaySources(String sources, {String? package}) async {
    Duration? duration;

    await _player.open(Media(sources), play: false);
    if (duration != null) {
      totalInMilliseconds = duration.inMilliseconds;
    }
    return duration;
  }
}
