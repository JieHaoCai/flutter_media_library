import 'dart:async';

import 'package:flutter_media_library/src/record/flutter_record.dart';

typedef void RecordingTimeChangeCallback(int recordTime);

class FlutterRecordHandler {
  Recorder _record = Recorder();
  Completer<Map<String, dynamic>>? _completer;

  StreamSubscription? _stateStreamSubscription;
  StreamSubscription? _timeStreamSubscription;
  StreamSubscription? _compleStreamSubscription;

  RecordingTimeChangeCallback? _timeChangeCallback;

  Map<String, dynamic> responseData = {};

  bool _isAddListen = false;
  int _recordDuration = 0;
  bool _isCallBack = false;

  void _addListen() {
    _isAddListen = true;
    _timeStreamSubscription =
        _record.recordTimeChangeController.stream.listen((event) {
      _recordDuration = event;
      _timeChangeCallback?.call(_recordDuration);
    });
    _compleStreamSubscription =
        _record.recordCompleController.stream.listen((event) async {
      if (_isCallBack) return;
      _isCallBack = true;
      _timeChangeCallback = null;
      _removeListen();
      if (event != null) {
        try {
          responseData["code"] = 0;
          responseData["msg"] = "success";
          responseData["data"]["fileStr"] = event;
          responseData["data"]["duration"] = _recordDuration;
        } catch (e) {
          responseData["code"] = -1;
          responseData["msg"] = e.toString();
        }
      } else {
        responseData["code"] = -1;
        responseData["msg"] = "录音失败";
      }
      _completer?.complete(responseData);
    });
  }

  void _removeListen() {
    if (!_isAddListen) return;
    _isAddListen = false;
    _stateStreamSubscription?.cancel();
    _timeStreamSubscription?.cancel();
    _compleStreamSubscription?.cancel();
  }

  //是否有录音权限
  Future<bool> hasPermission() {
    return _record.checkPermission();
  }

  /*开始录制
  id 标识本次录音的唯一标识码，返回时会原样返回
  maxTime 最大录制时长(秒) -1的话为不限制
  ext 扩展数据，返回时会原样返回

  回调如下 
  {
    "code":0,
    "msg":"",
    "data":{
      "id":id,
      "ext":ext,
      "fileStr":"base64之的值",
      "duration":录制的时长
    }
  */
  Future<Map<String, dynamic>> startRecord(String id,
      {int maxTime = 60,
      dynamic ext,
      RecordingTimeChangeCallback? timeChangeCallback}) {
    _removeListen();
    _addListen();
    _timeChangeCallback = timeChangeCallback;
    _recordDuration = 0;
    responseData.clear();
    responseData["data"] = {"id": id, "ext": ext};
    _completer = Completer();
    _isCallBack = false;
    try {
      _record.start(maxTime: maxTime);
    } catch (e) {
      if (!_isCallBack) {
        responseData["code"] = -1;
        responseData["msg"] = e.toString();
        _isCallBack = true;
        _completer?.complete(responseData);
      }
    }
    return _completer!.future;
  }

  //暂停录音
  Future<void> pasue() async {
    _record.pause();
    return;
  }

  //恢复录音
  Future<void> resume() async {
    _record.resume();
    return;
  }

  //停止录音
  Future<void> stop() async {
    return _record.stop();
  }

  //销毁
  void dispose() {
    try {
      _removeListen();
      _record.destoryRecord();
      _timeChangeCallback = null;
    } catch (e) {}
  }
}
