import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_media_library/flutter_media_library.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: Scaffold(
        body: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final videoPlayer = FlutterVideoPlayer(); //视频相关
  ValueNotifier<bool> video_is_playing = ValueNotifier(false); //视频播放状态
  ValueNotifier<int> video_playDuration = ValueNotifier(0); //视频播放状态
  int video_duration = 0; //视频总时长

  final FlutterAudioPlayer audioPlayer = FlutterAudioPlayer(); //音频相关
  //播放状态监听
  StreamSubscription? playStateSubscription; //播放状态监听
  StreamSubscription? processSubscription; //播放进度监听
  StreamSubscription? durationSubscription; //播放总时长进度监听
  ValueNotifier<bool> isPlayingVoice = ValueNotifier(false); //当前是否在播放声音
  int audio_duration = 0; //播放总时长
  ValueNotifier<int> audio_playDuration = ValueNotifier(0); //播放时长
  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    // _initializeAudioPlayer();
  }

  //初始化视频播放器
  Future<void> _initializeVideoPlayer() async {
    await videoPlayer.init("https://vjs.zencdn.net/v/oceans.mp4",
        videoSourceType: VideoSourceType.networkUrl);
    setState(() {
      //播放视频
      videoPlayer.play();
      //获取总时长
      video_duration = videoPlayer.getDuration().inMilliseconds;
    });
    //监听播放状态
    videoPlayer.playerStateStream.listen((isplaying) {
      video_is_playing.value = isplaying;
    });
    //监听播放进度
    videoPlayer.playerDurationStream.listen((duration) {
      video_playDuration.value = duration.inMilliseconds;
    }); // 更新 UI，确保视频播放器正确初始化
  }

  //初始化音频播放器
  Future<void> _initializeAudioPlayer() async {
    audioPlayer.init();
    //播放状态监听
    playStateSubscription =
        audioPlayer.playingStateStream.listen((event) async {
      Duration duration = await audioPlayer.getAudioDuration();
      if (!event && duration.inMilliseconds > 0) {
        isPlayingVoice.value = false;
      }
    });
    //获取当前播放进度
    processSubscription = audioPlayer.positonStream.listen((event) {
      audio_playDuration.value = event;
    });
    //获取总时长
    durationSubscription = audioPlayer.durationStateStream.listen((event) {
      audio_duration = audioPlayer.totalInMilliseconds;
    });
  }

  //播放音频
  void playAudio(String audioPath) async {
    await audioPlayer.stop();
    await audioPlayer.addPlayPkgSources(audioPath);
    await audioPlayer.play();
  }

  //暂停音频
  void pauseAudio() async {
    await audioPlayer.pause();
  }

  //停止音频
  void stopAudio() async {
    await audioPlayer.stop();
  }

  //设置当前播放进度
  void setPlayPosition(int milliseconds) async {
    await videoPlayer.videoPlayerController
        .seekTo(Duration(milliseconds: milliseconds));
    videoPlayer.videoPlayerController.play();
  }

  //实时监听时长变化
  void setCurrentDuration(int milliseconds) async {
    await videoPlayer.videoPlayerController.pause();
    video_playDuration.value = milliseconds;
  }

  String formatMilliseconds(int totalInMilliseconds) {
    // 计算分钟数和秒数
    int minutes = (totalInMilliseconds / (1000 * 60)).floor();
    int seconds = ((totalInMilliseconds / 1000) % 60).floor();

    // 格式化分钟和秒，确保显示两位数字
    String minutesStr = (minutes < 10) ? '0$minutes' : '$minutes';
    String secondsStr = (seconds < 10) ? '0$seconds' : '$seconds';

    // 返回格式化后的时间字符串
    return '$minutesStr:$secondsStr';
  }

  @override
  void dispose() {
    //销毁
    videoPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            const Text(
              "视频播放使用示例",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            videoWidget(),
            Container(
              height: 40,
              child: _progressWidget(context),
            )
          ],
        ),
      ),
    );
  }

  //视频容器示例
  Widget videoWidget() {
    double gap = 44 / 375 * MediaQuery.of(context).size.width;
    double videoWidth = MediaQuery.of(context).size.width - gap - gap;
    double videoHeight =
        videoWidth / videoPlayer.videoPlayerController.value.aspectRatio;
    return ValueListenableBuilder(
        valueListenable: video_is_playing,
        builder: (context, value, child) {
          return GestureDetector(
            onTap: () {
              if (!value) {
                videoPlayer.play();
              } else {
                videoPlayer.pause();
              }
            },
            child: videoPlayer.videoPlayerController.value.isInitialized
                ? Container(
                    width: MediaQuery.of(context).size.width - gap - gap,
                    // height: 512 / 812 * Get.height,
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xffffffff).withOpacity(0.15)),
                      child: Stack(
                        children: [
                          FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                  width: videoWidth,
                                  height: videoHeight,
                                  child: AspectRatio(
                                    aspectRatio: videoPlayer
                                        .videoPlayerController
                                        .value
                                        .aspectRatio,
                                    child: VideoPlayer(
                                        videoPlayer.videoPlayerController),
                                  ))),
                          !value
                              ? Container(
                                  height: videoHeight,
                                  child: const Center(
                                    child: Icon(Icons.play_arrow,
                                        size: 50, color: Colors.white),
                                  ),
                                )
                              : const SizedBox()
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),
          );
        });
  }

  //进度条示例
  Widget _progressWidget(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 30,
      padding: const EdgeInsets.only(left: 28, right: 28),
      child: Column(
        children: [
          const Expanded(child: SizedBox()),
          ValueListenableBuilder(
              valueListenable: video_playDuration,
              builder: (context, fvalue, child) {
                return Container(
                  child: Row(children: [
                    Text(
                      formatMilliseconds(fvalue),
                      style: const TextStyle(
                          color: Color(0xffffffff),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SliderTheme(
                              data: const SliderThemeData(
                                thumbColor: Colors.white,
                                // 设置滑动小球的颜色为白色
                                thumbShape: RoundSliderThumbShape(
                                  pressedElevation: 10.0,
                                  enabledThumbRadius: 6.0, // 设置滑动小球的半径
                                  disabledThumbRadius: 6.0, // 设置禁用状态下滑动小球的半径
                                ),
                                overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: 1.0 + 9.0, // 设置滑动小球外围圆形的半径
                                ),
                                overlayColor: Color(0xff2355f6),
                                // 设置滑动小球外围圆形的颜色为蓝色并设置透明度
                                trackHeight: 2,
                                // 设置轨道高度
                                trackShape: RoundedRectSliderTrackShape(),
                                // 设置轨道形状
                                activeTrackColor: Color(0xff2355f6),
                                // 设置激活状态下轨道的颜色
                                inactiveTrackColor:
                                    Color(0xffcccccc), // 设置非激活状态下轨道的颜色
                              ),
                              child: Slider(
                                  min: 0.0,
                                  max: video_duration / 100,
                                  value: fvalue < 0 ? 0.0 : fvalue / 100,
                                  onChangeStart: (value) {
                                    // isSlidering = true;
                                  },
                                  onChanged: (avalue) {
                                    setCurrentDuration((avalue * 100).toInt());
                                  },
                                  onChangeEnd: (value) {
                                    setPlayPosition((value * 100).toInt());
                                  }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      formatMilliseconds(video_duration),
                      style: const TextStyle(
                          color: Color(0xffffffff),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    )
                  ]),
                );
              }),
          const SizedBox(
            height: 14,
          )
        ],
      ),
    );
  }
}
