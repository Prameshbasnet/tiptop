// ignore_for_file: prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import 'AddNewCard.dart';
import 'RemoveCard.dart';

var cardDetail;
List<Map<String, dynamic>> cardList = [];

class CardManagement extends StatefulWidget {
  const CardManagement({super.key});

  @override
  State<CardManagement> createState() => _CardManagementState();
}

class _CardManagementState extends State<CardManagement> {
  bool _isLoading = true;
  bool _completed = false;
  bool showtoast = false;
  @override
  void initState() {
    getCardList();
    // Initialize cardList with empty list
    cardList = [];
    super.initState();
  }

//get Card Management details
  Future<void> getCardList() async {
    var val = await getCardManagementDetails();
    debugPrint(val);
    if (val == 'success') {
      setState(() {
        _isLoading = false;
        _completed = true;
        valueNotifierBook.incrementNotifier();
      });
    } else if (val == 'logout') {

      navigateLogout();
    }else if (val == 'no internet'){
      setState(() {
        _isLoading = false;
      });
    }
  }

  void navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

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
                bottomSheet: const SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        'Your payment info is stored securely',
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                ),
                body: Stack(children: [
                  Container(
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    padding: EdgeInsets.fromLTRB(media.width * 0.05,
                        media.width * 0.05, media.width * 0.05, 0),
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
                              child: Text(
                                languages[choosenLanguage]
                                    ['text_enable_card_management'],
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * twenty,
                                    fontWeight: FontWeight.w600,
                                    color: textColor),
                              ),
                            ),
                            Positioned(
                                child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Icon(Icons.arrow_back)))
                          ],
                        ),
                        Expanded(
                          // Wrap the ListView in an Expanded widget
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(children: [
                              (cardManagementPaymentMethods.isNotEmpty)
                                  ? Column(
                                      children: cardManagementPaymentMethods
                                          .asMap()
                                          .map((i, value) {
                                            return MapEntry(
                                                i,
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                height: 40,
                                                                width: 50,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .black),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8), // Add rounded corners
                                                                ),
                                                                // Add some padding for better spacing
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(8),
                                                                child: Center(
                                                                  child: Image
                                                                      .asset(
                                                                    value['card']['brand'] ==
                                                                            'mastercard'
                                                                        ? 'assets/images/masterCard.png'
                                                                        : value['card']['brand'] ==
                                                                                'visa'
                                                                            ? 'assets/images/visa.png'
                                                                            : 'assets/images/default.png', // Default image if not mastercard or visa
                                                                    fit: BoxFit
                                                                        .contain, // You can adjust the fit as needed
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    value['billing_details']['name']??'',
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 2,
                                                                  ),
                                                                  Text(
                                                                    // Access the 'last4' property from cardDetails
                                                                    '**** **** **** ${value['card']['last4']}',
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .blueGrey),
                                                                  ),
                                                                  Text(
                                                                    // Access the 'last4' property from cardDetails
                                                                    '${value['card']['exp_month']} / ${value['card']['exp_year']}',
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .blueGrey),
                                                                  ),
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
                                                              // cardDetail = cardDetails;
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      RemoveCard(
                                                                          cardDetail:
                                                                              value),
                                                                ),
                                                              );
                                                            },
                                                            child: const Icon(Icons
                                                                .arrow_forward),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      const Divider(),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
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
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Container(
                                              height: media.width * 0.7,
                                              width: media.width * 0.7,
                                              decoration: const BoxDecoration(
                                                  image: DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/nodatafound.gif'),
                                                      fit: BoxFit.contain)),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.02,
                                            ),
                                            SizedBox(
                                              width: media.width * 0.9,
                                              child: Text(
                                                languages[choosenLanguage]
                                                    ['text_noDataFound'],
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * sixteen,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor),
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                          ],
                                        )
                                      : Container(),
                            ]),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(
                              top: media.width * 0.05,
                              bottom: media.width * 0.12),
                          child: Button(
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AddNewCard()));
                              },
                              text: languages[choosenLanguage]
                                  ['text_card_management_add_card']),
                        ),
                        //loader
                      ],
                    ),
                  ),
                  //no internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _isLoading = true;
                              });
                            },
                          ))
                      : Container(),
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container()
                ]),
              ),
            );
          }),
    );
  }
}
