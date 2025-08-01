import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tiptop/pages/login/login.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/nointernet.dart';

class PickContact
    extends
        StatefulWidget {
  final String from;
  const PickContact({
    super.key,
    required this.from,
  });

  @override
  State<
    PickContact
  >
  createState() => _PickContactState();
}

List
contacts = [];
String
pickedName = '';
String
pickedNumber = '';

class _PickContactState
    extends
        State<
          PickContact
        > {
  bool _isLoading = false;
  bool _contactDenied = false;
  bool _noPermission = false;

  @override
  void initState() {
    getContact();
    super.initState();
  }

  //get contact permission
  Future<PermissionStatus> getContactPermission() async {
    var status = await Permission.contacts.status;
    return status;
  }

  //fetch contact data
  Future<void> getContact() async {
    if (contacts.isEmpty) {
      var permission = await getContactPermission();
      if (permission ==
          PermissionStatus.granted) {
        if (mounted) {
          setState(
            () {
              _isLoading = true;
            },
          );
        }

        Iterable<
          Contact
        >
        contactsList = await FlutterContacts.getContacts();

        // ignore: avoid_function_literals_in_foreach_calls
        contactsList.forEach(
          (
            contact,
          ) {
            contact.phones.toSet().forEach(
              (
                phone,
              ) {
                contacts.add(
                  {
                    'name':
                        contact.displayName ??
                        contact.name,
                    'phone': phone.number,
                  },
                );
              },
            );
          },
        );
        if (mounted) {
          setState(
            () {
              _isLoading = false;
            },
          );
        }
      } else {
        setState(
          () {
            _noPermission = true;
            _isLoading = false;
          },
        );
      }
    }
  }

  //navigate pop

  void pop() {
    Navigator.pop(
      context,
      true,
    );
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

  @override
  Widget build(
    BuildContext context,
  ) {
    var media = MediaQuery.of(
      context,
    ).size;
    return PopScope(
      canPop: true,
      // onWillPop: () async {
      //   Navigator.pop(context, false);
      //   return true;
      // },
      child: Material(
        child: Directionality(
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
                padding: EdgeInsets.only(
                  left:
                      media.width *
                      0.05,
                  right:
                      media.width *
                      0.05,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height:
                          MediaQuery.of(
                            context,
                          ).padding.top +
                          media.width *
                              0.05,
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
                          child: Text(
                            (widget.from ==
                                    '1')
                                ? languages[choosenLanguage]['text_sos']
                                : languages[choosenLanguage]['text_pick_contact'],
                            style: GoogleFonts.poppins(
                              fontSize:
                                  media.width *
                                  twenty,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        Positioned(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                    true,
                                  );
                                },
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: textColor,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(
                                    () {
                                      contacts.clear();
                                    },
                                  );
                                  getContact();
                                },
                                child: Icon(
                                  Icons.replay_outlined,
                                  color: textColor,
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
                          0.05,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: contacts
                              .asMap()
                              .map(
                                (
                                  i,
                                  value,
                                ) {
                                  return MapEntry(
                                    i,
                                    (sosData
                                            .map(
                                              (
                                                e,
                                              ) => e['number'],
                                            )
                                            .toString()
                                            .replaceAll(
                                              ' ',
                                              '',
                                            )
                                            .contains(
                                              contacts[i]['phone'].toString().replaceAll(
                                                ' ',
                                                '',
                                              ),
                                            ))
                                        ? Container()
                                        : Container(
                                            padding: EdgeInsets.all(
                                              media.width *
                                                  0.025,
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                setState(
                                                  () {
                                                    pickedName = contacts[i]['name'];
                                                    pickedNumber = contacts[i]['phone'];
                                                  },
                                                );
                                              },
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        media.width *
                                                        0.7,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          contacts[i]['name'],
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: GoogleFonts.poppins(
                                                            fontSize:
                                                                media.width *
                                                                fourteen,
                                                            fontWeight: FontWeight.w600,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height:
                                                              media.width *
                                                              0.01,
                                                        ),
                                                        Text(
                                                          contacts[i]['phone'],
                                                          style: GoogleFonts.poppins(
                                                            fontSize:
                                                                media.width *
                                                                twelve,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    height:
                                                        media.width *
                                                        0.05,
                                                    width:
                                                        media.width *
                                                        0.05,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: textColor,
                                                        width: 1.2,
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child:
                                                        (pickedName ==
                                                            contacts[i]['name'])
                                                        ? Container(
                                                            height:
                                                                media.width *
                                                                0.03,
                                                            width:
                                                                media.width *
                                                                0.03,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: textColor,
                                                            ),
                                                          )
                                                        : Container(),
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
                      ),
                    ),
                    (pickedName !=
                            '')
                        ? Container(
                            padding: EdgeInsets.only(
                              top:
                                  media.width *
                                  0.05,
                              bottom:
                                  media.width *
                                  0.05,
                            ),
                            child: Button(
                              onTap: () async {
                                setState(
                                  () {
                                    _isLoading = true;
                                  },
                                );
                                var val = await addSos(
                                  pickedName,
                                  pickedNumber,
                                );
                                if (val ==
                                    'success') {
                                  pop();
                                } else if (val ==
                                    'logout') {
                                  navigateLogout();
                                }
                                setState(
                                  () {
                                    _isLoading = false;
                                  },
                                );
                              },
                              text: languages[choosenLanguage]['text_confirm'],
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),

              (_noPermission ==
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
                                  Text(
                                    languages[choosenLanguage]['text_contact_permission'],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize:
                                          media.width *
                                          sixteen,
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        media.width *
                                        0.05,
                                  ),
                                  Button(
                                    onTap: () async {
                                      var status = await Permission.contacts.request();
                                      setState(
                                        () {
                                          _isLoading = true;
                                          _noPermission = false;
                                        },
                                      );
                                      if (status ==
                                          PermissionStatus.granted) {
                                        getContact();
                                      } else {
                                        _contactDenied = true;
                                        _isLoading = false;
                                      }
                                    },
                                    text: languages[choosenLanguage]['text_continue'],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(),

              //permission denied error
              (_contactDenied ==
                      true)
                  ? Positioned(
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
                                  InkWell(
                                    onTap: () {
                                      setState(
                                        () {
                                          _contactDenied = false;
                                        },
                                      );
                                      Navigator.pop(
                                        context,
                                        true,
                                      );
                                    },
                                    child: Container(
                                      height:
                                          media.width *
                                          0.1,
                                      width:
                                          media.width *
                                          0.1,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: page,
                                      ),
                                      child: const Icon(
                                        Icons.cancel_outlined,
                                      ),
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
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 2.0,
                                    spreadRadius: 2.0,
                                    color: Colors.black.withOpacity(
                                      0.2,
                                    ),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width:
                                        media.width *
                                        0.8,
                                    child: Text(
                                      languages[choosenLanguage]['text_open_contact_setting'],
                                      style: GoogleFonts.poppins(
                                        fontSize:
                                            media.width *
                                            sixteen,
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        media.width *
                                        0.05,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          await openAppSettings();
                                        },
                                        child: Text(
                                          languages[choosenLanguage]['text_open_settings'],
                                          style: GoogleFonts.poppins(
                                            fontSize:
                                                media.width *
                                                sixteen,
                                            color: buttonColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          setState(
                                            () {
                                              _contactDenied = false;
                                            },
                                          );
                                          getContact();
                                        },
                                        child: Text(
                                          languages[choosenLanguage]['text_done'],
                                          style: GoogleFonts.poppins(
                                            fontSize:
                                                media.width *
                                                sixteen,
                                            color: buttonColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
              //loader
              (_isLoading ==
                      true)
                  ? const Positioned(
                      top: 0,
                      child: Loading(),
                    )
                  : Container(),

              //no internet
              (internet ==
                      false)
                  ? Positioned(
                      top: 0,
                      child: NoInternet(
                        onTap: () {
                          setState(
                            () {
                              internetTrue();
                            },
                          );
                        },
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
