import 'dart:js_interop';

@JS('alarmAudio.init')
external JSBoolean _initAlarmAudio();

@JS('alarmAudio.play')
external void _playAlarmAudio();

@JS('alarmAudio.vibrate')
external void _vibrateAlarm();

class AlarmAudioService {
  const AlarmAudioService();

  bool activate() {
    return _initAlarmAudio().toDart;
  }

  void playAlarm() {
    _initAlarmAudio();
    _playAlarmAudio();
    _vibrateAlarm();
  }
}
