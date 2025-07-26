import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiptop/pages/Reward/RewardPage.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';
import 'DailyQuizPage.dart';
import 'FortuneWheelPage.dart';

class EarnRewardPointsPage
    extends
        StatefulWidget {
  const EarnRewardPointsPage({
    super.key,
  });

  @override
  State<
    EarnRewardPointsPage
  >
  createState() => _EarnRewardPointsPageState();
}

class _EarnRewardPointsPageState
    extends
        State<
          EarnRewardPointsPage
        > {
  bool _isLoading = false;
  bool _showWheelGuide = false;
  bool _showQuizGuide = false;
  int _dailySpinsLeft = 0;
  int _bonusRewardPoints = 0;
  bool _bonusPointsClaimed = false;
  double _conversionRate = 0.01;
  int _minRedeemPoints = 100;
  int _maxRedeemPoints = 1000;

  final List<
    int
  >
  wheelPoints = [
    50,
    20,
    100,
    10,
    200,
    30,
    75,
    15,
  ];

  @override
  void initState() {
    super.initState();
    _loadDailySpins();
  }

  Future<
    void
  >
  _loadDailySpins() async {
    setState(
      () {
        _isLoading = true;
      },
    );
    var result = await GetQuizSettings();
    if (result ==
        'success') {
      setState(
        () {
          _dailySpinsLeft = QuizSettingsData['user_remaining_spin'];
          _bonusRewardPoints = QuizSettingsData['bonus_reward_points'];
          _bonusPointsClaimed = QuizSettingsData['bonus_point_already_collected'];
          _conversionRate = QuizSettingsData['reward_points_conversion_rate'];
          _minRedeemPoints = QuizSettingsData['min_redeem_reward_points_for_redemption'];
          _maxRedeemPoints = QuizSettingsData['max_redeem_reward_points_for_redemption'];
          _isLoading = false;
        },
      );
    } else if (result ==
        'failure') {
      showErrorDialog(
        ErrorMessage,
      );
      setState(
        () {
          _isLoading = false;
        },
      );
    } else {
      setState(
        () {
          _isLoading = false;
          internet = true;
        },
      );
    }
  }

  Future<
    void
  >
  _claimBonusPoints() async {
    setState(
      () {
        _isLoading = true;
      },
    );
    var result = await ClaimBonusRewardPoints();
    if (result ==
        'success') {
      setState(
        () {
          _isLoading = false;
          _bonusPointsClaimed = true;
          _bonusRewardPoints = 0;
        },
      );
    } else if (result ==
        'failure') {
      showErrorDialog(
        ErrorMessage,
      );
      setState(
        () {
          _isLoading = false;
        },
      );
    } else {
      setState(
        () {
          _isLoading = false;
          internet = true;
        },
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    var media = MediaQuery.of(
      context,
    ).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(
            context,
          ),
        ),
        title: MyText(
          text: languages[choosenLanguage]['text_earn_rewards'],
          size:
              media.width *
              twenty,
          fontweight: FontWeight.w600,
        ),
        backgroundColor: page,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Bonus Points Card (if available)
                if (_bonusRewardPoints >
                        0 &&
                    !_bonusPointsClaimed)
                  Container(
                    width:
                        media.width *
                        0.9,
                    margin: EdgeInsets.all(
                      media.width *
                          0.05,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                      border: Border.all(
                        color: Colors.amber,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _claimBonusPoints,
                        borderRadius: BorderRadius.circular(
                          15,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            media.width *
                                0.04,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.gift,
                                        size:
                                            media.width *
                                            0.06,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(
                                        width:
                                            media.width *
                                            0.03,
                                      ),
                                      MyText(
                                        text: languages[choosenLanguage]['text_bonus_points'],
                                        size:
                                            media.width *
                                            sixteen,
                                        fontweight: FontWeight.w600,
                                        color: Colors.amber[700],
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        media.width *
                                        0.02,
                                  ),
                                  MyText(
                                    text: '$_bonusRewardPoints ${languages[choosenLanguage]['text_points_available']}',
                                    size:
                                        media.width *
                                        fourteen,
                                    color: Colors.amber[700],
                                  ),
                                  ElevatedButton(
                                    onPressed: _claimBonusPoints,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                      ),
                                    ),
                                    child: MyText(
                                      text: languages[choosenLanguage]['text_claim_now'],
                                      size:
                                          media.width *
                                          fourteen,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Header Section
                Container(
                  width:
                      media.width *
                      0.9,
                  margin: EdgeInsets.symmetric(
                    vertical:
                        media.width *
                        0.05,
                    horizontal:
                        media.width *
                        0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: languages[choosenLanguage]['text_ways_to_earn'],
                        size:
                            media.width *
                            eighteen,
                        fontweight: FontWeight.w700,
                      ),
                      SizedBox(
                        height:
                            media.width *
                            0.02,
                      ),
                      MyText(
                        text: languages[choosenLanguage]['text_earn_points_desc'],
                        size:
                            media.width *
                            fourteen,
                        color: textColor.withOpacity(
                          0.7,
                        ),
                      ),
                    ],
                  ),
                ),

                // Conversion Rate Info
                Container(
                  width:
                      media.width *
                      0.9,
                  margin: EdgeInsets.symmetric(
                    horizontal:
                        media.width *
                        0.05,
                  ),
                  padding: EdgeInsets.all(
                    media.width *
                        0.04,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.coins,
                        size:
                            media.width *
                            0.05,
                        color: buttonColor,
                      ),
                      SizedBox(
                        width:
                            media.width *
                            0.03,
                      ),
                      Expanded(
                        child: MyText(
                          text: '${languages[choosenLanguage]['text_points_worth']} \$$_conversionRate ${languages[choosenLanguage]['text_each_point']}',
                          size:
                              media.width *
                              fourteen,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height:
                      media.width *
                      0.05,
                ),

                // Fortune Wheel Card
                _buildEarningOptionCard(
                  context,
                  title: languages[choosenLanguage]['text_fortune_wheel'],
                  description: languages[choosenLanguage]['text_spin_wheel_desc'],
                  icon: FontAwesomeIcons.dharmachakra,
                  onTap: () => _navigateToWheel(
                    context,
                  ),
                  onInfoTap: () => setState(
                    () => _showWheelGuide = true,
                  ),
                  bottomText: '$_dailySpinsLeft ${languages[choosenLanguage]['text_spins_left']}',
                ),

                SizedBox(
                  height:
                      media.width *
                      0.05,
                ),

                // Quiz Card
                _buildEarningOptionCard(
                  context,
                  title: languages[choosenLanguage]['text_daily_quiz'],
                  description: languages[choosenLanguage]['text_quiz_desc'],
                  icon: FontAwesomeIcons.questionCircle,
                  onTap: () => _navigateToQuiz(
                    context,
                  ),
                  onInfoTap: () => setState(
                    () => _showQuizGuide = true,
                  ),
                  bottomText: languages[choosenLanguage]['text_earn_up_to_500'],
                ),

                // Redemption Info
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (
                              context,
                            ) => const RewardPage(),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.all(
                      media.width *
                          0.05,
                    ),
                    padding: EdgeInsets.all(
                      media.width *
                          0.04,
                    ),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      border: Border.all(
                        color: Colors.blue.withOpacity(
                          0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.exchangeAlt,
                              size:
                                  media.width *
                                  0.05,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width:
                                  media.width *
                                  0.02,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText(
                                    text: languages[choosenLanguage]['text_points_conversion_info'],
                                    size:
                                        media.width *
                                        twelve,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    height:
                                        media.width *
                                        0.01,
                                  ),
                                  MyText(
                                    text: '${languages[choosenLanguage]['text_redeem_between']} $_minRedeemPoints - $_maxRedeemPoints ${languages[choosenLanguage]['text_points']}',
                                    size:
                                        media.width *
                                        twelve,
                                    color: Colors.white.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            const Positioned(
              child: Loading(),
            ),

          // No internet overlay
          if (internet ==
              false)
            Positioned.fill(
              child: Container(
                color: page,
                child: NoInternet(
                  onTap: () {
                    setState(
                      () {
                        internetTrue();
                        _isLoading = true;
                        _loadDailySpins();
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      bottomSheet: _showWheelGuide
          ? _buildGuideBottomSheet(
              context,
              true,
            )
          : _showQuizGuide
          ? _buildGuideBottomSheet(
              context,
              false,
            )
          : null,
    );
  }

  // Rest of the methods remain the same
  Widget _buildEarningOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onInfoTap,
    required String bottomText,
  }) {
    var media = MediaQuery.of(
      context,
    ).size;

    return Container(
      width:
          media.width *
          0.9,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: borderLines,
        ),
        color: page,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.1,
            ),
            blurRadius: 10,
            offset: const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            15,
          ),
          child: Padding(
            padding: EdgeInsets.all(
              media.width *
                  0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size:
                              media.width *
                              0.06,
                          color: buttonColor,
                        ),
                        SizedBox(
                          width:
                              media.width *
                              0.03,
                        ),
                        MyText(
                          text: title,
                          size:
                              media.width *
                              sixteen,
                          fontweight: FontWeight.w600,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        FontAwesomeIcons.circleInfo,
                        size:
                            media.width *
                            0.05,
                        color: textColor.withOpacity(
                          0.5,
                        ),
                      ),
                      onPressed: onInfoTap,
                    ),
                  ],
                ),
                SizedBox(
                  height:
                      media.width *
                      0.02,
                ),
                MyText(
                  text: description,
                  size:
                      media.width *
                      twelve,
                  color: textColor.withOpacity(
                    0.7,
                  ),
                ),
                SizedBox(
                  height:
                      media.width *
                      0.03,
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        media.width *
                        0.03,
                    vertical:
                        media.width *
                        0.02,
                  ),
                  decoration: BoxDecoration(
                    color: buttonColor.withOpacity(
                      0.2,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: MyText(
                    text: bottomText,
                    size:
                        media.width *
                        twelve,
                    color: buttonColor,
                    fontweight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideBottomSheet(
    BuildContext context,
    bool isWheel,
  ) {
    var media = MediaQuery.of(
      context,
    ).size;

    return Container(
      decoration: BoxDecoration(
        color: page,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(
            20,
          ),
        ),
      ),
      padding: EdgeInsets.all(
        media.width *
            0.05,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: isWheel
                    ? languages[choosenLanguage]['text_wheel_guide']
                    : languages[choosenLanguage]['text_quiz_guide'],
                size:
                    media.width *
                    sixteen,
                fontweight: FontWeight.w600,
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: textColor,
                ),
                onPressed: () => setState(
                  () {
                    if (isWheel) {
                      _showWheelGuide = false;
                    } else {
                      _showQuizGuide = false;
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                media.width *
                0.03,
          ),
          ...isWheel
              ? _buildWheelGuideContent(
                  media,
                )
              : _buildQuizGuideContent(
                  media,
                ),
        ],
      ),
    );
  }

  List<
    Widget
  >
  _buildWheelGuideContent(
    Size media,
  ) {
    return [
      _buildGuideItem(
        media,
        icon: FontAwesomeIcons.repeat,
        title: languages[choosenLanguage]['text_daily_spins'],
        description: languages[choosenLanguage]['text_daily_spins_desc'],
      ),
      _buildGuideItem(
        media,
        icon: FontAwesomeIcons.gift,
        title: languages[choosenLanguage]['text_instant_rewards'],
        description: languages[choosenLanguage]['text_wheel_rewards_desc'],
      ),
      _buildGuideItem(
        media,
        icon: FontAwesomeIcons.clock,
        title: languages[choosenLanguage]['text_wait_period'],
        description: languages[choosenLanguage]['text_wheel_wait_desc'],
      ),
    ];
  }

  List<
    Widget
  >
  _buildQuizGuideContent(
    Size media,
  ) {
    return [
      _buildGuideItem(
        media,
        icon: FontAwesomeIcons.listCheck,
        title: languages[choosenLanguage]['text_quiz_rules'],
        description: languages[choosenLanguage]['text_quiz_rules_desc'],
      ),
      _buildGuideItem(
        media,
        icon: FontAwesomeIcons.trophy,
        title: languages[choosenLanguage]['text_scoring'],
        description: languages[choosenLanguage]['text_scoring_desc'],
      ),
    ];
  }

  Widget _buildGuideItem(
    Size media, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            media.width *
            0.04,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size:
                media.width *
                0.05,
            color: buttonColor,
          ),
          SizedBox(
            width:
                media.width *
                0.03,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: title,
                  size:
                      media.width *
                      fourteen,
                  fontweight: FontWeight.w600,
                ),
                SizedBox(
                  height:
                      media.width *
                      0.01,
                ),
                MyText(
                  text: description,
                  size:
                      media.width *
                      twelve,
                  color: textColor.withOpacity(
                    0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWheel(
    BuildContext context,
  ) {
    if (_dailySpinsLeft >
        0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (
                context,
              ) => FortuneWheelPage(),
        ),
      );
    } else {
      var media = MediaQuery.of(
        context,
      ).size;
      showDialog(
        context: context,
        builder:
            (
              context,
            ) => AlertDialog(
              title: MyText(
                text: languages[choosenLanguage]['text_no_spins'],
                size:
                    media.width *
                    sixteen,
                fontweight: FontWeight.w600,
              ),
              content: MyText(
                text: languages[choosenLanguage]['text_no_spins_desc'],
                size:
                    media.width *
                    fourteen,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                  ),
                  child: MyText(
                    text: languages[choosenLanguage]['text_ok'],
                    size:
                        media.width *
                        fourteen,
                    color: buttonColor,
                  ),
                ),
              ],
            ),
      );
    }
  }

  void _navigateToQuiz(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              context,
            ) => DailyquizPage(),
      ),
    );
  }
}
