import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiptop/pages/login/login.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';

class NotificationPage
    extends
        StatefulWidget {
  const NotificationPage({
    super.key,
  });

  @override
  State<
    NotificationPage
  >
  createState() => _NotificationPageState();
}

class _NotificationPageState
    extends
        State<
          NotificationPage
        > {
  bool isLoading = true;
  bool error = false;
  dynamic notificationid;
  @override
  void initState() {
    getdata();
    super.initState();
  }

  Future<void> getdata() async {
    var val = await getnotificationHistory();
    if (val ==
        'success') {
      isLoading = false;
    } else {
      isLoading = true;
    }
  }

  void navigateLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (
              context,
            ) => const Login(),
      ),
    );
  }

  bool showinfo = false;
  int? showinfovalue;

  bool showToastbool = false;

  Future<void> showToast() async {
    setState(
      () {
        showToastbool = true;
      },
    );
    Future.delayed(
      const Duration(
        seconds: 1,
      ),
      () async {
        setState(
          () {
            showToastbool = false;
            // Navigator.pop(context, true);
          },
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    var media = MediaQuery.of(
      context,
    ).size;
    return Material(
      child: ValueListenableBuilder(
        valueListenable: valueNotifierHome.value,
        builder:
            (
              context,
              value,
              child,
            ) {
              return Directionality(
                textDirection:
                    (languageDirection ==
                        'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Stack(
                  children: [
                    Container(
                      height:
                          media.height *
                          1,
                      width:
                          media.width *
                          1,
                      color: page,
                      padding: EdgeInsets.fromLTRB(
                        media.width *
                            0.05,
                        media.width *
                            0.05,
                        media.width *
                            0.05,
                        0,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(
                              context,
                            ).padding.top,
                          ),
                          Stack(
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                  bottom:
                                      media.width *
                                      0.05,
                                ),
                                width:
                                    media.width *
                                    1,
                                alignment: Alignment.center,
                                child: MyText(
                                  text: languages[choosenLanguage]['text_notification'],
                                  size:
                                      media.width *
                                      twenty,
                                  fontweight: FontWeight.w600,
                                ),
                              ),
                              Positioned(
                                child: InkWell(
                                  onTap: () async {
                                    Navigator.pop(
                                      context,
                                    );
                                  },
                                  child: Icon(
                                    Icons.arrow_back_ios,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  //wallet history
                                  (notificationHistory.isNotEmpty)
                                      ? Column(
                                          children: [
                                            Column(
                                              children: notificationHistory
                                                  .asMap()
                                                  .map(
                                                    (
                                                      i,
                                                      value,
                                                    ) {
                                                      return MapEntry(
                                                        i,
                                                        InkWell(
                                                          onTap: () {
                                                            setState(
                                                              () {
                                                                showinfovalue = i;
                                                                showinfo = true;
                                                              },
                                                            );
                                                          },
                                                          child: Container(
                                                            margin: EdgeInsets.only(
                                                              top:
                                                                  media.width *
                                                                  0.02,
                                                              bottom:
                                                                  media.width *
                                                                  0.02,
                                                            ),
                                                            width:
                                                                media.width *
                                                                0.9,
                                                            padding: EdgeInsets.all(
                                                              media.width *
                                                                  0.025,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(
                                                                color: borderLines,
                                                                width: 1.2,
                                                              ),
                                                              borderRadius: BorderRadius.circular(
                                                                12,
                                                              ),
                                                              color: page,
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Container(
                                                                      height:
                                                                          media.width *
                                                                          0.1067,
                                                                      width:
                                                                          media.width *
                                                                          0.1067,
                                                                      decoration: BoxDecoration(
                                                                        borderRadius: BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                        color:
                                                                            const Color(
                                                                              0xff000000,
                                                                            ).withOpacity(
                                                                              0.05,
                                                                            ),
                                                                      ),
                                                                      alignment: Alignment.center,
                                                                      child: const Icon(
                                                                        Icons.notifications,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          media.width *
                                                                          0.025,
                                                                    ),
                                                                    Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              media.width *
                                                                              0.55,
                                                                          child: Text(
                                                                            notificationHistory[i]['title'].toString(),
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: GoogleFonts.poppins(
                                                                              fontSize:
                                                                                  media.width *
                                                                                  fourteen,
                                                                              color: textColor,
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width *
                                                                              0.01,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width *
                                                                              0.55,
                                                                          child: Text(
                                                                            notificationHistory[i]['body'].toString(),
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: GoogleFonts.poppins(
                                                                              fontSize:
                                                                                  media.width *
                                                                                  twelve,
                                                                              color: hintColor,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width *
                                                                              0.01,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width *
                                                                              0.55,
                                                                          child: Text(
                                                                            notificationHistory[i]['converted_created_at'].toString(),
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: GoogleFonts.poppins(
                                                                              fontSize:
                                                                                  media.width *
                                                                                  twelve,
                                                                              color: textColor,
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Expanded(
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                        children: [
                                                                          Container(
                                                                            alignment: Alignment.centerRight,
                                                                            width:
                                                                                media.width *
                                                                                0.15,
                                                                            child: IconButton(
                                                                              onPressed: () {
                                                                                setState(
                                                                                  () {
                                                                                    error = true;
                                                                                    notificationid = notificationHistory[i]['id'];
                                                                                  },
                                                                                );
                                                                              },
                                                                              icon: const Icon(
                                                                                Icons.delete_forever,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      media.width *
                                                                      0.02,
                                                                ),
                                                                if (notificationHistory[i]['image'] !=
                                                                    null)
                                                                  Image.network(
                                                                    notificationHistory[i]['image'],
                                                                    height:
                                                                        media.width *
                                                                        0.1,
                                                                    width:
                                                                        media.width *
                                                                        0.8,
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                  .values
                                                  .toList(),
                                            ),
                                            (notificationHistoryPage['pagination'] !=
                                                    null)
                                                ? (notificationHistoryPage['pagination']['current_page'] <
                                                          notificationHistoryPage['pagination']['total_pages'])
                                                      ? InkWell(
                                                          onTap: () async {
                                                            setState(
                                                              () {
                                                                isLoading = true;
                                                              },
                                                            );
                                                            var val = await getNotificationPages(
                                                              'page=${notificationHistoryPage['pagination']['current_page'] + 1}',
                                                            );
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            }
                                                            setState(
                                                              () {
                                                                isLoading = false;
                                                              },
                                                            );
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets.all(
                                                              media.width *
                                                                  0.025,
                                                            ),
                                                            margin: EdgeInsets.only(
                                                              bottom:
                                                                  media.width *
                                                                  0.05,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(
                                                                10,
                                                              ),
                                                              color: page,
                                                              border: Border.all(
                                                                color: borderLines,
                                                                width: 1.2,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              languages[choosenLanguage]['text_loadmore'],
                                                              style: GoogleFonts.poppins(
                                                                fontSize:
                                                                    media.width *
                                                                    sixteen,
                                                                color: textColor,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Container()
                                                : Container(),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height:
                                                  media.width *
                                                  0.3,
                                            ),
                                            Container(
                                              alignment: Alignment.center,
                                              height:
                                                  media.width *
                                                  0.5,
                                              width:
                                                  media.width *
                                                  0.5,
                                              decoration: const BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                    'assets/images/nodatafound.gif',
                                                  ),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  media.width *
                                                  0.07,
                                            ),
                                            SizedBox(
                                              width:
                                                  media.width *
                                                  0.8,
                                              child: MyText(
                                                text: languages[choosenLanguage]['text_noDataFound'],
                                                textAlign: TextAlign.center,
                                                fontweight: FontWeight.w800,
                                                size:
                                                    media.width *
                                                    sixteen,
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
                    (showinfo ==
                            true)
                        ? Positioned(
                            top: 0,
                            child: Container(
                              height:
                                  media.height *
                                  1,
                              width:
                                  media.width *
                                  1,
                              color: Colors.transparent.withOpacity(
                                0.6,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width:
                                        media.width *
                                        0.9,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          height:
                                              media.height *
                                              0.1,
                                          width:
                                              media.width *
                                              0.1,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: page,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              setState(
                                                () {
                                                  showinfo = false;
                                                  showinfovalue = null;
                                                },
                                              );
                                            },
                                            child: const Icon(
                                              Icons.cancel_outlined,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(
                                      media.width *
                                          0.05,
                                    ),
                                    width:
                                        media.width *
                                        0.9,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: backgroundColor,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      color: page,
                                    ),
                                    child: Column(
                                      children: [
                                        MyText(
                                          text: notificationHistory[showinfovalue!]['title'].toString(),
                                          size:
                                              media.width *
                                              sixteen,
                                          fontweight: FontWeight.w600,
                                        ),
                                        SizedBox(
                                          height:
                                              media.width *
                                              0.05,
                                        ),
                                        MyText(
                                          text: notificationHistory[showinfovalue!]['body'].toString(),
                                          size:
                                              media.width *
                                              fourteen,
                                          color: hintColor,
                                        ),
                                        SizedBox(
                                          height:
                                              media.width *
                                              0.05,
                                        ),
                                        if (notificationHistory[showinfovalue!]['image'] !=
                                            null)
                                          Image.network(
                                            notificationHistory[showinfovalue!]['image'],
                                            height:
                                                media.width *
                                                0.4,
                                            width:
                                                media.width *
                                                0.4,
                                            fit: BoxFit.contain,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(),
                    (error ==
                            true)
                        ? Positioned(
                            top: 0,
                            child: Container(
                              height:
                                  media.height *
                                  1,
                              width:
                                  media.width *
                                  1,
                              color: Colors.transparent.withOpacity(
                                0.6,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      media.width *
                                          0.05,
                                    ),
                                    width:
                                        media.width *
                                        0.9,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      color: page,
                                    ),
                                    child: Column(
                                      children: [
                                        MyText(
                                          text: languages[choosenLanguage]['text_delete_notification'],
                                          size:
                                              media.width *
                                              sixteen,
                                          fontweight: FontWeight.w600,
                                        ),
                                        SizedBox(
                                          height:
                                              media.width *
                                              0.05,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Button(
                                              onTap: () async {
                                                setState(
                                                  () {
                                                    error = false;
                                                    notificationid = null;
                                                  },
                                                );
                                              },
                                              text: languages[choosenLanguage]['text_no'],
                                            ),
                                            SizedBox(
                                              width:
                                                  media.width *
                                                  0.05,
                                            ),
                                            Button(
                                              onTap: () async {
                                                setState(
                                                  () {
                                                    isLoading = true;
                                                  },
                                                );
                                                var result = await deleteNotification(
                                                  notificationid,
                                                );
                                                if (result ==
                                                    'success') {
                                                  setState(
                                                    () {
                                                      getdata();
                                                      error = false;
                                                      isLoading = false;
                                                      showToast();
                                                    },
                                                  );
                                                }
                                              },
                                              text: languages[choosenLanguage]['text_yes'],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(),
                    (isLoading ==
                            true)
                        ? const Positioned(
                            top: 0,
                            child: Loading(),
                          )
                        : Container(),
                    (showToastbool ==
                            true)
                        ? Positioned(
                            bottom:
                                media.height *
                                0.2,
                            left:
                                media.width *
                                0.2,
                            right:
                                media.width *
                                0.2,
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.all(
                                media.width *
                                    0.025,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                                color: Colors.transparent.withOpacity(
                                  0.6,
                                ),
                              ),
                              child: MyText(
                                text: languages[choosenLanguage]['text_notification_deleted'],
                                size:
                                    media.width *
                                    twelve,
                                color: topBar,
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              );
            },
      ),
    );
  }
}
