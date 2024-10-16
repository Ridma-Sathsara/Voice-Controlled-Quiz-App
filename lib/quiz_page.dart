import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'results_page.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _selectedOptionIndex = -1;
  int _score = 0;
  bool _answered = false;
  bool _isSpeaking = false;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    initTTS();
    initSpeech();
    _loadQuestions();
  }

  // Initialize Text-to-Speech
  Future<void> initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Initialize Speech-to-Text
  Future<void> initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final questions = (prefs.getStringList('questions') ?? []).map((q) {
      final parts = q.split('|');
      return Question(
        text: parts[0],
        options: parts.sublist(1, 5),
        correctOption: int.parse(parts[5]),
      );
    }).toList();

    setState(() {
      _questions = questions;
      if (_questions.isNotEmpty) {
        _readQuestion();
      }
    });
  }

  // Read the current question aloud
  Future<void> _readQuestion() async {
    if (_questions.isEmpty) return;
    final question = _questions[_currentQuestionIndex];
    await _speakText(question.text);
    await Future.delayed(const Duration(milliseconds: 500));
    _readOptions();
  }

  // Read all options aloud
  Future<void> _readOptions() async {
    if (_questions.isEmpty) return;
    final question = _questions[_currentQuestionIndex];
    for (int i = 0; i < question.options.length; i++) {
      await _speakText("Option ${i + 1} is ${question.options[i]}");
    }
    setState(() {
      _answered = false;
    });
  }

  // Speak the provided text
  Future<void> _speakText(String text) async {
    if (text.isNotEmpty) {
      setState(() {
        _isSpeaking = true;
      });
      await _flutterTts.speak(text);
      while (_isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  // Handle voice input
  void _startListening() async {
    if (_speechEnabled && !_isListening) {
      setState(() {
        _isListening = true;
      });

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: true,
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
      await _speechToText.stop();
    }
  }

  // Process the recognized speech result
  void _onSpeechResult(SpeechRecognitionResult result) {
    final userAnswer = result.recognizedWords.toLowerCase();
    print('Recognized Words: $userAnswer'); // Debugging line
    final question = _questions[_currentQuestionIndex];
    final options =
        question.options.map((option) => option.toLowerCase()).toList();

    // Convert common phrases to option index
    final optionIndex = _parseOption(userAnswer);
    if (optionIndex != null &&
        optionIndex >= 0 &&
        optionIndex < options.length) {
      _onOptionSelected(optionIndex);
    } else if (userAnswer.contains('next') ||
        userAnswer.contains('next question')) {
      // Ensure that the next question logic is correct
      _nextQuestion();
    } else if (userAnswer.contains('previous') ||
        userAnswer.contains('previous question')) {
      _previousQuestion();
    } else if (userAnswer.contains('repeat question')) {
      _replayQuestion(); // Replay the question
    } else if (userAnswer.contains('repeat option')) {
      // Check if the command includes a specific option number
      for (int i = 0; i < options.length; i++) {
        if (userAnswer.contains('repeat option ${i + 1}')) {
          _replayOption(i); // Replay the specific option
          return;
        }
      }
    } else {
      _flutterTts.speak("I did not recognize your command..");
    }
  }

  // Convert common answer phrases to option index
  int? _parseOption(String answer) {
    final optionMapping = {
      'option one': 0,
      'option two': 1,
      'option three': 2,
      'option four': 3,
    };

    final normalizedAnswer = answer.replaceAll(RegExp(r'\s+'), ' ').trim();

    return optionMapping[normalizedAnswer];
  }

  // Select option
  void _onOptionSelected(int index) {
    if (!_answered) {
      setState(() {
        _selectedOptionIndex = index;
        _answered = true;
        _isCorrect = index == _questions[_currentQuestionIndex].correctOption;
        if (_isCorrect) {
          _score++;
        }
      });
      _flutterTts.speak(_isCorrect ? "Correct" : "Incorrect Answer");
    }
  }

  // Move to next question
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = -1;
        _answered = false;
        _readQuestion();
      });
    } else {
      _flutterTts.speak("Quiz completed. Thank you for participating.");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResultsPage(score: _score, totalQuestions: _questions.length),
        ),
      );
    }
  }

  // Move to previous question
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedOptionIndex = -1;
        _answered = false;
        _readQuestion();
      });
    } else {
      _flutterTts.speak("This is the first question.");
    }
  }

  // Replay the current question
  void _replayQuestion() {
    if (_questions.isNotEmpty) {
      final question = _questions[_currentQuestionIndex];
      _speakText(question.text);
    }
  }

  // Replay a specific option
  void _replayOption(int index) {
    if (_questions.isNotEmpty && index >= 0 && index < 4) {
      final option = _questions[_currentQuestionIndex].options[index];
      _speakText("Option ${index + 1} is ${option}");
    }
  }

  // Check answer by button click
  void _checkAnswer() {
    if (_selectedOptionIndex != -1) {
      final question = _questions[_currentQuestionIndex];
      setState(() {
        _answered = true;
        _isCorrect = _selectedOptionIndex == question.correctOption;
        if (_isCorrect) {
          _score++;
        }
      });
      _flutterTts.speak(_isCorrect ? "Correct" : "Incorrect Answer");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadQuestions();
            },
          ),
        ],
      ),
      body: _questions.isEmpty
          ? Center(
              child: Text(
                'Loading questions...',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _questions[_currentQuestionIndex].text,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(
                    4,
                    (index) => RadioListTile<int>(
                      title: Text(
                        _questions[_currentQuestionIndex].options[index],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      value: index,
                      groupValue: _selectedOptionIndex,
                      onChanged: (value) {
                        setState(() {
                          _selectedOptionIndex = value!;
                        });
                      },
                      tileColor: _selectedOptionIndex == index
                          ? Colors.blue.shade100
                          : Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _answered ? _nextQuestion : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _answered ? 'Next Question' : 'Submit Answer',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_answered)
                    Text(
                      _isCorrect ? 'Correct!' : 'Incorrect!',
                      style: TextStyle(
                        color: _isCorrect ? Colors.green : Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onLongPress: _startListening,
                    onLongPressUp: _stopListening,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _isListening ? 'Listening...' : 'Hold to Speak Answer',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Question class to represent quiz questions
class Question {
  final String text;
  final List<String> options;
  final int correctOption;

  Question({
    required this.text,
    required this.options,
    required this.correctOption,
  });
}
