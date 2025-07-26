import 'dart:async';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';
import 'QuizAttemptPage.dart';

class QuizItem {
  final String title;
  final String? description;
  final String? image;
  final String startDateTime;
  final String endDateTime;
  final int id;
  final bool is_started;
  final bool is_completed;

  QuizItem({
    required this.title,
    this.description,
    this.image,
    required this.startDateTime,
    required this.endDateTime,
    required this.id,
    required this.is_started,
    required this.is_completed,
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      image: json['image'],
      startDateTime: json['start_datetime'] ?? '',
      endDateTime: json['end_datetime'] ?? '',
      is_started: json['is_started'] ?? false,
      is_completed: json['is_completed'] ?? false,
    );
  }
}

class DailyquizPage extends StatefulWidget {
  const DailyquizPage({super.key});

  @override
  _DailyquizPageState createState() => _DailyquizPageState();
}

class _DailyquizPageState extends State<DailyquizPage> with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  bool _isLoading = true;
  List<QuizItem> quizList = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    fetchQuizQuestions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchQuizQuestions() async {
    var result = await GetDailyQuizList();
    if (result == 'success') {
      setState(() {
        quizList = List<QuizItem>.from(
            dailyQuizList.map((quiz) => QuizItem.fromJson(quiz)));
        _isLoading = false;
      });
      _fadeController.forward();
    } else {
      showErrorDialog(result['message']);
    }
  }

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM d, y • h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: media.width * 0.4,
                  floating: false,
                  pinned: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      languages[choosenLanguage]['text_daily_quiz'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: media.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/dailyquiz.jpg',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.all(media.width * 0.04),
                  sliver: (quizList.isEmpty
                      ? SliverToBoxAdapter(
                    child: _buildEmptyState(media),
                  )
                      : _buildQuizList(media)),
                ),
              ],
            ),
            (_isLoading == true)
                ? const Positioned(child: Loading())
                : Container(),
            if (internet == false)
              Positioned(
                top: 0,
                child: NoInternet(
                  onTap: () {
                    setState(() {
                      internetTrue();
                      _isLoading = true;
                      fetchQuizQuestions();
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Size media) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: media.width * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: media.width * 0.04),
          Text(
            "No Quizzes Available",
            style: TextStyle(
              fontSize: media.width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: media.width * 0.02),
          Text(
            "Check back later for new quizzes",
            style: TextStyle(
              fontSize: media.width * 0.035,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizList(Size media) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          QuizItem quiz = quizList[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: EdgeInsets.only(bottom: media.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {

                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (quiz.image != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            quiz.image!,
                            height: media.width * 0.5,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(media.width * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz.title,
                              style: TextStyle(
                                fontSize: media.width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (quiz.description != null) ...[
                              SizedBox(height: media.width * 0.02),
                              Text(
                                quiz.description!,
                                style: TextStyle(
                                  fontSize: media.width * 0.035,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            SizedBox(height: media.width * 0.03),
                            _buildTimeInfo(
                              media,
                              Icons.play_circle_outline,
                              'Starts',
                              formatDateTime(quiz.startDateTime),
                              Colors.green,
                            ),
                            SizedBox(height: media.width * 0.02),
                            _buildTimeInfo(
                              media,
                              Icons.timer_off_outlined,
                              'Ends',
                              formatDateTime(quiz.endDateTime),
                              Colors.red,
                            ),
                            SizedBox(height: media.width * 0.03),
                            SizedBox(
                              width: double.infinity,
                              height: media.width * 0.12,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if(quiz.is_completed){
                                    showErrorDialog('You have already completed this quiz');
                                    return;
                                  }
                                  var result=await GetDailyQuizQuestions(quiz.id);
                                  if(result=='success'){
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const QuizAttemptPage(),
                                      ),
                                    );

                                      setState(() {
                                        _isLoading = true;
                                      });
                                    fetchQuizQuestions();
                                  }else if(result=='failure'){
                                    showErrorDialog(ErrorMessage);
                                  }

                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: quiz.is_completed?Colors.green:quiz.is_started?Colors.amber:Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  quiz.is_completed?'Completed': quiz.is_started?'Resume Quiz':'Start Quiz',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: media.width * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: quizList.length,
      ),
    );
  }

  Widget _buildTimeInfo(
      Size media,
      IconData icon,
      String label,
      String time,
      Color color,
      ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(media.width * 0.02),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: media.width * 0.05,
            color: color,
          ),
        ),
        SizedBox(width: media.width * 0.02),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: media.width * 0.035,
                color: Colors.grey[600],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: media.width * 0.035,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }
}