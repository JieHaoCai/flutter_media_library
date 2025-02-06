import 'dart:async';
import 'dart:io';

import 'package:video_player/video_player.dart';

class FlutterVideoPlayer {
  static final FlutterVideoPlayer _instance = FlutterVideoPlayer._internal();

  factory FlutterVideoPlayer() {
    return _instance;
  }

  FlutterVideoPlayer._internal();

  late VideoPlayerController videoPlayerController;

  final StreamController<bool> _playerStateController =
      StreamController.broadcast();
  Stream<bool> get playerStateStream => _playerStateController.stream;

  final StreamController<Duration> _playerDurationController =
      StreamController.broadcast();
  Stream<Duration> get playerDurationStream => _playerDurationController.stream;

  bool _isInitialized = false;

  // 初始化
  Future<void> init(String url,
      {VideoSourceType videoSourceType = VideoSourceType.networkUrl,
      String? package}) async {
    if (_isInitialized) {
      await dispose(); // 释放之前的实例
    }

    switch (videoSourceType) {
      case VideoSourceType.networkUrl:
        videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(url));
        break;
      case VideoSourceType.asset:
        videoPlayerController =
            VideoPlayerController.asset(url, package: package);
        break;
      case VideoSourceType.file:
        videoPlayerController = VideoPlayerController.file(File(url));
        break;
    }

    await videoPlayerController.initialize();
    videoPlayerController.addListener(_videoListener);
    _isInitialized = true;
  }

  void _videoListener() {
    // 播放状态监听
    _playerStateController.add(videoPlayerController.value.isPlaying);
    // 播放进度监听
    _playerDurationController.add(videoPlayerController.value.position);
  }

  // 播放
  Future<void> play() async {
    if (_isInitialized) {
      await videoPlayerController.play();
    } else {
      print("videoPlayerController is not initialized");
    }
  }

  // 暂停
  Future<void> pause() async {
    if (_isInitialized) {
      await videoPlayerController.pause();
    } else {
      print("videoPlayerController is not initialized");
    }
  }

  // 跳转到指定时长
  Future<void> seekTo(Duration position) async {
    if (_isInitialized) {
      await videoPlayerController.seekTo(position);
    } else {
      print("videoPlayerController is not initialized");
    }
  }

  // 获取总时长
  Duration getDuration() {
    if (_isInitialized) {
      return videoPlayerController.value.duration;
    }
    return Duration.zero;
  }

  // 销毁
  Future<void> dispose() async {
    if (_isInitialized) {
      await videoPlayerController.dispose();
      _playerDurationController.close();
      _playerStateController.close();
      _isInitialized = false;
    }
  }
}

enum VideoSourceType {
  networkUrl, // 网络资源
  asset, // 本地资源
  file, // 文件
}
