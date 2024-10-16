import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceNotesPage extends StatefulWidget {
  const VoiceNotesPage({super.key});

  @override
  State<VoiceNotesPage> createState() => _VoiceNotesPageState();
}

class _VoiceNotesPageState extends State<VoiceNotesPage> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _voiceNote = "";
  List<String> _savedNotes = [];

  @override
  void initState() {
    super.initState();
    initSpeech();
    initTTS();
    _loadNotes();
  }

  Future<void> initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedNotes = prefs.getStringList('voice_notes') ?? [];
    });
  }

  Future<void> _saveNote() async {
    if (_voiceNote.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _savedNotes.add(_voiceNote);
        _voiceNote = ""; // Clear the text field after saving
      });
      await prefs.setStringList('voice_notes', _savedNotes);
    }
  }

  Future<void> _playNoteAtIndex(int index) async {
    await _flutterTts.speak(_savedNotes[index]);
  }

  void _toggleListening(bool value) async {
    if (value) {
      if (_speechEnabled) {
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _voiceNote = result.recognizedWords;
            });
          },
          listenFor: const Duration(days: 1), // Continuous listening
          cancelOnError: true,
        );
        setState(() {
          _isListening = true;
        });
      }
    } else {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _deleteNoteAtIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedNotes.removeAt(index);
    });
    await prefs.setStringList('voice_notes', _savedNotes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _savedNotes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_savedNotes[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            _playNoteAtIndex(index); // Play the specific note
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteNoteAtIndex(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Enter your voice note',
                    ),
                    controller: TextEditingController(text: _voiceNote),
                    onChanged: (value) {
                      setState(() {
                        _voiceNote = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60, // Same height for consistency
                    child: ElevatedButton(
                      onPressed: _saveNote,
                      child: const Text('Save Note'),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Transform.scale(
                  scale: 1.5, // Increase the size of the switch
                  child: Switch(
                    value: _isListening,
                    onChanged: _toggleListening,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
