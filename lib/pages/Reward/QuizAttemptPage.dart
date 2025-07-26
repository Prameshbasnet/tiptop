import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiptop/styles/styles.dart';
import 'package:tiptop/widgets/widgets.dart';

import '../../functions/functions.dart';

class QuizQuestion {
  final int id;
  final String type;
  final String answerType; // 'single' or 'multiple'
  final String description;
  final String? file;
  final double points;
  final int time;
  final List<QuizOption> options;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.answerType,
    required this.description,
    this.file,
    required this.points,
    required this.time,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      type: json['type'],
      answerType: json['answer_type'],
      description: json['description'],
      file: json['file'],
      points: double.parse(json['points'].toString()),
      time: json['time'],
      options: (json['options'] as List)
          .map((option) => QuizOption.fromJson(option))
          .toList(),
    );
  }
}

class QuizOption {
  final int id;
  final String value;

  QuizOption({
    required this.id,
    required this.value,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'],
      value: json['value'],
    );
  }
}

class QuizAttemptPage extends StatefulWidget {
  const QuizAttemptPage({super.key});

  @override
  _QuizAttemptPageState createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  late QuizQuestion currentQuestion;
  int currentQuestionNo = 1;
  // Updated to handle multiple selections
  int? selectedOptionId;
  Set<int> selectedOptionIds = {};
  late Timer _timer;
  int _timeRemaining = 0;
  bool _isSubmitting = false;
  late Map<String, dynamic> quizData;
  bool _mounted = true; // Track mounted state


  @override
  void initState() {
    super.initState();
    quizData = dailyQuizData;
    currentQuestion = QuizQuestion.fromJson(quizData['questions'][0]);
    //calculate current question number
    currentQuestionNo = quizData['questions'].indexWhere((question) => question['id'] == currentQuestion.id)+1;
    _timeRemaining = currentQuestion.time;
    _startTimer();
  }

  @override
  void dispose() {
    _mounted = false; // Set mounted to false when widget is disposed
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        if(_mounted) {
          setState(() {
            _timeRemaining--;
          });
        }
      } else {
        _timer.cancel();
        _submitAnswer();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitAnswer({backTrigger = false}) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    //if no option is selected select first option by default
    if(selectedOptionIds.isEmpty){
      selectedOptionId=currentQuestion.options[0].id;
      selectedOptionIds.add(selectedOptionId!);
    }

    var result=await submitDailyQuizQuestionAnswer(
        quizData['id'],
        currentQuestion.id,
        selectedOptionIds.toList()
    );
    if(result=='success') {
      if(backTrigger){
        Navigator.pop(context);
        return;
      }
      // Set Current Question to the next question
      int currentIndex = quizData['questions'].indexWhere((question) => question['id'] == currentQuestion.id);
      if (currentIndex < quizData['questions'].length - 1) {
        setState(() {
          currentQuestion = QuizQuestion.fromJson(quizData['questions'][currentIndex + 1]);
          currentQuestionNo = quizData['questions'].indexWhere((question) => question['id'] == currentQuestion.id)+1;
          _timeRemaining = currentQuestion.time;
          selectedOptionId = null;
          selectedOptionIds.clear();
        });
        _startTimer();
      }else {
        // Quiz Completed
        Navigator.pop(context);
      }

    }else{
      showErrorDialog(ErrorMessage);
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  bool get canSubmit {
    if (currentQuestion.answerType == 'single') {
      return selectedOptionId != null;
    } else {
      return selectedOptionIds.isNotEmpty;
    }
  }

  void _handleOptionSelection(int optionId) {
    setState(() {
      if (currentQuestion.answerType == 'radio') {
        selectedOptionId = optionId;
        selectedOptionIds = {optionId};
      } else {
        if (selectedOptionIds.contains(optionId)) {
          selectedOptionIds.remove(optionId);
        } else {
          selectedOptionIds.add(optionId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(media),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(media.width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionCard(media),
                      SizedBox(height: media.width * 0.04),
                      _buildOptions(media),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(media),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size media) {
    return Container(
      padding: EdgeInsets.all(media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>_submitAnswer(backTrigger: true),
          ),
          SizedBox(width: media.width * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quizData['title'],
                  style: TextStyle(
                    fontSize: media.width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  //use current question index instead of 1
                  'Question $currentQuestionNo of ${quizData['questions'].length}',
                  style: TextStyle(
                    fontSize: media.width * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: media.width * 0.03,
              vertical: media.width * 0.02,
            ),
            decoration: BoxDecoration(
              color: _timeRemaining < 60
                  ? Colors.red.withOpacity(0.1)
                  : buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: media.width * 0.045,
                  color: _timeRemaining < 60 ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_timeRemaining),
                  style: TextStyle(
                    fontSize: media.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: _timeRemaining < 60 ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Size media) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: media.width * 0.02,
              vertical: media.width * 0.01,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${currentQuestion.points} Points',
              style: TextStyle(
                fontSize: media.width * 0.035,
                color: buttonColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: media.width * 0.03),
          Text(
            currentQuestion.description,
            style: TextStyle(
              fontSize: media.width * 0.04,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (currentQuestion.file != null) ...[
            SizedBox(height: media.width * 0.03),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                currentQuestion.file!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions(Size media) {
    return Column(
      children: currentQuestion.options.map((option) {
        bool isSelected = currentQuestion.answerType == 'radio'
            ? selectedOptionId == option.id
            : selectedOptionIds.contains(option.id);

        return Container(
          margin: EdgeInsets.only(bottom: media.width * 0.03),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleOptionSelection(option.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(media.width * 0.04),
                decoration: BoxDecoration(
                  color: isSelected ? buttonColor.withOpacity(0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? buttonColor : Colors.grey.withOpacity(0.2),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: media.width * 0.06,
                      height: media.width * 0.06,
                      decoration: BoxDecoration(
                        shape: currentQuestion.answerType == 'radio'
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: currentQuestion.answerType == 'checkbox'
                            ? BorderRadius.circular(4)
                            : null,
                        border: Border.all(
                          color: isSelected ? buttonColor : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                        child: currentQuestion.answerType == 'single'
                            ? Container(
                          width: media.width * 0.03,
                          height: media.width * 0.03,
                          decoration: BoxDecoration(
                            color: buttonColor,
                            shape: BoxShape.circle,
                          ),
                        )
                            : Icon(
                          Icons.check,
                          size: media.width * 0.04,
                          color: buttonColor,
                        ),
                      )
                          : null,
                    ),
                    SizedBox(width: media.width * 0.03),
                    Expanded(
                      child: Text(
                        option.value,
                        style: TextStyle(
                          fontSize: media.width * 0.04,
                          color: isSelected ? buttonColor : Colors.black87,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(Size media) {
    return Container(
      padding: EdgeInsets.all(media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: !canSubmit || _isSubmitting ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? SizedBox(
                width: media.width * 0.05,
                height: media.width * 0.05,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'Submit Answer',
                style: TextStyle(
                  color: buttonText,
                  fontSize: media.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}