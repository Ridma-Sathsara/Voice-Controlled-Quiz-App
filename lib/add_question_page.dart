import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart'; // Ensure this import is added

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({super.key});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  int _correctOption = 0;
  List<Question> _questions = [];
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final questionStrings = prefs.getStringList('questions') ?? [];

    setState(() {
      _questions = questionStrings.map((q) {
        final parts = q.split('|');
        return Question(
          text: parts[0],
          options: parts.sublist(1, 5),
          correctOption: int.parse(parts[5]),
        );
      }).toList();
    });
  }

  Future<void> _addQuestion() async {
    final questionText = _questionController.text;
    final options =
        _optionControllers.map((controller) => controller.text).toList();
    final correctOption = _correctOption;

    if (questionText.isNotEmpty &&
        options.every((option) => option.isNotEmpty) &&
        options.length == 4) {
      final question = Question(
        text: questionText,
        options: options,
        correctOption: correctOption,
      );

      final prefs = await SharedPreferences.getInstance();
      final questionStrings = prefs.getStringList('questions') ?? [];

      List<Question> questions = questionStrings.map((q) {
        final parts = q.split('|');
        return Question(
          text: parts[0],
          options: parts.sublist(1, 5),
          correctOption: int.parse(parts[5]),
        );
      }).toList();

      if (_editingIndex != null) {
        questions[_editingIndex!] = question;
      } else {
        questions.add(question);
      }

      await prefs.setStringList(
        'questions',
        questions
            .map((q) => '${q.text}|${q.options.join('|')}|${q.correctOption}')
            .toList(), // Ensure toList() is called
      );

      Navigator.pop(context, true);
    }
  }

  void _editQuestion(int index) {
    final question = _questions[index];
    _questionController.text = question.text;
    for (int i = 0; i < question.options.length; i++) {
      _optionControllers[i].text = question.options[i];
    }
    setState(() {
      _correctOption = question.correctOption;
      _editingIndex = index;
    });
  }

  Future<void> _deleteQuestion(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final questionStrings = prefs.getStringList('questions') ?? [];
    final questions = questionStrings.map((q) {
      final parts = q.split('|');
      return Question(
        text: parts[0],
        options: parts.sublist(1, 5),
        correctOption: int.parse(parts[5]),
      );
    }).toList();

    questions.removeAt(index);

    await prefs.setStringList(
      'questions',
      questions
          .map((q) => '${q.text}|${q.options.join('|')}|${q.correctOption}')
          .toList(), // Ensure toList() is called
    );

    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Question ${i + 1}: ${question.text}',
                  style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 10),
              pw.Text('Options:', style: pw.TextStyle(fontSize: 16)),
              ...List.generate(
                question.options.length,
                (index) => pw.Text(
                    '  Option ${index + 1}: ${question.options[index]}'),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Correct Option: Option ${question.correctOption + 1}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    try {
      // Define the path to the Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/questions_report.pdf');
      await file.writeAsBytes(await pdf.save());

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Generated'),
          content: Text('PDF report saved to ${file.path}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to save PDF: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Questions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _generatePdfReport,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            ...List.generate(4, (index) {
              return TextField(
                controller: _optionControllers[index],
                decoration: InputDecoration(labelText: 'Option ${index + 1}'),
              );
            }),
            DropdownButton<int>(
              value: _correctOption,
              items: List.generate(
                  4,
                  (index) => DropdownMenuItem(
                        value: index,
                        child: Text('Option ${index + 1}'),
                      )),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _correctOption = value;
                  });
                }
              },
              hint: const Text('Select Correct Option'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addQuestion,
              child: Text(
                  _editingIndex == null ? 'Add Question' : 'Update Question'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return ListTile(
                    title: Text(question.text),
                    subtitle: Text(question.options.join(', ')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editQuestion(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteQuestion(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
