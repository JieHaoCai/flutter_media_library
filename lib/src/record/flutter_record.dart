import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class Recorder {
  int _recordDuration = 0;
  Timer? _timer;
  late final AudioRecorder _audioRecorder;
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;
  int maxRecordTime = 60;

  StreamController<RecordState> recordStateController =
      StreamController.broadcast();

  StreamController<int> recordTimeChangeController =
      StreamController.broadcast();

  StreamController<String?> recordCompleController =
      StreamController.broadcast();

  AIAPPRecorder() {
    initRecord();
  }

  initRecord() {
    _audioRecorder = AudioRecorder();

    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      _amplitude = amp;
    });
  }

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<bool> checkPermission() async {
    if (!(await Permission.microphone.isGranted)) {
      PermissionStatus status = await Permission.microphone.request();
      if (status == PermissionStatus.permanentlyDenied) {
        openAppSettings();
        return false;
      }
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Future<void> start({int maxTime = 60}) async {
    if (maxTime <= 0) {
      maxRecordTime = 1000000;
    } else {
      maxRecordTime = maxTime;
    }
    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.wav;

        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          encoder,
        );

        debugPrint('${encoder.name} supported: $isSupported');

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        // const config = RecordConfig(encoder: encoder, sampleRate: 8000);
        const config = RecordConfig(encoder: encoder);

        // Record to file
        await recordFile(_audioRecorder, config);

        // Record to stream
        // await recordStream(_audioRecorder, config);

        _recordDuration = 0;

        _startTimer();
      } else {
        throw "请开启录音权限";
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      throw e;
    }
  }

  Future<void> stop() async {
    final path = await _audioRecorder.stop();

    recordCompleController.sink.add(path);
  }

  Future<void> pause() => _audioRecorder.pause();

  Future<void> resume() => _audioRecorder.resume();

  void _updateRecordState(RecordState recordState) {
    _recordState = recordState;
    recordStateController.sink.add(recordState);
    switch (recordState) {
      case RecordState.pause:
        _timer?.cancel();
        break;
      case RecordState.record:
        _startTimer();
        break;
      case RecordState.stop:
        _timer?.cancel();
        _recordDuration = 0;
        break;
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _recordDuration++;
      recordTimeChangeController.sink.add(_recordDuration);
      if (_recordDuration >= maxRecordTime) {
        stop();
      }
    });
  }

  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) async {
    final path = await _getPath();

    await recorder.start(config, path: path);
  }

  Future<void> recordStream(AudioRecorder recorder, RecordConfig config) async {
    final file = File(await _getPath());

    final stream = await recorder.startStream(config);

    stream.listen(
      (data) {
        // ignore: avoid_print
        print(
          recorder.convertBytesToInt16(Uint8List.fromList(data)),
        );
        file.writeAsBytesSync(data, mode: FileMode.append);
      },
      // ignore: avoid_print
      onDone: () => print('End of stream'),
    );
  }

  Future<String> _getPath() async {
    if (kIsWeb) {
      return Future.value('');
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
  }

  void destoryRecord() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    recordCompleController.close();
  }
}
