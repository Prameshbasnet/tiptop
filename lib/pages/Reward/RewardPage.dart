import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiptop/pages/PaymentGateway/mercadopago.dart';
import 'package:tiptop/pages/PaymentGateway/paywellnepalpage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/selectwallet.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';
import 'package:tiptop/pages/PaymentGateway/paystackpayment.dart';
import 'package:tiptop/pages/PaymentGateway/flutterWavePage.dart';
import 'package:tiptop/pages/PaymentGateway/razorpaypage.dart';
import 'package:tiptop/pages/PaymentGateway/cashfreepage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

dynamic addMoney;

TextEditingController phonenumber = TextEditingController();
TextEditingController amount = TextEditingController();

class _RewardPageState extends State<RewardPage> {
  TextEditingController addMoneyController = TextEditingController();

  bool _isLoading = true;
  bool _addPayment = false;
  bool _completed = false;
  bool showtoast = false;
  int ischeckmoneytransfer = 0;

  @override
  void initState() {
    getRewardPoint();
    super.initState();
  }

//get wallet details
  getRewardPoint() async {
    var val = await getRewardPointHistory();
    if (val == 'success') {
      _isLoading = false;
      _completed = true;
      valueNotifierBook.incrementNotifier();
    }
  }

  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = const [
      DropdownMenuItem(value: "user", child: Text("User")),
      DropdownMenuItem(value: "driver", child: Text("Driver")),
    ];
    return menuItems;
  }

  String dropdownValue = 'user';
  bool error = false;
  String errortext = '';
  bool ispop = false;


  //show toast for copy

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: ValueListenableBuilder(
          valueListenable: valueNotifierBook.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Scaffold(
                body: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(media.width * 0.05,
                          media.width * 0.05, media.width * 0.05, 0),
                      height: media.height * 1,
                      width: media.width * 1,
                      color: page,
                      child: Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          Stack(
                            children: [
                              Container(
                                padding:
                                    EdgeInsets.only(bottom: media.width * 0.05),
                                width: media.width * 1,
                                alignment: Alignment.center,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_enable_rewards'],
                                  size: media.width * twenty,
                                  fontweight: FontWeight.w600,
                                ),
                              ),
                              Positioned(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Icon(Icons.arrow_back_ios,
                                          color: textColor)))
                            ],
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          (rewardPointBalance != null)
                              ? Column(
                                  children: [
                                    Row(
                                      children: [
                                        MyText(
                                          text: languages[choosenLanguage][
                                              'text_availablerewardpointsbalance'],
                                          size: media.width * fourteen,
                                          fontweight: FontWeight.w800,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: media.width * 0.03,
                                    ),
                                    Container(
                                      height: media.width * 0.15,
                                      width: media.width * 0.9,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: backgroundColor),
                                        color: buttonColor.withOpacity(0.3),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            FontAwesomeIcons
                                                .coins, // Coin icon from FontAwesome
                                            color: buttonColor,
                                            size: media.width *
                                                0.06, // Adjust icon size based on your design
                                          ),
                                          SizedBox(
                                              width: media.width *
                                                  0.02), // Space between icon and text
                                          MyText(
                                            text: rewardPointBalance.toString(),
                                            size: media.width * twenty,
                                            fontweight: FontWeight.w600,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: MyText(
                                        text: languages[choosenLanguage][
                                            'text_recentRewardPointTransactions'],
                                        size: media.width * sixteen,
                                        fontweight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                )
                              : Container(),
                          Expanded(
                              child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                (rewardPointHistory.isNotEmpty)
                                    ? Column(
                                        children: rewardPointHistory
                                            .asMap()
                                            .map((i, value) {
                                              return MapEntry(
                                                  i,
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                        top: media.width * 0.02,
                                                        bottom:
                                                            media.width * 0.02),
                                                    width: media.width * 0.9,
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.025),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: borderLines,
                                                            width: 1.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        color: Colors.grey
                                                            .withOpacity(0.1)),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.center,  // Align items to the top
                                                      children: [
                                                        Container(
                                                          height: media.width *
                                                              0.1067,
                                                          width: media.width *
                                                              0.1067,
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              color: topBar),
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            (rewardPointHistory[
                                                                            i][
                                                                        'transaction_type'] ==
                                                                    "in")
                                                                ? '+'
                                                                : '-',
                                                            style: TextStyle(
                                                                fontSize: media
                                                                        .width *
                                                                    twentyfour),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.025,
                                                        ),
                                                        Flexible(
                                                            flex: 2, // Adjust this value if needed
                                                            child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            MyText(
                                                              text: rewardPointHistory[
                                                                          i][
                                                                      'description']
                                                                  .toString(),
                                                              size:
                                                                  media.width *
                                                                      fourteen,
                                                              fontweight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.02,
                                                            ),
                                                            MyText(
                                                              text: rewardPointHistory[
                                                                      i][
                                                                  'created_at'],
                                                              size:
                                                                  media.width *
                                                                      ten,
                                                              color: textColor
                                                                  .withOpacity(
                                                                      0.4),
                                                            )
                                                          ],
                                                        )),
                                                        // Spacer to push the points row to the end
                                                        const Spacer(),
                                                         Row(
                                                           mainAxisAlignment: MainAxisAlignment.end,
                                                           children: [
                                                            FaIcon(
                                                                FontAwesomeIcons
                                                                    .coins,
                                                                color:
                                                                    buttonColor,
                                                                size: media
                                                                        .width *
                                                                    sixteen,
                                                              ),
                                                            SizedBox(width: media.width * 0.01), // Small gap between icon and points text
                                                            MyText(
                                                              text:
                                                                  // rewardPointHistory[
                                                                  // i][
                                                                  // 'currency_symbol'] +

                                                                  ' ${rewardPointHistory[i]
                                                                              [
                                                                              'points']}',
                                                              size:
                                                                  media.width *
                                                                      twelve,
                                                              color: (isDarkTheme ==
                                                                      true)
                                                                  ? Colors.white
                                                                  : buttonColor,
                                                            )
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ));
                                            })
                                            .values
                                            .toList(),
                                      )
                                    : (_completed == true)
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                alignment: Alignment.center,
                                                height: media.width * 0.5,
                                                width: media.width * 0.5,
                                                decoration: const BoxDecoration(
                                                    image: DecorationImage(
                                                        image: AssetImage(
                                                            'assets/images/nodatafound.gif'),
                                                        fit: BoxFit.contain)),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.07,
                                              ),
                                              SizedBox(
                                                width: media.width * 0.8,
                                                child: MyText(
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_noDataFound'],
                                                    textAlign: TextAlign.center,
                                                    fontweight: FontWeight.w800,
                                                    size:
                                                        media.width * sixteen),
                                              ),
                                            ],
                                          )
                                        : Container(),

                                //load more button
                                (rewardPointHistoryPages.isNotEmpty)
                                    ? (rewardPointHistoryPages['current_page'] <
                                    rewardPointHistoryPages['last_page'])
                                        ? InkWell(
                                            onTap: () async {
                                              setState(() {
                                                _isLoading = true;
                                              });

                                              await getRewardPointHistory(
                                                  page:(rewardPointHistoryPages['current_page'] +
                                                          1)
                                                      .toString());

                                              setState(() {
                                                _isLoading = false;
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.025),
                                              margin: EdgeInsets.only(
                                                  bottom: media.width * 0.05),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: page,
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2)),
                                              child: MyText(
                                                text: languages[choosenLanguage]
                                                    ['text_loadmore'],
                                                size: media.width * sixteen,
                                              ),
                                            ),
                                          )
                                        : Container()
                                    : Container()
                              ],
                            ),
                          )),
                          SizedBox(
                            height: media.width * 0.18,
                            width: media.width * 0.9,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  text: languages[choosenLanguage]
                                      ['text_redeem_reward_points'],
                                  size: media.width * fourteen,
                                  fontweight: FontWeight.w800,
                                ),
                                SizedBox(
                                  height: media.width * 0.04,
                                ),
                                MyText(
                                  text: languages[choosenLanguage]
                                      ['text_redeem_reward_points_text'],
                                  size: media.width * twelve,
                                  fontweight: FontWeight.w600,
                                  color: textColor.withOpacity(0.5),
                                )
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                height: media.width * 0.15,
                                width: media.width * 0.9,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: backgroundColor),
                                  color: backgroundColor.withOpacity(0.3),
                                ),
                                // color: textColor,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _addPayment = true;
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          FaIcon(
                                            FontAwesomeIcons.gift, // Change this to the desired icon
                                            size: media.width * 0.06,
                                            color: buttonColor,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          MyText(
                                              text: languages[choosenLanguage]
                                                  ['text_redeem_reward_points'],
                                              size: media.width * sixteen,
                                              color: (ischeckmoneytransfer == 1)
                                                  ? const Color(0xFFFF0000)
                                                  : textColor)
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.1,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    //add payment
                    (_addPayment == true)
                        ? Positioned(
                            bottom: 0,
                            child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(
                                        bottom: media.width * 0.05),
                                    width: media.width * 0.9,
                                    padding:
                                        EdgeInsets.all(media.width * 0.025),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: borderLines, width: 1.2),
                                        color: page),
                                    child: Column(children: [
                                      Container(
                                        height: media.width * 0.128,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: borderLines, width: 1.2),
                                        ),
                                        child: Row(children: [
                                          Container(
                                              width: media.width * 0.1,
                                              height: media.width * 0.128,
                                              decoration: const BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(12),
                                                    bottomLeft:
                                                        Radius.circular(12),
                                                  ),
                                                  color: Color(0xffF0F0F0)),
                                              alignment: Alignment.center,
                                              child:FaIcon(
                                                FontAwesomeIcons.coins,
                                                color: buttonColor,
                                                size: media.width * 0.06,
                                              )
                                              // MyText(
                                              //   text: walletBalance[
                                              //       'currency_symbol'],
                                              //   size: media.width * twelve,
                                              //   fontweight: FontWeight.w600,
                                              //   color: (isDarkTheme == true)
                                              //       ? Colors.black
                                              //       : textColor,
                                              // )
                                          ),
                                          SizedBox(
                                            width: media.width * 0.05,
                                          ),
                                          Container(
                                            height: media.width * 0.128,
                                            width: media.width * 0.6,
                                            alignment: Alignment.center,
                                            child: TextField(
                                              controller: addMoneyController,
                                              onChanged: (val) {
                                                setState(() {
                                                  // Ensure to parse only if the input is a valid number
                                                  if (val.isNotEmpty) {
                                                    addMoney = int.parse(val);
                                                  } else {
                                                    addMoney = 0; // or handle the case for empty input
                                                  }
                                                });
                                              },
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter.digitsOnly, // Only allow digits
                                              ],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText:
                                                    languages[choosenLanguage]
                                                        ['text_enteramount'],
                                                hintStyle: choosenLanguage ==
                                                        'ar'
                                                    ? GoogleFonts.cairo(
                                                        fontSize: media.width *
                                                            fourteen,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: textColor
                                                            .withOpacity(0.4),
                                                      )
                                                    : GoogleFonts.poppins(
                                                        fontSize: media.width *
                                                            fourteen,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: textColor
                                                            .withOpacity(0.4),
                                                      ),
                                              ),
                                              style: choosenLanguage == 'ar'
                                                  ? GoogleFonts.cairo(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: textColor)
                                                  : GoogleFonts.poppins(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: textColor),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ]),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.05,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text = '100';
                                                addMoney = 100;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.22,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons.coins,
                                                    color: buttonColor,
                                                    size: media.width * 0.06,
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.02,
                                                  ),
                                                  MyText(
                                                    text: '100',
                                                    size: media.width * twelve,
                                                    fontweight: FontWeight.w600,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: media.width * 0.05,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text = '500';
                                                addMoney = 500;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.22,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons.coins,
                                                    color: buttonColor,
                                                    size: media.width * 0.06,
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.02,
                                                  ),
                                                  MyText(
                                                    text: '500',
                                                    size: media.width * twelve,
                                                    fontweight: FontWeight.w600,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: media.width * 0.05,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text =
                                                    '1000';
                                                addMoney = 1000;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.22,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons.coins,
                                                    color: buttonColor,
                                                    size: media.width * 0.06,
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.02,
                                                  ),
                                                  MyText(
                                                    text: '1000',
                                                    size: media.width * twelve,
                                                    fontweight: FontWeight.w600,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: media.width * 0.1,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Button(
                                            onTap: () async {
                                              setState(() {
                                                _addPayment = false;
                                                addMoney = null;
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                                addMoneyController.clear();
                                              });
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_cancel_redeem_points'],
                                            width: media.width * 0.4,
                                          ),
                                          Button(
                                            onTap: () async {
                                              print(addMoney);
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              if (addMoney != 0 &&
                                                  addMoney != null) {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                var val = await redeemRewardPoints(addMoney);
                                                if(val == 'success'){
                                                  setState(() {
                                                    _isLoading = false;
                                                    showtoast = true;
                                                  });
                                                }else{
                                                  setState(() {
                                                    _isLoading = false;
                                                    showtoast = false;
                                                  });
                                                  showErrorDialog(RewardPointRedeemErrorMessage,alignment: Alignment.topCenter);
                                                }
                                              }
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_addrewardpoints'],
                                            width: media.width * 0.4,
                                          ),
                                        ],
                                      )
                                    ]),
                                  ),
                                ],
                              ),
                            ))
                        : Container(),



                    //loader
                    (_isLoading == true)
                        ? const Positioned(child: Loading())
                        : Container(),
                    (showtoast == true)
                        ? PointsRedeemSuccess(
                            onTap: () async {
                              setState(() {
                                showtoast = false;
                                _addPayment = false;
                              });
                            },
                      points: (addMoney is String) ? num.parse(addMoney) : addMoney, // Check if it's a String, otherwise use the value directly
                      //add conversionRate:rewardPointConversionRate convert to double
                            convertionAmount: convertPointsToDollars(addMoney),
                            transfer: true,
                          )
                        : Container(),
                    (internet == false)
                        ? Positioned(
                            top: 0,
                            child: NoInternet(
                              onTap: () {
                                setState(() {
                                  internetTrue();
                                  _isLoading = true;
                                  getRewardPoint();
                                });
                              },
                            ))
                        : Container(),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
