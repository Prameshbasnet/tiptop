import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import 'map_page.dart';

class Review extends StatefulWidget {
  const Review({super.key});

  @override
  State<Review> createState() => _ReviewState();
}

double review = 0.0;
String feedback = '';

class _ReviewState extends State<Review> {
  bool _loading = false;

  @override
  void initState() {
    review = 0.0;
    super.initState();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  //navigate
  navigate() {
    dropStopList.clear();
    addressList.clear();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Maps()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Stack(
                children: [
                  Container(
                    height: media.height * 1,
                    width: media.width * 1,
                    padding: EdgeInsets.all(media.width * 0.05),
                    color: page,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: media.width * 0.1,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              (userRequestData.isNotEmpty)
                                  ? Container(
                                      height: media.width * 0.25,
                                      width: media.width * 0.25,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                              image: NetworkImage(
                                                  userRequestData[
                                                              'driverDetail']
                                                          ['data']
                                                      ['profile_picture']),
                                              fit: BoxFit.cover)),
                                    )
                                  : Container(),
                              SizedBox(
                                height: media.height * 0.03,
                              ),
                              MyText(
                                text: (userRequestData.isNotEmpty)
                                    ? userRequestData['driverDetail']['data']
                                        ['name']
                                    : '',
                                size: media.width * sixteen,
                              ),
                              SizedBox(
                                height: media.height * 0.02,
                              ),

                              //stars
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                      onTap: () {
                                        setState(() {
                                          review = 1.0;
                                        });
                                      },
                                      child: Icon(
                                        Icons.star,
                                        size: media.width * 0.08,
                                        color: (review >= 1)
                                            ? buttonColor
                                            : Colors.grey,
                                      )),
                                  SizedBox(
                                    width: media.width * 0.02,
                                  ),
                                  InkWell(
                                      onTap: () {
                                        setState(() {
                                          review = 2.0;
                                        });
                                      },
                                      child: Icon(
                                        Icons.star,
                                        size: media.width * 0.08,
                                        color: (review >= 2)
                                            ? buttonColor
                                            : Colors.grey,
                                      )),
                                  SizedBox(
                                    width: media.width * 0.02,
                                  ),
                                  InkWell(
                                      onTap: () {
                                        setState(() {
                                          review = 3.0;
                                        });
                                      },
                                      child: Icon(
                                        Icons.star,
                                        size: media.width * 0.08,
                                        color: (review >= 3)
                                            ? buttonColor
                                            : Colors.grey,
                                      )),
                                  SizedBox(
                                    width: media.width * 0.02,
                                  ),
                                  InkWell(
                                      onTap: () {
                                        setState(() {
                                          review = 4.0;
                                        });
                                      },
                                      child: Icon(
                                        Icons.star,
                                        size: media.width * 0.08,
                                        color: (review >= 4)
                                            ? buttonColor
                                            : Colors.grey,
                                      )),
                                  SizedBox(
                                    width: media.width * 0.02,
                                  ),
                                  InkWell(
                                      onTap: () {
                                        setState(() {
                                          review = 5.0;
                                        });
                                      },
                                      child: Icon(
                                        Icons.star,
                                        size: media.width * 0.08,
                                        color: (review == 5)
                                            ? buttonColor
                                            : Colors.grey,
                                      ))
                                ],
                              ),
                              SizedBox(
                                height: media.height * 0.05,
                              ),

                              //feedback text
                              Container(
                                padding: EdgeInsets.all(media.width * 0.05),
                                width: media.width * 0.9,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        width: 1.5, color: backgroundColor
                                        //  isDarkTheme == true
                                        //     ? Colors.grey
                                        //     : Colors.grey.withOpacity(0.1)
                                        )),
                                child: TextField(
                                  maxLines: 4,
                                  onChanged: (val) {
                                    setState(() {
                                      feedback = val;
                                    });
                                  },
                                  style: choosenLanguage == 'ar'
                                      ? GoogleFonts.cairo(color: textColor)
                                      : GoogleFonts.poppins(color: textColor),
                                  decoration: InputDecoration(
                                      hintText: languages[choosenLanguage]
                                          ['text_feedback'],
                                      hintStyle: choosenLanguage == 'ar'
                                          ? GoogleFonts.cairo(
                                              color: isDarkTheme == true
                                                  ? textColor.withOpacity(0.4)
                                                  : Colors.grey
                                                      .withOpacity(0.6))
                                          : GoogleFonts.poppins(
                                              color: isDarkTheme == true
                                                  ? textColor.withOpacity(0.4)
                                                  : Colors.grey
                                                      .withOpacity(0.6)),
                                      border: InputBorder.none),
                                ),
                              ),
                              SizedBox(
                                height: media.height * 0.05,
                              ),
                            ],
                          ),
                        ),
                        Button(
                          onTap: () async {
                            if (review >= 1.0) {
                              setState(() {
                                _loading = true;
                              });
                              var result = await userRating();

                              if (result == true) {
                                navigate();
                                _loading = false;
                              } else if (result == 'logout') {
                                navigateLogout();
                              } else {
                                setState(() {
                                  _loading = false;
                                });
                              }
                            }
                          },
                          text: languages[choosenLanguage]['text_submit'],
                          color: (review >= 1.0) ? buttonColor : Colors.grey,
                        )
                      ],
                    ),
                  ),
                  //loader
                  (_loading == true)
                      ? const Positioned(child: Loading())
                      : Container()
                ],
              ),
            );
          }),
    );
  }
}
