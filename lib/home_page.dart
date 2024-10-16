import 'package:flutter/material.dart';
import 'quiz_page.dart';
import 'voice_notes_page.dart';
import 'add_question_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Welcome to the Quiz App',
                child: Text(
                  'Welcome to the Quiz App!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24, // Larger font size
                        color: Colors.black, // High contrast color
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              Semantics(
                label: 'Start Quiz',
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuizPage()),
                    );
                  },
                  child: const Text('Start Quiz'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 40), // Larger button
                    textStyle: const TextStyle(fontSize: 20), // Text color
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Voice Notes',
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VoiceNotesPage()),
                    );
                  },
                  child: const Text('Voice Notes'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 40), // Larger button
                    textStyle: const TextStyle(fontSize: 20), // Text color
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Add Question',
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddQuestionPage()),
                    );
                  },
                  child: const Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 40), // Larger button
                    textStyle: const TextStyle(fontSize: 20), // Text color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
