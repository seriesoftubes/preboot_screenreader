import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  FlutterTts flutterTts;

  TextToSpeech() {
    flutterTts = FlutterTts();
  }

  Future speak(String ttsString) async {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.setLanguage("en-GB");
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(1.0);
    await flutterTts.isLanguageAvailable("en-GB");
    await flutterTts.speak(ttsString);
  }

  Future stop() async {
    await flutterTts.stop();
  }
}
