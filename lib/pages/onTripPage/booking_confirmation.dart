import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:vector_math/vector_math.dart' as vector;
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:share_plus/share_plus.dart';
import '../../functions/functions.dart';
import '../../functions/geohash.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
//import '../CardManagement/AddNewCard.dart';
import '../NavigatorPages/pickcontacts.dart';
//import '../chatPage/chat_page.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import 'choosegoods.dart';
import 'drop_loc_select.dart';
import 'invoice.dart';
import 'map_page.dart';

// ignore: must_be_immutable
class BookingConfirmation extends StatefulWidget {
  // const BookingConfirmation({Key? key}) : super(key: key);
  dynamic type;

  //type = 1 is rental ride and type = null is regular ride
  BookingConfirmation({super.key, this.type});

  @override
  State<BookingConfirmation> createState() => _BookingConfirmationState();
}

//Custom UseCase
dynamic selectedPaymentIndex;
bool incorrectAmount = false;
var biddingLowestAmount = 0.00;
/////////////////Custom UseCase

bool serviceNotAvailable = false;
String promoCode = '';
dynamic promoStatus;
dynamic choosenVehicle;
int payingVia = 0;
dynamic timing;
dynamic mapPadding = 0.0;
String goodsSize = '';
bool noDriverFound = false;
var driverData = {};
var driversData = [];
dynamic choosenDateTime;
bool lowWalletBalance = false;
bool tripReqError = false;
List rentalOption = [];
int rentalChoosenOption = 0;
Animation<double>? _animation;

class _BookingConfirmationState extends State<BookingConfirmation>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  TextEditingController promoKey = TextEditingController();
  TextEditingController yourAmount = TextEditingController();
  TextEditingController updateAmount = TextEditingController();
  TextEditingController pickerName = TextEditingController();
  TextEditingController pickerNumber = TextEditingController();
  TextEditingController instructions = TextEditingController();
  final Map minutes = {};
  List myMarker = [];
  Map myBearings = {};
  String _cancelReason = '';
  dynamic _controller;
  late PermissionStatus permission;
  bool _addCoupon = false;
  bool bottomChooseMethod = false;
  bool islowwalletbalance = false;
  List gesture = [];
  dynamic start;

  Location location = Location();
  bool _locationDenied = false;
  bool _isLoading = false;
  LatLng _center = const LatLng(41.4219057, -102.0840772);
  dynamic pinLocationIcon;
  dynamic pinLocationIcon2;
  dynamic animationController;
  bool _ontripBottom = false;
  bool _cancelling = false;
  bool _choosePayment = false;
  String _cancelCustomReason = '';
  dynamic timers;
  bool _dateTimePicker = false;
  bool _rideLaterSuccess = false;
  bool _confirmRideLater = false;
  bool showSos = false;
  bool notifyCompleted = false;
  bool _showInfo = false;
  bool _chooseGoodsType = false;
  dynamic _showInfoInt;
  dynamic _dist;
  bool _editUserDetails = false;
  String _cancellingError = '';
  GlobalKey iconKey = GlobalKey();
  GlobalKey iconDropKey = GlobalKey();
  GlobalKey iconDistanceKey = GlobalKey();
  var iconDropKeys = {};
  bool _cancel = false;
  List driverBck = [];
  bool currentpage = true;
  final _mapMarkerSC = StreamController<List<Marker>>();
  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
  Stream<List<Marker>> get mapMarkerStream => _mapMarkerSC.stream;
  bool dropConfirmed = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    promoCode = '';
    mapPadding = 0.0;
    promoStatus = null;
    serviceNotAvailable = false;
    tripReqError = false;
    myBearings.clear();
    noDriverFound = false;
    etaDetails.clear();
    currentpage = true;
    selectedGoodsId = '';
    if (widget.type == 1 || widget.type == 2) {
      setState(() {
        dropConfirmed = true;
      });
    }
    getLocs();
    getCardList();
    super.initState();
  }

  //get Card Management details
  Future<void> getCardList() async {
    setState(() {
      _isLoading = false;
    });
    var val = await getCardManagementDetails();
    debugPrint(val);
    if (val == 'success') {
      setState(() {
        _isLoading = false;
        valueNotifierBook.incrementNotifier();
      });
    } else if (val == 'logout') {
      navigateLogout();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
      }
      getUserDetails();
      if (timers == null &&
          userRequestData.isNotEmpty &&
          userRequestData['accepted_at'] == null) {
        timer();
      }
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
    }
  }

  @override
  void dispose() {
    if (timers != null) {
      timers?.cancel;
    }

    _controller?.dispose();
    _controller = null;
    animationController?.dispose();

    super.dispose();
  }

  //Card List Bottom Sheet

  // void _showCardModal(BuildContext context, int methodId) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Container(
  //         padding: EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text(
  //                   'Your Cards',
  //                   style:
  //                       TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
  //                 ),
  //                 Button(
  //                     onTap: () async {
  //                       Navigator.of(context).pop();
  //                       await Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                               builder: (context) => AddNewCard()));
  //                     },
  //                     text: languages[choosenLanguage]
  //                         ['text_card_management_add_card']),
  //               ],
  //             ),
  //             Divider(),
  //             // Add your card list here
  //             // You can use ListView.builder to display a dynamic list of cards
  //             (cardManagementPaymentMethods.isNotEmpty)
  //                 ? Column(
  //                     children: cardManagementPaymentMethods
  //                         .asMap()
  //                         .map((i, value) {
  //                           bool isSelected = false;
  //
  //                           if (selectedPaymentIndex != null && value != null) {
  //                             // Check if both value and selectedPaymentIndex are maps
  //                             if (value is Map && selectedPaymentIndex is Map) {
  //                               // Check if both maps contain the "id" property
  //                               if (value.containsKey('id') &&
  //                                   selectedPaymentIndex.containsKey('id')) {
  //                                 isSelected =
  //                                     value['id'] == selectedPaymentIndex['id'];
  //                               }
  //                             }
  //                           }
  //                           return MapEntry(
  //                             i,
  //                             Padding(
  //                               padding:
  //                                   const EdgeInsets.symmetric(horizontal: 20),
  //                               child: Column(
  //                                 children: [
  //                                   GestureDetector(
  //                                     onTap: () {
  //                                       setState(() {
  //                                         payingVia = methodId;
  //                                         selectedPaymentIndex =
  //                                             value; // Set the selected card index
  //                                         Navigator.of(context)
  //                                             .pop(); // Close the modal sheet
  //                                       });
  //                                     },
  //                                     child: Row(
  //                                       crossAxisAlignment:
  //                                           CrossAxisAlignment.start,
  //                                       mainAxisAlignment:
  //                                           MainAxisAlignment.spaceBetween,
  //                                       children: [
  //                                         Row(
  //                                           children: [
  //                                             Radio(
  //                                               // Use a Radio widget here
  //                                               value:
  //                                                   i, // Assign a unique value to each radio button
  //                                               groupValue: isSelected
  //                                                   ? i
  //                                                   : null, // Use the selectedPaymentIndex
  //                                               onChanged: (value2) {
  //                                                 // Handle radio button selection
  //                                                 setState(() {
  //                                                   selectedPaymentIndex =
  //                                                       value;
  //                                                   payingVia = methodId;
  //                                                   Navigator.of(context).pop();
  //                                                 });
  //                                               },
  //                                             ),
  //                                             Container(
  //                                               height: 40,
  //                                               width: 50,
  //                                               decoration: BoxDecoration(
  //                                                 color: Colors.white,
  //                                                 border: Border.all(
  //                                                     color: Colors.black),
  //                                                 borderRadius:
  //                                                     BorderRadius.circular(8),
  //                                               ),
  //                                               child: Center(
  //                                                 child: Image.asset(
  //                                                   value['card']['brand'] ==
  //                                                           'mastercard'
  //                                                       ? 'assets/images/masterCard.png'
  //                                                       : value['card']
  //                                                                   ['brand'] ==
  //                                                               'visa'
  //                                                           ? 'assets/images/visa.png'
  //                                                           : 'assets/images/default.png',
  //                                                   fit: BoxFit.contain,
  //                                                 ),
  //                                               ),
  //                                               padding: EdgeInsets.all(8),
  //                                             ),
  //                                             const SizedBox(width: 10),
  //                                             Column(
  //                                               crossAxisAlignment:
  //                                                   CrossAxisAlignment.start,
  //                                               children: [
  //                                                 Text(
  //                                                   value['billing_details']
  //                                                       ['name'],
  //                                                   style: const TextStyle(
  //                                                       fontWeight:
  //                                                           FontWeight.bold),
  //                                                 ),
  //                                                 const SizedBox(height: 2),
  //                                                 Text(
  //                                                   '**** **** **** ${value['card']['last4']}',
  //                                                   style: const TextStyle(
  //                                                       color: Colors.blueGrey),
  //                                                 ),
  //                                                 Text(
  //                                                   '${value['card']['exp_month']} / ${value['card']['exp_year']}',
  //                                                   style: const TextStyle(
  //                                                       color: Colors.blueGrey),
  //                                                 ),
  //                                               ],
  //                                             )
  //                                           ],
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ),
  //                                   const SizedBox(height: 10),
  //                                   const Divider(),
  //                                   const SizedBox(height: 10),
  //                                 ],
  //                               ),
  //                             ),
  //                           );
  //                         })
  //                         .values
  //                         .toList(),
  //                   )
  //                 : Container()
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

//running timer
  void timer() {
    if (userRequestData['is_bid_ride'] == 1) {
      timers = Timer.periodic(const Duration(seconds: 1), (timer) {
        valueNotifierTimer.incrementNotifier();
      });
    } else {
      timing =
          userRequestData['maximum_time_for_find_drivers_for_regular_ride'];

      if (mounted) {
        timers = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (timing != null) {
            if (userRequestData.isNotEmpty &&
                userDetails['accepted_at'] == null &&
                timing > 0) {
              timing--;
              valueNotifierBook.incrementNotifier();
            } else if (userRequestData.isNotEmpty &&
                userRequestData['accepted_at'] == null &&
                timing == 0) {
              var val = await cancelRequest();

              setState(() {
                noDriverFound = true;
              });

              timer.cancel();
              timing = null;
              if (val == 'logout') {
                navigateLogout();
              }
            } else {
              timer.cancel();
              timing = null;
            }
          } else {
            timer.cancel();
            timing = null;
          }
        });
      }
    }
  }

//create icon

  Future _capturePng(GlobalKey iconKeys) async {
    dynamic bitmap;

    try {
      RenderRepaintBoundary boundary =
          iconKeys.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();
      bitmap = BitmapDescriptor.fromBytes(pngBytes);
      // return pngBytes;
    } catch (e) {
      debugPrint(e.toString());
    }
    return bitmap;
  }

  Future<void> addDropMarker() async {
    for (var i = 1; i < addressList.length; i++) {
      var testIcon = await _capturePng(iconDropKeys[i]);
      if (testIcon != null) {
        setState(() {
          myMarker.add(Marker(
              markerId: MarkerId((i + 1).toString()),
              icon: testIcon,
              position: addressList[i].latlng));
        });
      }
    }

    if (widget.type != 1) {
      LatLngBounds bound;
      if (userRequestData.isNotEmpty) {
        if (userRequestData['pick_lat'] > userRequestData['drop_lat'] &&
            userRequestData['pick_lng'] > userRequestData['drop_lng']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              northeast: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng']));
        } else if (userRequestData['pick_lng'] > userRequestData['drop_lng']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['pick_lat'], userRequestData['drop_lng']),
              northeast: LatLng(
                  userRequestData['drop_lat'], userRequestData['pick_lng']));
        } else if (userRequestData['pick_lat'] > userRequestData['drop_lat']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['drop_lat'], userRequestData['pick_lng']),
              northeast: LatLng(
                  userRequestData['pick_lat'], userRequestData['drop_lng']));
        } else {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng']),
              northeast: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']));
        }
      } else {
        if (addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                    .latitude >
                addressList
                    .lastWhere((element) => element.type == 'drop')
                    .latlng
                    .latitude &&
            addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                    .longitude >
                addressList
                    .lastWhere((element) => element.type == 'drop')
                    .latlng
                    .longitude) {
          bound = LatLngBounds(
              southwest: addressList
                  .lastWhere((element) => element.type == 'drop')
                  .latlng,
              northeast: addressList
                  .firstWhere((element) => element.type == 'pickup')
                  .latlng);
        } else if (addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .longitude) {
          bound = LatLngBounds(
              southwest: LatLng(
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .latitude,
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .longitude),
              northeast: LatLng(
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .latitude,
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .longitude));
        } else if (addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .latitude) {
          bound = LatLngBounds(
              southwest: LatLng(
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .latitude,
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .longitude),
              northeast: LatLng(
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .latitude,
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .longitude));
        } else {
          bound = LatLngBounds(
              southwest: addressList
                  .firstWhere((element) => element.type == 'pickup')
                  .latlng,
              northeast: addressList
                  .lastWhere((element) => element.type == 'drop')
                  .latlng);
        }
      }
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bound, 50);
      _controller!.animateCamera(cameraUpdate);
      // CameraUpdate.newCameraPosition(CameraPosition(target: target))
    }
  }

  Future<void> addMarker() async {
    var testIcon = await _capturePng(iconKey);
    if (testIcon != null) {
      setState(() {
        myMarker.add(Marker(
            markerId: const MarkerId('1'),
            icon: testIcon,
            position: (userRequestData.isEmpty)
                ? addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                : LatLng(
                    userRequestData['pick_lat'], userRequestData['pick_lng'])));
      });
    }
  }

//add distance marker
  Future<void> addDistanceMarker(length) async {
    var testIcon = await _capturePng(iconDistanceKey);
    if (testIcon != null) {
      setState(() {
        if (polyList.isNotEmpty) {
          myMarker.add(Marker(
              markerId: const MarkerId('pointdistance'),
              icon: testIcon,
              position: polyList[length],
              anchor: const Offset(0.0, 1.0)));
        }
      });
    }
  }

  void navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

//add drop marker
  Future<void> addPickDropMarker() async {
    // Simulate some delay for demonstration purposes
    await Future.delayed(const Duration(milliseconds: 500));

    addMarker();
    // Future.delayed(const Duration(milliseconds: 200), () async {
    if (userRequestData.isNotEmpty &&
        userRequestData['is_rental'] != true &&
        userRequestData['drop_address'] != null) {
      addDropMarker();
      if (userRequestData.isEmpty) {
        polyline.add(
          Polyline(
              polylineId: const PolylineId('1'),
              color: buttonColor,
              points: [
                addressList
                    .firstWhere((element) => element.id == 'pickup')
                    .latlng,
                addressList
                    .firstWhere((element) => element.id == 'pickup')
                    .latlng
              ],
              geodesic: false,
              width: 5),
        );
      } else {
        polyline.add(
          Polyline(
              polylineId: const PolylineId('1'),
              color: buttonColor,
              points: [
                LatLng(double.parse(userRequestData['pick_lat'].toString()),
                    double.parse(userRequestData['pick_lng'].toString())),
                LatLng(double.parse(userRequestData['pick_lat'].toString()),
                    double.parse(userRequestData['pick_lng'].toString()))
              ],
              geodesic: false,
              width: 5),
        );
      }

      getPolylines();
    } else if (widget.type == null) {
      addDropMarker();
      if (userRequestData.isEmpty) {
        polyline.add(
          Polyline(
              polylineId: const PolylineId('1'),
              color: buttonColor,
              points: [
                addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng,
                addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
              ],
              geodesic: false,
              width: 5),
        );
      } else {
        polyline.add(
          Polyline(
              polylineId: const PolylineId('1'),
              color: buttonColor,
              points: [
                LatLng(double.parse(userRequestData['pick_lat'].toString()),
                    double.parse(userRequestData['pick_lng'].toString())),
                LatLng(double.parse(userRequestData['pick_lat'].toString()),
                    double.parse(userRequestData['pick_lng'].toString()))
              ],
              geodesic: false,
              width: 5),
        );
      }

      await getPolylines();

      // var list = await getPolylines();
      // if (choosenTransportType == 0 && userRequestData.isEmpty) {
      //   addDistanceMarker((list.length / 2).toInt());
      // }
    } else {
      if (userRequestData.isNotEmpty) {
        CameraUpdate cameraUpdate = CameraUpdate.newLatLng(
            LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']));
        _controller!.animateCamera(cameraUpdate);
      } else {
        CameraUpdate cameraUpdate = CameraUpdate.newLatLng(addressList
            .firstWhere((element) => element.type == 'pickup')
            .latlng);
        _controller!.animateCamera(cameraUpdate);
      }
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

//get location permission and location details
  Future<void> getLocs() async {
    setState(() {
      _center = (userRequestData.isEmpty)
          ? addressList.firstWhere((element) => element.type == 'pickup').latlng
          : LatLng(double.parse(userRequestData['pick_lat'].toString()),
              double.parse(userRequestData['pick_lng'].toString()));
    });
    if (await geolocs.GeolocatorPlatform.instance.isLocationServiceEnabled()) {
      serviceEnabled = true;
    } else {
      serviceEnabled = false;
    }
    final Uint8List markerIcon;
    final Uint8List markerIcon2;
    if (choosenTransportType == 0) {
      markerIcon = await getBytesFromAsset('assets/images/top-taxi.png', 40);
      pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
      markerIcon2 = await getBytesFromAsset('assets/images/bike.png', 40);
      pinLocationIcon2 = BitmapDescriptor.fromBytes(markerIcon2);
    } else {
      markerIcon =
          await getBytesFromAsset('assets/images/deliveryicon.png', 40);
      pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
      markerIcon2 = await getBytesFromAsset('assets/images/bike.png', 40);
      pinLocationIcon2 = BitmapDescriptor.fromBytes(markerIcon2);
    }

    choosenVehicle = null;
    _dist = null;

    // if (widget.type != 1) {
    //   var val = await etaRequest();
    //   if (val == 'logout') {
    //     navigateLogout();
    //   }
    // } else {
    //   var val = await rentalEta();
    //   if (val == 'logout') {
    //     navigateLogout();
    //   }
    // }
    if (widget.type == 2) {
      var val = await etaRequest();
      if (val == 'logout') {
        navigateLogout();
      }
    }
    if (widget.type == 1) {
      var val = await rentalEta();
      if (val == 'logout') {
        navigateLogout();
      }
    }

    permission = await location.hasPermission();

    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever) {
      setState(() {
        locationAllowed = false;
      });
    } else if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
      setState(() {});
    }
    Future.delayed(const Duration(milliseconds: 100), () async {
      await addPickDropMarker();
    });
  }

  void _onMapCreated(GoogleMapController controller) async {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    _controller!.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      check(u, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    GeoHasher geo = GeoHasher();

    double lat = 0.0144927536231884;
    double lon = 0.0181818181818182;
    double lowerLat = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude -
            (lat * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lat'] - (lat * 1.24)
            : 0.0;
    double lowerLon = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude -
            (lon * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lng'] - (lon * 1.24)
            : 0.0;

    double greaterLat = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude +
            (lat * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lat'] - (lat * 1.24)
            : 0.0;
    double greaterLon = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude +
            (lon * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lng'] - (lat * 1.24)
            : 0.0;
    var lower = geo.encode(lowerLon, lowerLat);
    var higher = geo.encode(greaterLon, greaterLat);

    var fdb = FirebaseDatabase.instance
        .ref('drivers')
        .orderByChild('g')
        .startAt(lower)
        .endAt(higher);

    popFunction() {
      if (userRequestData.isEmpty) {
        return false;
      } else {
        return true;
      }
    }

    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: popFunction(),
      onPopInvoked: (did) {
        if (userRequestData.isEmpty) {
          if (widget.type == null) {
            if (dropConfirmed) {
              setState(() {
                dropConfirmed = false;
              });
            } else {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Maps()),
                  (route) => false);
              addressList.removeWhere((element) => element.id == 'drop');
              etaDetails.clear();
              promoKey.clear();
              promoStatus = null;
              rentalOption.clear();
              _rideLaterSuccess = false;
              myMarker.clear();
              dropStopList.clear();
            }
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Maps()),
                (route) => false);
            addressList.removeWhere((element) => element.id == 'drop');
            etaDetails.clear();
            promoKey.clear();
            promoStatus = null;
            rentalOption.clear();
            _rideLaterSuccess = false;
            myMarker.clear();
            dropStopList.clear();
          }
        }
      },
      child: Material(
        child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: Container(
            height: media.height * 1,
            width: media.width * 1,
            color: page,
            child: ValueListenableBuilder(
                valueListenable: valueNotifierBook.value,
                builder: (context, value, child) {
                  if (_controller != null) {
                    mapPadding = media.width * 1;
                  }
                  if (cancelRequestByUser == true) {
                    myMarker.clear();
                    polyline.clear();
                    addressList
                        .removeWhere((element) => element.type == 'drop');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Maps()),
                          (route) => false);
                    });
                  }
                  if (userRequestData['is_completed'] == 1 &&
                      currentpage == true) {
                    currentpage = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Invoice()),
                          (route) => false);
                    });
                  }
                  if (userRequestData.isNotEmpty &&
                      timing == null &&
                      userRequestData['accepted_at'] == null) {
                    timer();
                  } else if (userRequestData.isNotEmpty &&
                      userRequestData['accepted_at'] != null) {
                    timing = null;
                  }
                  if (userRequestData.isNotEmpty &&
                      userRequestData['accepted_at'] != null) {
                    if (myMarker
                        .where((element) =>
                            element.markerId == const MarkerId('pointdistance'))
                        .isNotEmpty) {
                      myMarker.removeWhere((element) =>
                          element.markerId == const MarkerId('pointdistance'));
                    }
                  }
                  return StreamBuilder<DatabaseEvent>(
                      stream: (userRequestData['driverDetail'] == null &&
                              pinLocationIcon != null)
                          ? fdb.onValue.asBroadcastStream()
                          : null,
                      builder: (context, AsyncSnapshot<DatabaseEvent> event) {
                        if (event.hasData) {
                          if (event.data!.snapshot.value != null) {
                            if (userRequestData['accepted_at'] == null) {
                              DataSnapshot snapshots = event.data!.snapshot;
                              // ignore: unnecessary_null_comparison
                              if (snapshots != null &&
                                  choosenVehicle != null &&
                                  etaDetails.isNotEmpty) {
                                driversData = [];
                                // ignore: avoid_function_literals_in_foreach_calls
                                snapshots.children.forEach((element) {
                                  driversData.add(element.value);
                                });
                                // ignore: avoid_function_literals_in_foreach_calls
                                driversData.forEach((e) {
                                  if (e['is_active'] == 1 &&
                                      e['is_available'] == true) {
                                    if (((choosenTransportType == 0 && e['transport_type'] == 'taxi') ||
                                            (choosenTransportType == 0 &&
                                                e['transport_type'] ==
                                                    'both')) &&
                                        ((e['vehicle_types'] != null && ((widget.type != 1 && e['vehicle_types'].contains(etaDetails[choosenVehicle]['type_id'])) || (widget.type == 1 && e['vehicle_types'].contains(rentalOption[choosenVehicle]['type_id'])))) ||
                                            ((widget.type != 1 && e['vehicle_type'] == etaDetails[choosenVehicle]['type_id']) ||
                                                (widget.type == 1 &&
                                                    e['vehicle_type'] ==
                                                        rentalOption[choosenVehicle]
                                                            ['type_id'])))) {
                                      DateTime dt =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              e['updated_at']);
                                      if (DateTime.now()
                                              .difference(dt)
                                              .inMinutes <=
                                          2) {
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains('car${e['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId('car${e['id']}'),
                                            rotation: (myBearings[
                                                        e['id'].toString()] !=
                                                    null)
                                                ? myBearings[e['id'].toString()]
                                                : 0.0,
                                            position:
                                                LatLng(e['l'][0], e['l'][1]),
                                            icon: (e['vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                              'car${e['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                              'car${e['id']}'))
                                                  .position
                                                  .longitude,
                                              e['l'][0],
                                              e['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car${e['id']}'))
                                                        .position
                                                        .latitude !=
                                                    e['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car${e['id']}'))
                                                            .position
                                                            .longitude !=
                                                        e['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );
                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${e['id']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${e['id']}'))
                                                      .position
                                                      .longitude,
                                                  e['l'][0],
                                                  e['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  _controller,
                                                  'car${e['id']}',
                                                  e['id'],
                                                  (e['vehicle_type_icon'] ==
                                                          'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    } else if (((choosenTransportType == 1 && e['transport_type'] == 'delivery') ||
                                            choosenTransportType == 1 &&
                                                e['transport_type'] ==
                                                    'both') &&
                                        ((e['vehicle_types'] != null && ((widget.type != 1 && e['vehicle_types'].contains(etaDetails[choosenVehicle]['type_id'])) || (widget.type == 1 && e['vehicle_types'].contains(rentalOption[choosenVehicle]['type_id'])))) ||
                                            ((widget.type != 1 && e['vehicle_type'] == etaDetails[choosenVehicle]['type_id']) ||
                                                (widget.type == 1 &&
                                                    e['vehicle_type'] ==
                                                        rentalOption[choosenVehicle]
                                                            ['type_id'])))) {
                                      DateTime dt =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              e['updated_at']);
                                      if (DateTime.now()
                                              .difference(dt)
                                              .inMinutes <=
                                          2) {
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains('car${e['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId('car${e['id']}'),
                                            rotation: (myBearings[
                                                        e['id'].toString()] !=
                                                    null)
                                                ? myBearings[e['id'].toString()]
                                                : 0.0,
                                            position:
                                                LatLng(e['l'][0], e['l'][1]),
                                            icon: (e['vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                              'car${e['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                              'car${e['id']}'))
                                                  .position
                                                  .longitude,
                                              e['l'][0],
                                              e['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car${e['id']}'))
                                                        .position
                                                        .latitude !=
                                                    e['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car${e['id']}'))
                                                            .position
                                                            .longitude !=
                                                        e['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );
                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${e['id']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${e['id']}'))
                                                      .position
                                                      .longitude,
                                                  e['l'][0],
                                                  e['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  _controller,
                                                  'car${e['id']}',
                                                  e['id'],
                                                  (driverData['vehicle_type_icon'] ==
                                                          'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    } else {
                                      if (myMarker
                                          .where((element) => element.markerId
                                              .toString()
                                              .contains('car${e['id']}'))
                                          .isNotEmpty) {
                                        myMarker.removeWhere((element) =>
                                            element.markerId
                                                .toString()
                                                .contains('car${e['id']}'));
                                      }
                                    }
                                  } else {
                                    if (myMarker
                                        .where((element) => element.markerId
                                            .toString()
                                            .contains('car${e['id']}'))
                                        .isNotEmpty) {
                                      myMarker.removeWhere((element) => element
                                          .markerId
                                          .toString()
                                          .contains('car${e['id']}'));
                                    }
                                  }
                                });
                              }
                            }
                          }
                        }

                        return StreamBuilder<DatabaseEvent>(
                            stream: (userRequestData['driverDetail'] != null &&
                                    pinLocationIcon != null)
                                ? FirebaseDatabase.instance
                                    .ref(
                                        'drivers/driver_${userRequestData['driverDetail']['data']['id']}')
                                    .onValue
                                    .asBroadcastStream()
                                : null,
                            builder:
                                (context, AsyncSnapshot<DatabaseEvent> event) {
                              if (event.hasData) {
                                if (event.data!.snapshot.value != null) {
                                  if (userRequestData['accepted_at'] != null) {
                                    driversData.clear();
                                    if (myMarker.length > 3) {
                                      myMarker.removeWhere((element) => element
                                          .markerId
                                          .toString()
                                          .contains('car'));
                                    }

                                    DataSnapshot snapshots =
                                        event.data!.snapshot;
                                    // ignore: unnecessary_null_comparison
                                    if (snapshots != null) {
                                      driverData = jsonDecode(
                                          jsonEncode(snapshots.value));
                                      if (userRequestData != {}) {
                                        if (userRequestData['arrived_at'] ==
                                            null) {
                                          var distCalc = calculateDistance(
                                              userRequestData['pick_lat'],
                                              userRequestData['pick_lng'],
                                              driverData['l'][0],
                                              driverData['l'][1]);
                                          _dist = double.parse(
                                              (distCalc / 1000).toString());
                                        } else if (userRequestData[
                                                    'transport_type'] ==
                                                'taxi' &&
                                            userRequestData['is_rental'] !=
                                                true &&
                                            userRequestData['drop_lat'] !=
                                                null) {
                                          var distCalc = calculateDistance(
                                            driverData['l'][0],
                                            driverData['l'][1],
                                            userRequestData['drop_lat'],
                                            userRequestData['drop_lng'],
                                          );
                                          _dist = double.parse(
                                              (distCalc / 1000).toString());
                                        }
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains(
                                                    'car${driverData['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId(
                                                'car${driverData['id']}'),
                                            rotation: (myBearings[
                                                        driverData['id']
                                                            .toString()] !=
                                                    null)
                                                ? myBearings[
                                                    driverData['id'].toString()]
                                                : 0.0,
                                            position: LatLng(driverData['l'][0],
                                                driverData['l'][1]),
                                            icon: (driverData[
                                                        'vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car${driverData['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car${driverData['id']}'))
                                                  .position
                                                  .longitude,
                                              driverData['l'][0],
                                              driverData['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car${driverData['id']}'))
                                                        .position
                                                        .latitude !=
                                                    driverData['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car${driverData['id']}'))
                                                            .position
                                                            .longitude !=
                                                        driverData['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );

                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${driverData['id']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .firstWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${driverData['id']}'))
                                                      .position
                                                      .longitude,
                                                  driverData['l'][0],
                                                  driverData['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  _controller,
                                                  'car${driverData['id']}',
                                                  driverData['id'],
                                                  (driverData['vehicle_type_icon'] ==
                                                          'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      //get drivers location updates
                                      child: StreamBuilder<List<Marker>>(
                                          stream: mapMarkerStream,
                                          builder: (context, snapshot) {
                                            return GoogleMap(
                                              padding: EdgeInsets.only(
                                                  bottom: mapPadding,
                                                  top: media.height * 0.1 +
                                                      MediaQuery.of(context)
                                                          .padding
                                                          .top),
                                              onMapCreated: _onMapCreated,
                                              compassEnabled: false,
                                              initialCameraPosition:
                                                  CameraPosition(
                                                target: _center,
                                                zoom: 11.0,
                                              ),
                                              markers:
                                                  Set<Marker>.from(myMarker),
                                              polylines: polyline,
                                              minMaxZoomPreference:
                                                  const MinMaxZoomPreference(
                                                      0.0, 20.0),
                                              myLocationButtonEnabled: false,
                                              buildingsEnabled: false,
                                              zoomControlsEnabled: false,
                                              myLocationEnabled: true,
                                            );
                                          })),
                                  (userRequestData.isEmpty)
                                      ? Positioned(
                                          top: MediaQuery.of(context)
                                                  .padding
                                                  .top +
                                              12.5,
                                          child: SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (widget.type == null) {
                                                      if (dropConfirmed) {
                                                        setState(() {
                                                          dropConfirmed = false;
                                                        });
                                                      } else {
                                                        Navigator.pushAndRemoveUntil(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const Maps()),
                                                            (route) => false);
                                                        addressList.removeWhere(
                                                            (element) =>
                                                                element.id ==
                                                                'drop');
                                                        etaDetails.clear();
                                                        promoKey.clear();
                                                        promoStatus = null;
                                                        rentalOption.clear();
                                                        _rideLaterSuccess =
                                                            false;
                                                        myMarker.clear();
                                                        dropStopList.clear();
                                                      }
                                                    } else {
                                                      Navigator.pushAndRemoveUntil(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const Maps()),
                                                          (route) => false);
                                                      addressList.removeWhere(
                                                          (element) =>
                                                              element.id ==
                                                              'drop');
                                                      etaDetails.clear();
                                                      promoKey.clear();
                                                      promoStatus = null;
                                                      rentalOption.clear();
                                                      _rideLaterSuccess = false;
                                                      myMarker.clear();
                                                      dropStopList.clear();
                                                    }
                                                  },
                                                  child: Container(
                                                    height: media.width * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.2),
                                                              spreadRadius: 2,
                                                              blurRadius: 2)
                                                        ],
                                                        color: page),
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.arrow_back,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(),
                                  Positioned(
                                    bottom: media.width * 1.15,
                                    // top: media.width*0.2 + MediaQuery.of(context).padding.top,
                                    child: SizedBox(
                                      width: media.width * 0.9,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (userRequestData.isNotEmpty &&
                                              userRequestData['accepted_at'] !=
                                                  null)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () async {
                                                    await Share.share(
                                                        'Your Driver is ${userRequestData['driverDetail']['data']['name']}. ${userRequestData['driverDetail']['data']['car_color']} ${userRequestData['driverDetail']['data']['car_make_name']} ${userRequestData['driverDetail']['data']['car_model_name']}, Vehicle Number: ${userRequestData['driverDetail']['data']['car_number']}. Track with link: ${url}track/request/${userRequestData['id']}');
                                                  },
                                                  child: Container(
                                                      height: media.width * 0.1,
                                                      width: media.width * 0.1,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      media.width *
                                                                          0.02),
                                                          color: buttonColor),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Icon(
                                                        Icons.share,
                                                        size: media.width *
                                                            sixteen,
                                                        color: page,
                                                      )),
                                                ),
                                              ],
                                            ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          (userRequestData.isNotEmpty &&
                                                  userRequestData[
                                                          'is_trip_start'] ==
                                                      1)
                                              ? InkWell(
                                                  onTap: () async {
                                                    setState(() {
                                                      showSos = true;
                                                    });
                                                  },
                                                  child: Container(
                                                    height: media.width * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        boxShadow: [
                                                          BoxShadow(
                                                              blurRadius: 2,
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.2),
                                                              spreadRadius: 2)
                                                        ],
                                                        color: buttonColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(media
                                                                        .width *
                                                                    0.02)),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      'SOS',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize:
                                                                  media.width *
                                                                      fourteen,
                                                              color: page),
                                                    ),
                                                  ))
                                              : Container(),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          (etaDetails.isNotEmpty ||
                                                  userRequestData.isNotEmpty)
                                              ? InkWell(
                                                  onTap: () async {
                                                    if (locationAllowed ==
                                                        true) {
                                                      if (currentLocation !=
                                                          null) {
                                                        _controller?.animateCamera(
                                                            CameraUpdate
                                                                .newLatLngZoom(
                                                                    currentLocation,
                                                                    18.0));
                                                        center =
                                                            currentLocation;
                                                      } else {
                                                        _controller?.animateCamera(
                                                            CameraUpdate
                                                                .newLatLngZoom(
                                                                    center,
                                                                    18.0));
                                                      }
                                                    } else {
                                                      if (serviceEnabled ==
                                                          true) {
                                                        setState(() {
                                                          _locationDenied =
                                                              true;
                                                        });
                                                      } else {
                                                        await geolocs.Geolocator
                                                            .getCurrentPosition(
                                                                desiredAccuracy:
                                                                    geolocs
                                                                        .LocationAccuracy
                                                                        .low);
                                                        if (await geolocs
                                                            .GeolocatorPlatform
                                                            .instance
                                                            .isLocationServiceEnabled()) {
                                                          setState(() {
                                                            _locationDenied =
                                                                true;
                                                          });
                                                        }
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    height: media.width * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        boxShadow: [
                                                          BoxShadow(
                                                              blurRadius: 2,
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.2),
                                                              spreadRadius: 2)
                                                        ],
                                                        color: page,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(media
                                                                        .width *
                                                                    0.02)),
                                                    child: Icon(
                                                      Icons.my_location_sharp,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                )
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                  ),

                                  //show bottom nav bar for choosing ride type and vehicles
                                  (_isLoading == false &&
                                          addressList.isNotEmpty &&
                                          etaDetails.isNotEmpty &&
                                          userRequestData.isEmpty &&
                                          noDriverFound == false &&
                                          tripReqError == false &&
                                          dropConfirmed == true &&
                                          lowWalletBalance == false)
                                      ? (_chooseGoodsType == true ||
                                              choosenTransportType == 0)
                                          ? Positioned(
                                              bottom: 0 +
                                                  MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                padding: EdgeInsets.only(
                                                    top: media.width * 0.02,
                                                    bottom: media.width * 0.02),
                                                width: media.width * 1,
                                                height: (bottomChooseMethod ==
                                                            false &&
                                                        widget.type != 1)
                                                    ? media.width * 1
                                                    : (bottomChooseMethod ==
                                                                false &&
                                                            widget.type == 1)
                                                        ? media.height * 0.6
                                                        : media.height * 0.9,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: backgroundColor),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    20),
                                                            topRight:
                                                                Radius.circular(
                                                                    20)),
                                                    color: page),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.02,
                                                      ),
                                                      SizedBox(
                                                        width: media.width * 1,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Container(
                                                              margin: EdgeInsets.only(
                                                                  left: media
                                                                          .width *
                                                                      0.04,
                                                                  right: media
                                                                          .width *
                                                                      0.04),
                                                              // width: media.width *
                                                              //     0.9,
                                                              child: MyText(
                                                                text: languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_availablerides'],
                                                                size: media
                                                                        .width *
                                                                    sixteen,
                                                                fontweight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.02,
                                                      ),

                                                      (etaDetails.isNotEmpty &&
                                                              widget.type != 1)
                                                          ? SizedBox(
                                                              width:
                                                                  media.width *
                                                                      1,
                                                              // height:
                                                              //     media.width *
                                                              //         0.4,
                                                              child:
                                                                  SingleChildScrollView(
                                                                      // scrollDirection:
                                                                      //     Axis
                                                                      //         .horizontal,
                                                                      physics:
                                                                          const BouncingScrollPhysics(),
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          // Row(
                                                                          //   mainAxisAlignment:
                                                                          //       MainAxisAlignment.end,
                                                                          //   children: [
                                                                          //     Image.asset(
                                                                          //       'assets/images/right-arrow.png',
                                                                          //       height: 30,
                                                                          //     ),
                                                                          //   ],
                                                                          // ),
                                                                          SingleChildScrollView(
                                                                            scrollDirection:
                                                                                Axis.horizontal,
                                                                            child:
                                                                                Row(
                                                                              children: etaDetails
                                                                                  .asMap()
                                                                                  .map((i, value) {
                                                                                    return MapEntry(
                                                                                        i,
                                                                                        StreamBuilder<DatabaseEvent>(
                                                                                            stream: fdb.onValue,
                                                                                            builder: (context, AsyncSnapshot event) {
                                                                                              if (event.data != null) {
                                                                                                minutes[etaDetails[i]['type_id']] = '';
                                                                                                List vehicleList = [];
                                                                                                List vehicles = [];
                                                                                                List<double> minsList = [];
                                                                                                event.data!.snapshot.children.forEach((e) {
                                                                                                  vehicleList.add(e.value);
                                                                                                });
                                                                                                if (vehicleList.isNotEmpty) {
                                                                                                  // ignore: avoid_function_literals_in_foreach_calls
                                                                                                  vehicleList.forEach(
                                                                                                    (e) async {
                                                                                                      if (e['is_active'] == 1 && e['is_available'] == true && ((e['vehicle_types'] != null && e['vehicle_types'].contains(etaDetails[i]['type_id'])) || e['vehicle_type'] == etaDetails[i]['type_id'])) {
                                                                                                        DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                                        if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                                          vehicles.add(e);
                                                                                                          if (vehicles.isNotEmpty) {
                                                                                                            var dist = calculateDistance(addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);

                                                                                                            minsList.add(double.parse((dist / 1000).toString()));
                                                                                                            var minDist = minsList.reduce(min);
                                                                                                            if (minDist > 0 && minDist <= 1) {
                                                                                                              minutes[etaDetails[i]['type_id']] = '2 mins';
                                                                                                            } else if (minDist > 1 && minDist <= 3) {
                                                                                                              minutes[etaDetails[i]['type_id']] = '5 mins';
                                                                                                            } else if (minDist > 3 && minDist <= 5) {
                                                                                                              minutes[etaDetails[i]['type_id']] = '8 mins';
                                                                                                            } else if (minDist > 5 && minDist <= 7) {
                                                                                                              minutes[etaDetails[i]['type_id']] = '11 mins';
                                                                                                            } else if (minDist > 7 && minDist <= 10) {
                                                                                                              minutes[etaDetails[i]['type_id']] = '14 mins';
                                                                                                            } else if (minDist > 10) {
                                                                                                              minutes[etaDetails[i]['type_id']] = '15 mins';
                                                                                                            }
                                                                                                          } else {
                                                                                                            minutes[etaDetails[i]['type_id']] = '';
                                                                                                          }
                                                                                                        }
                                                                                                      }
                                                                                                    },
                                                                                                  );
                                                                                                } else {
                                                                                                  minutes[etaDetails[i]['type_id']] = '';
                                                                                                }
                                                                                              } else {
                                                                                                minutes[etaDetails[i]['type_id']] = '';
                                                                                              }
                                                                                              return InkWell(
                                                                                                onTap: () {
                                                                                                  setState(() {
                                                                                                    choosenVehicle = i;
                                                                                                  });
                                                                                                },
                                                                                                child: Container(
                                                                                                  padding: EdgeInsets.all(media.width * 0.02),
                                                                                                  margin: EdgeInsets.only(top: 10, left: media.width * 0.03, right: media.width * 0.03),
                                                                                                  height: media.width * 0.350,
                                                                                                  width: media.width * 0.350,
                                                                                                  decoration: BoxDecoration(
                                                                                                    border: Border.all(color: backgroundColor),
                                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                                    boxShadow: [
                                                                                                      BoxShadow(color: (isDarkTheme == true) ? Colors.white.withOpacity(0.2) : backgroundColor.withOpacity(0.2), spreadRadius: 2, blurRadius: 2)
                                                                                                    ],
                                                                                                    color: (choosenVehicle != i)
                                                                                                        ? (isDarkTheme == true)
                                                                                                            ? Colors.black
                                                                                                            : Colors.white
                                                                                                        : backgroundColor.withOpacity(0.07),
                                                                                                  ),
                                                                                                  child: Column(
                                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                    //  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                                    children: [
                                                                                                      (etaDetails[i]['icon'] != null)
                                                                                                          ? SizedBox(
                                                                                                              width: media.width * 0.15,
                                                                                                              child: Image.network(
                                                                                                                etaDetails[i]['icon'],
                                                                                                                fit: BoxFit.contain,
                                                                                                              ))
                                                                                                          : Container(),
                                                                                                      SizedBox(
                                                                                                        width: media.width * 0.05,
                                                                                                      ),
                                                                                                      Text(etaDetails[i]['name'],
                                                                                                          style: GoogleFonts.poppins(
                                                                                                              fontSize: media.width * fourteen,
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              color: (choosenVehicle != i)
                                                                                                                  ? (isDarkTheme == true)
                                                                                                                      ? hintColor
                                                                                                                      : textColor
                                                                                                                  : Colors.black)),
                                                                                                      Row(
                                                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                                                        children: [
                                                                                                          Icon(
                                                                                                            Icons.timelapse,
                                                                                                            size: media.width * 0.04,
                                                                                                            color: const Color(0xff8A8A8A),
                                                                                                          ),
                                                                                                          SizedBox(
                                                                                                            width: media.width * 0.01,
                                                                                                          ),
                                                                                                          (minutes[etaDetails[i]['type_id']] != null && minutes[etaDetails[i]['type_id']] != '')
                                                                                                              ? Text(
                                                                                                                  minutes[etaDetails[i]['type_id']].toString(),
                                                                                                                  style: GoogleFonts.poppins(fontSize: media.width * twelve, color: const Color(0xff8A8A8A)),
                                                                                                                )
                                                                                                              : Text(
                                                                                                                  '- -',
                                                                                                                  style: GoogleFonts.poppins(fontSize: media.width * twelve, color: (choosenVehicle != i) ? textColor.withOpacity(0.7) : hintColor.withOpacity(0.4)),
                                                                                                                ),
                                                                                                          SizedBox(
                                                                                                            width: media.width * 0.01,
                                                                                                          ),
                                                                                                          InkWell(
                                                                                                              onTap: () {
                                                                                                                setState(() {
                                                                                                                  _showInfoInt = i;
                                                                                                                  _showInfo = true;
                                                                                                                });
                                                                                                              },
                                                                                                              child: Icon(
                                                                                                                Icons.info_outline,
                                                                                                                size: media.width * 0.04,
                                                                                                                color: const Color(0xff8A8A8A),
                                                                                                              ))
                                                                                                        ],
                                                                                                      ),
                                                                                                      (widget.type != 2)
                                                                                                          ? Expanded(
                                                                                                              child: (etaDetails[i]['has_discount'] != true || etaDetails[i]['enable_bidding'] == true)
                                                                                                                  ? Row(
                                                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                      children: [
                                                                                                                        Text(
                                                                                                                          etaDetails[i]['currency'] + etaDetails[i]['total'].toStringAsFixed(2),
                                                                                                                          style: GoogleFonts.poppins(
                                                                                                                              fontSize: media.width * fourteen,
                                                                                                                              fontWeight: FontWeight.w600,
                                                                                                                              color: (choosenVehicle != i)
                                                                                                                                  ? (isDarkTheme == true)
                                                                                                                                      ? Colors.white
                                                                                                                                      : textColor
                                                                                                                                  : Colors.black),
                                                                                                                        ),
                                                                                                                      ],
                                                                                                                    )
                                                                                                                  : Row(
                                                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                      children: [
                                                                                                                        Text(
                                                                                                                          etaDetails[i]['currency'] + ' ',
                                                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: (choosenVehicle != i) ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                                                                                                                        ),
                                                                                                                        Column(
                                                                                                                          children: [
                                                                                                                            Text(
                                                                                                                              etaDetails[i]['total'].toStringAsFixed(2),
                                                                                                                              style: GoogleFonts.poppins(
                                                                                                                                  fontSize: media.width * fourteen,
                                                                                                                                  color: (choosenVehicle != i)
                                                                                                                                      ? (isDarkTheme == true)
                                                                                                                                          ? Colors.white
                                                                                                                                          : textColor
                                                                                                                                      : Colors.black,
                                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                                  decoration: TextDecoration.lineThrough),
                                                                                                                            ),
                                                                                                                            Text(
                                                                                                                              '${etaDetails[i]['discounted_totel'].toStringAsFixed(2)}',
                                                                                                                              style: GoogleFonts.poppins(
                                                                                                                                  fontSize: media.width * fourteen,
                                                                                                                                  color: (choosenVehicle != i)
                                                                                                                                      ? (isDarkTheme == true)
                                                                                                                                          ? Colors.white
                                                                                                                                          : textColor
                                                                                                                                      : Colors.black,
                                                                                                                                  fontWeight: FontWeight.w600),
                                                                                                                            )
                                                                                                                          ],
                                                                                                                        ),
                                                                                                                      ],
                                                                                                                    ))
                                                                                                          : Container()
                                                                                                    ],
                                                                                                  ),
                                                                                                ),
                                                                                              );
                                                                                            }));
                                                                                  })
                                                                                  .values
                                                                                  .toList(),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      )))
                                                          : (etaDetails
                                                                      .isNotEmpty &&
                                                                  widget.type ==
                                                                      1)
                                                              ? Expanded(
                                                                  child: SizedBox(
                                                                      width: media.width * 1,
                                                                      child: Column(
                                                                        children: [
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.025,
                                                                          ),
                                                                          SizedBox(
                                                                              width: media.width * 0.9,
                                                                              child: SingleChildScrollView(
                                                                                scrollDirection: Axis.horizontal,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  children: etaDetails
                                                                                      .asMap()
                                                                                      .map((i, value) {
                                                                                        return MapEntry(
                                                                                            i,
                                                                                            Container(
                                                                                              margin: EdgeInsets.only(right: media.width * 0.05),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: (rentalChoosenOption == i) ? buttonColor : borderLines),
                                                                                              padding: EdgeInsets.all(media.width * 0.02),
                                                                                              child: InkWell(
                                                                                                onTap: () {
                                                                                                  setState(() {
                                                                                                    rentalOption = etaDetails[i]['typesWithPrice']['data'];
                                                                                                    rentalChoosenOption = i;
                                                                                                    choosenVehicle = null;
                                                                                                    payingVia = 0;
                                                                                                  });
                                                                                                },
                                                                                                child: Text(
                                                                                                  etaDetails[i]['package_name'],
                                                                                                  style: GoogleFonts.poppins(fontSize: media.width * sixteen, fontWeight: FontWeight.w600, color: (rentalChoosenOption == i) ? Colors.black : Colors.black),
                                                                                                ),
                                                                                              ),
                                                                                            ));
                                                                                      })
                                                                                      .values
                                                                                      .toList(),
                                                                                ),
                                                                              )),
                                                                          SizedBox(
                                                                              height: media.width * 0.02),
                                                                          Expanded(
                                                                            child:
                                                                                SizedBox(
                                                                              width: media.width * 0.9,
                                                                              child: SingleChildScrollView(
                                                                                // scrollDirection:
                                                                                //     Axis.horizontal,
                                                                                physics: const BouncingScrollPhysics(),
                                                                                child: Column(
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    children: rentalOption
                                                                                        .asMap()
                                                                                        .map((i, value) {
                                                                                          return MapEntry(
                                                                                              i,
                                                                                              StreamBuilder<DatabaseEvent>(
                                                                                                  stream: fdb.onValue,
                                                                                                  builder: (context, AsyncSnapshot event) {
                                                                                                    if (event.data != null) {
                                                                                                      minutes[rentalOption[i]['type_id']] = '';
                                                                                                      List vehicleList = [];
                                                                                                      List vehicles = [];
                                                                                                      List<double> minsList = [];
                                                                                                      event.data!.snapshot.children.forEach((e) {
                                                                                                        vehicleList.add(e.value);
                                                                                                      });
                                                                                                      if (vehicleList.isNotEmpty) {
                                                                                                        // ignore: avoid_function_literals_in_foreach_calls
                                                                                                        vehicleList.forEach(
                                                                                                          (e) async {
                                                                                                            if (e['is_active'] == 1 && e['is_available'] == true && ((e['vehicle_types'] != null && e['vehicle_types'].contains(rentalOption[i]['type_id'])) || e['vehicle_type'] == rentalOption[i]['type_id'])) {
                                                                                                              DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                                              if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                                                vehicles.add(e);
                                                                                                                if (vehicles.isNotEmpty) {
                                                                                                                  var dist = calculateDistance(addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);

                                                                                                                  minsList.add(double.parse((dist / 1000).toString()));
                                                                                                                  var minDist = minsList.reduce(min);
                                                                                                                  if (minDist > 0 && minDist <= 1) {
                                                                                                                    minutes[rentalOption[i]['type_id']] = '2 mins';
                                                                                                                  } else if (minDist > 1 && minDist <= 3) {
                                                                                                                    minutes[rentalOption[i]['type_id']] = '5 mins';
                                                                                                                  } else if (minDist > 3 && minDist <= 5) {
                                                                                                                    minutes[rentalOption[i]['type_id']] = '8 mins';
                                                                                                                  } else if (minDist > 5 && minDist <= 7) {
                                                                                                                    minutes[rentalOption[i]['type_id']] = '11 mins';
                                                                                                                  } else if (minDist > 7 && minDist <= 10) {
                                                                                                                    minutes[rentalOption[i]['type_id']] = '14 mins';
                                                                                                                  } else if (minDist > 10) {
                                                                                                                    minutes[rentalOption[i]['type_id']] = '15 mins';
                                                                                                                  }
                                                                                                                } else {
                                                                                                                  minutes[rentalOption[i]['type_id']] = '';
                                                                                                                }
                                                                                                              }
                                                                                                            }
                                                                                                          },
                                                                                                        );
                                                                                                      } else {
                                                                                                        minutes[rentalOption[i]['type_id']] = '';
                                                                                                      }
                                                                                                    } else {
                                                                                                      minutes[rentalOption[i]['type_id']] = '';
                                                                                                    }
                                                                                                    return InkWell(
                                                                                                        onTap: () {
                                                                                                          setState(() {
                                                                                                            choosenVehicle = i;
                                                                                                          });
                                                                                                        },
                                                                                                        child: Container(
                                                                                                          padding: EdgeInsets.all(media.width * 0.02),
                                                                                                          margin: EdgeInsets.only(top: 10, left: media.width * 0.05, right: media.width * 0.05),
                                                                                                          height: media.width * 0.152,
                                                                                                          decoration: BoxDecoration(
                                                                                                            borderRadius: BorderRadius.circular(12),
                                                                                                            boxShadow: [
                                                                                                              BoxShadow(color: (isDarkTheme == true) ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2), spreadRadius: 2, blurRadius: 2)
                                                                                                            ],
                                                                                                            color: (choosenVehicle != i)
                                                                                                                ? (isDarkTheme == true)
                                                                                                                    ? Colors.black
                                                                                                                    : Colors.white
                                                                                                                : const Color(0xffF3F3F3),
                                                                                                          ),
                                                                                                          child: Row(
                                                                                                            children: [
                                                                                                              (rentalOption[i]['icon'] != null)
                                                                                                                  ? SizedBox(
                                                                                                                      width: media.width * 0.1,
                                                                                                                      child: Image.network(
                                                                                                                        rentalOption[i]['icon'],
                                                                                                                        fit: BoxFit.contain,
                                                                                                                      ))
                                                                                                                  : Container(),
                                                                                                              SizedBox(
                                                                                                                width: media.width * 0.05,
                                                                                                              ),
                                                                                                              Column(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                                                children: [
                                                                                                                  Text(rentalOption[i]['name'],
                                                                                                                      style: GoogleFonts.poppins(
                                                                                                                          fontSize: media.width * fourteen,
                                                                                                                          fontWeight: FontWeight.w600,
                                                                                                                          color: (choosenVehicle != i)
                                                                                                                              ? (isDarkTheme == true)
                                                                                                                                  ? hintColor
                                                                                                                                  : textColor
                                                                                                                              : Colors.black)),
                                                                                                                  Row(
                                                                                                                    children: [
                                                                                                                      Icon(
                                                                                                                        Icons.timelapse,
                                                                                                                        size: media.width * 0.04,
                                                                                                                        color: const Color(0xff8A8A8A),
                                                                                                                      ),
                                                                                                                      SizedBox(
                                                                                                                        width: media.width * 0.01,
                                                                                                                      ),
                                                                                                                      (minutes[rentalOption[i]['type_id']] != null && minutes[rentalOption[i]['type_id']] != '')
                                                                                                                          ? Text(
                                                                                                                              minutes[rentalOption[i]['type_id']].toString(),
                                                                                                                              style: GoogleFonts.poppins(fontSize: media.width * twelve, color: const Color(0xff8A8A8A)),
                                                                                                                            )
                                                                                                                          : Text(
                                                                                                                              '- -',
                                                                                                                              style: GoogleFonts.poppins(fontSize: media.width * twelve, color: (choosenVehicle != i) ? textColor.withOpacity(0.7) : hintColor.withOpacity(0.4)),
                                                                                                                            ),
                                                                                                                      SizedBox(
                                                                                                                        width: media.width * 0.01,
                                                                                                                      ),
                                                                                                                      InkWell(
                                                                                                                          onTap: () {
                                                                                                                            setState(() {
                                                                                                                              _showInfoInt = i;
                                                                                                                              _showInfo = true;
                                                                                                                            });
                                                                                                                          },
                                                                                                                          child: Icon(
                                                                                                                            Icons.info_outline,
                                                                                                                            size: media.width * 0.04,
                                                                                                                            color: const Color(0xff8A8A8A),
                                                                                                                          ))
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                ],
                                                                                                              ),
                                                                                                              Expanded(
                                                                                                                  child: (rentalOption[i]['has_discount'] != true)
                                                                                                                      ? Row(
                                                                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                          children: [
                                                                                                                            Text(
                                                                                                                              rentalOption[i]['currency'] + ' ' + rentalOption[i]['fare_amount'].toStringAsFixed(2),
                                                                                                                              style: GoogleFonts.poppins(
                                                                                                                                  fontSize: media.width * fourteen,
                                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                                  color: (choosenVehicle != i)
                                                                                                                                      ? (isDarkTheme == true)
                                                                                                                                          ? Colors.white
                                                                                                                                          : textColor
                                                                                                                                      : Colors.black),
                                                                                                                            ),
                                                                                                                          ],
                                                                                                                        )
                                                                                                                      : Row(
                                                                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                          children: [
                                                                                                                            Text(
                                                                                                                              rentalOption[i]['currency'] + ' ',
                                                                                                                              style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: (choosenVehicle != i) ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                                                                                                                            ),
                                                                                                                            Column(
                                                                                                                              children: [
                                                                                                                                Text(
                                                                                                                                  rentalOption[i]['currency'] + ' ' + rentalOption[i]['fare_amount'].toStringAsFixed(2),
                                                                                                                                  style: GoogleFonts.poppins(
                                                                                                                                      fontSize: media.width * fourteen,
                                                                                                                                      color: (choosenVehicle != i)
                                                                                                                                          ? (isDarkTheme == true)
                                                                                                                                              ? Colors.white
                                                                                                                                              : textColor
                                                                                                                                          : Colors.black,
                                                                                                                                      fontWeight: FontWeight.w600,
                                                                                                                                      decoration: TextDecoration.lineThrough),
                                                                                                                                ),
                                                                                                                                Text(
                                                                                                                                  rentalOption[i]['currency'] + ' ' + rentalOption[i]['discounted_totel'].toStringAsFixed(2),
                                                                                                                                  style: GoogleFonts.poppins(
                                                                                                                                      fontSize: media.width * fourteen,
                                                                                                                                      color: (choosenVehicle != i)
                                                                                                                                          ? (isDarkTheme == true)
                                                                                                                                              ? Colors.white
                                                                                                                                              : textColor
                                                                                                                                          : Colors.black,
                                                                                                                                      fontWeight: FontWeight.w600),
                                                                                                                                )
                                                                                                                              ],
                                                                                                                            ),
                                                                                                                          ],
                                                                                                                        ))
                                                                                                            ],
                                                                                                          ),
                                                                                                        ));
                                                                                                  }));
                                                                                        })
                                                                                        .values
                                                                                        .toList()),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      )),
                                                                )
                                                              : Container(),

                                                      // Container(
                                                      //   height: 1,
                                                      //   width: media.width * 0.9,
                                                      //   color: borderLines,
                                                      // ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.02,
                                                      ),
                                                      (choosenVehicle != null &&
                                                              widget.type != 1)
                                                          ? Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      0,
                                                                      25,
                                                                      0,
                                                                      0),
                                                              height:
                                                                  media.width *
                                                                      0.106,
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              decoration: BoxDecoration(
                                                                  color: (isDarkTheme ==
                                                                          true)
                                                                      ? page
                                                                      : Colors
                                                                          .white,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5),
                                                                  border: Border
                                                                      .all(
                                                                          color:
                                                                              backgroundColor)),
                                                              child:
                                                                  SingleChildScrollView(
                                                                scrollDirection:
                                                                    Axis.horizontal,
                                                                child: Row(
                                                                  children: etaDetails[
                                                                              choosenVehicle]
                                                                          [
                                                                          'payment_type']
                                                                      .toString()
                                                                      .split(
                                                                          ',')
                                                                      .toList()
                                                                      .asMap()
                                                                      .map((i,
                                                                          value) {
                                                                        return MapEntry(
                                                                            i,
                                                                            InkWell(
                                                                              onTap: () {
                                                                                // if (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card' && selectedPaymentIndex == null) {
                                                                                //   _showCardModal(context, i);
                                                                                //   return;
                                                                                // } else if (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card' && selectedPaymentIndex != null) {
                                                                                //   _showCardModal(context, i);
                                                                                //   return;
                                                                                // } else {
                                                                                setState(() {
                                                                                  payingVia = i;
                                                                                  // selectedPaymentIndex = null;
                                                                                });
                                                                                // }
                                                                              },
                                                                              child: Container(
                                                                                height: media.width * 0.106,
                                                                                width: etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList().length == 2 ? media.width * 0.45 : media.width * 0.3,
                                                                                decoration: BoxDecoration(color: (payingVia == i) ? backgroundColor.withOpacity(0.2) : Colors.transparent, border: Border(right: BorderSide(color: (i < etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList().length - 1) ? backgroundColor : Colors.transparent, width: 1.1))),
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                  children: [
                                                                                    // (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                    //     ? Image.asset(
                                                                                    //         'assets/images/cash.png',
                                                                                    //         width: media.width * 0.037,
                                                                                    //         height: media.width * 0.037,
                                                                                    //         fit: BoxFit.contain,
                                                                                    //         color: (payingVia == i)
                                                                                    //             ? backgroundColor
                                                                                    //             : (isDarkTheme == true)
                                                                                    //                 ? Colors.white
                                                                                    //                 : Colors.black,
                                                                                    //       )
                                                                                    //     : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                    //         ? Image.asset(
                                                                                    //             'assets/images/wallet.png',
                                                                                    //             width: media.width * 0.037,
                                                                                    //             height: media.width * 0.037,
                                                                                    //             color: (payingVia == i)
                                                                                    //                 ? backgroundColor
                                                                                    //                 : (isDarkTheme == true)
                                                                                    //                     ? Colors.white
                                                                                    //                     : Colors.black,
                                                                                    //             fit: BoxFit.contain,
                                                                                    //           )
                                                                                    //         : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                    //             ? Image.asset(
                                                                                    //                 'assets/images/card.png',
                                                                                    //                 width: media.width * 0.037,
                                                                                    //                 height: media.width * 0.037,
                                                                                    //                 color: (payingVia == i)
                                                                                    //                     ? const Color.fromARGB(255, 0, 204, 255)
                                                                                    //                     : (isDarkTheme == true)
                                                                                    //                         ? Colors.white
                                                                                    //                         : Colors.black,
                                                                                    //                 fit: BoxFit.contain,
                                                                                    //               )
                                                                                    //             : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                    //                 ? Image.asset(
                                                                                    //                     'assets/images/upi.png',
                                                                                    //                     width: media.width * 0.037,
                                                                                    //                     height: media.width * 0.037,
                                                                                    //                     color: (payingVia == i)
                                                                                    //                         ? backgroundColor
                                                                                    //                         : (isDarkTheme == true)
                                                                                    //                             ? Colors.white
                                                                                    //                             : Colors.black,
                                                                                    //                     fit: BoxFit.contain,
                                                                                    //                   )
                                                                                    //                 : Container(),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.02,
                                                                                    ),
                                                                                    MyText(
                                                                                      text: etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i],
                                                                                      size: media.width * fourteen,
                                                                                      fontweight: FontWeight.bold,
                                                                                      color: (payingVia == i)
                                                                                          ? backgroundColor
                                                                                          : (isDarkTheme == true)
                                                                                              ? Colors.white
                                                                                              : Colors.black,
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ));
                                                                      })
                                                                      .values
                                                                      .toList(),
                                                                ),
                                                              ),
                                                            )
                                                          : (choosenVehicle !=
                                                                      null &&
                                                                  widget.type ==
                                                                      1)
                                                              ? Container(
                                                                  height: media
                                                                          .width *
                                                                      0.106,
                                                                  width: media
                                                                          .width *
                                                                      0.9,
                                                                  color: (isDarkTheme ==
                                                                          true)
                                                                      ? page
                                                                      : const Color(
                                                                          0xffF3F3F3),
                                                                  child:
                                                                      SingleChildScrollView(
                                                                    scrollDirection:
                                                                        Axis.horizontal,
                                                                    child: Row(
                                                                      children: rentalOption[choosenVehicle]
                                                                              [
                                                                              'payment_type']
                                                                          .toString()
                                                                          .split(
                                                                              ',')
                                                                          .toList()
                                                                          .asMap()
                                                                          .map((i,
                                                                              value) {
                                                                            return MapEntry(
                                                                                i,
                                                                                InkWell(
                                                                                  onTap: () {
                                                                                    // if (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card' && selectedPaymentIndex == null) {
                                                                                    //   _showCardModal(context, i);
                                                                                    //   return;
                                                                                    // } else if (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card' && selectedPaymentIndex != null) {
                                                                                    //   _showCardModal(context, i);
                                                                                    //   return;
                                                                                    // } else {
                                                                                    setState(() {
                                                                                      payingVia = i;
                                                                                      // selectedPaymentIndex = null;
                                                                                    });
                                                                                    // }
                                                                                  },
                                                                                  child: Container(
                                                                                    height: media.width * 0.106,
                                                                                    width: media.width * 0.3,
                                                                                    decoration: BoxDecoration(border: Border(right: BorderSide(color: (i < rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList().length - 1) ? const Color(0xffE7EDEF) : Colors.transparent, width: 1.1))),
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                      children: [
                                                                                        (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                            ? Image.asset(
                                                                                                'assets/images/cash.png',
                                                                                                width: media.width * 0.037,
                                                                                                height: media.width * 0.037,
                                                                                                fit: BoxFit.contain,
                                                                                                color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                              )
                                                                                            : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                ? Image.asset(
                                                                                                    'assets/images/wallet.png',
                                                                                                    width: media.width * 0.037,
                                                                                                    height: media.width * 0.037,
                                                                                                    color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                                    fit: BoxFit.contain,
                                                                                                  )
                                                                                                : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                    ? Image.asset(
                                                                                                        'assets/images/card.png',
                                                                                                        width: media.width * 0.037,
                                                                                                        height: media.width * 0.037,
                                                                                                        color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                                        fit: BoxFit.contain,
                                                                                                      )
                                                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                        ? Image.asset(
                                                                                                            'assets/images/upi.png',
                                                                                                            width: media.width * 0.037,
                                                                                                            height: media.width * 0.037,
                                                                                                            color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                                            fit: BoxFit.contain,
                                                                                                          )
                                                                                                        : Container(),
                                                                                        SizedBox(
                                                                                          width: media.width * 0.02,
                                                                                        ),
                                                                                        MyText(
                                                                                          text: rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i],
                                                                                          size: media.width * fourteen,
                                                                                          color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ));
                                                                          })
                                                                          .values
                                                                          .toList(),
                                                                    ),
                                                                  ),
                                                                )
                                                              : Container(),

                                                      // (selectedPaymentIndex !=
                                                      //             null &&
                                                      //         selectedPaymentIndex
                                                      //             is Map &&
                                                      //         selectedPaymentIndex
                                                      //             .containsKey(
                                                      //                 'card'))
                                                      //     ? Padding(
                                                      //         padding:
                                                      //             EdgeInsets.only(
                                                      //                 top:
                                                      //                     16.0), // Adjust the top margin as needed
                                                      //         child:
                                                      //             GestureDetector(
                                                      //                 onTap: () {
                                                      //                   _showCardModal(
                                                      //                       context,
                                                      //                       payingVia);
                                                      //                 },
                                                      //                 child:
                                                      //                     Container(
                                                      //                   height: media
                                                      //                           .width *
                                                      //                       0.106,
                                                      //                   width: media
                                                      //                           .width *
                                                      //                       0.9,
                                                      //                   decoration:
                                                      //                       BoxDecoration(
                                                      //                     borderRadius:
                                                      //                         BorderRadius.circular(12.0), // Adjust the radius as needed
                                                      //                     color: (isDarkTheme ==
                                                      //                             true)
                                                      //                         ? page
                                                      //                         : const Color(0xffF3F3F3),
                                                      //                   ),
                                                      //                   // color: (isDarkTheme == true) ? page : const Color(0xffF3F3F3),
                                                      //                   child:
                                                      //                       SingleChildScrollView(
                                                      //                     scrollDirection:
                                                      //                         Axis.horizontal,
                                                      //                     child:
                                                      //                         Row(
                                                      //                       children: [
                                                      //                         // Add your SVG for the card here
                                                      //
                                                      //                         // Display card brand
                                                      //                         if (selectedPaymentIndex != null &&
                                                      //                             selectedPaymentIndex is Map &&
                                                      //                             selectedPaymentIndex.containsKey('card'))
                                                      //                           Padding(
                                                      //                             padding: EdgeInsets.symmetric(horizontal: 8.0), // Adjust the padding as needed
                                                      //                             child: Row(
                                                      //                               children: [
                                                      //                                 Image.asset(
                                                      //                                   'assets/images/card.png',
                                                      //                                   width: media.width * 0.037,
                                                      //                                   height: media.width * 0.037,
                                                      //                                   color: Colors.black,
                                                      //                                   fit: BoxFit.contain,
                                                      //                                 ),
                                                      //                                 SizedBox(width: 8.0), // Adjust the space between image and text as needed
                                                      //                                 Text(
                                                      //                                   '${selectedPaymentIndex['card']['brand']} (**** **** **** ${selectedPaymentIndex['card']['last4']})',
                                                      //                                   style: GoogleFonts.roboto(
                                                      //                                     fontSize: media.width * fourteen,
                                                      //                                     fontWeight: FontWeight.w600,
                                                      //                                     color: buttonColor,
                                                      //                                   ),
                                                      //                                 ),
                                                      //                               ],
                                                      //                             ),
                                                      //                           ),
                                                      //                       ],
                                                      //                     ),
                                                      //                   ),
                                                      //                 )),
                                                      //       )
                                                      //     : Container(),

                                                   
                                                      (choosenVehicle != null &&
                                                              (widget.type ==
                                                                      1 ||
                                                                  etaDetails[choosenVehicle]
                                                                          [
                                                                          'enable_bidding'] ==
                                                                      false))
                                                          ? InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _addCoupon =
                                                                      true;
                                                                });
                                                              },
                                                              child: (_addCoupon ==
                                                                      false)
                                                                  ? Container(
                                                                      height: media
                                                                              .width *
                                                                          0.106,
                                                                      width: media
                                                                              .width *
                                                                          0.9,
                                                                      decoration:
                                                                          const BoxDecoration(
                                                                              border: Border(bottom: BorderSide(color: Color(0xffF3F3F3), width: 1.1))),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          MyText(
                                                                            text:
                                                                                languages[choosenLanguage]['text_coupons'],
                                                                            size:
                                                                                media.width * fourteen,
                                                                            fontweight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                          Icon(
                                                                            Icons.arrow_forward_ios,
                                                                            color:
                                                                                textColor,
                                                                            size:
                                                                                media.width * 0.04,
                                                                          )
                                                                        ],
                                                                      ),
                                                                    )
                                                                  : Container(
                                                                      padding: EdgeInsets.only(
                                                                          top: media.width *
                                                                              0.02),
                                                                      height: media
                                                                              .width *
                                                                          0.106,
                                                                      width: media
                                                                              .width *
                                                                          0.9,
                                                                      color: (isDarkTheme ==
                                                                              true)
                                                                          ? Colors
                                                                              .black
                                                                          : const Color(
                                                                              0xffF3F3F3),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceEvenly,
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.25,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                MyText(text: languages[choosenLanguage]['text_coupons'], size: media.width * fourteen, color: textColor),
                                                                                Icon(
                                                                                  Icons.card_giftcard_outlined,
                                                                                  size: media.width * fourteen,
                                                                                  color: (isDarkTheme == true) ? const Color(0xFFFF0000) : buttonColor,
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          (promoStatus != 1)
                                                                              ? Container(
                                                                                  width: media.width * 0.25,
                                                                                  height: media.width * 0.090,
                                                                                  padding: EdgeInsets.all(media.width * 0.010),
                                                                                  decoration: BoxDecoration(color: page, border: Border.all(color: textColor.withOpacity(0.4)), borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                                  child: TextField(
                                                                                    controller: promoKey,
                                                                                    decoration: const InputDecoration(border: InputBorder.none),
                                                                                    onChanged: (val) {
                                                                                      promoCode = val;
                                                                                    },
                                                                                  ),
                                                                                )
                                                                              : const Icon(
                                                                                  Icons.done,
                                                                                  color: Colors.green,
                                                                                ),
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.25,
                                                                            height:
                                                                                media.width * 0.090,
                                                                            child:
                                                                                Button(
                                                                              text: (promoStatus != 1) ? languages[choosenLanguage]['text_apply'] : languages[choosenLanguage]['text_remove'],
                                                                              fontweight: FontWeight.w500,
                                                                              onTap: () async {
                                                                                FocusScope.of(context).unfocus();
                                                                                setState(() {
                                                                                  _isLoading = true;
                                                                                });
                                                                                if (promoStatus != 1) {
                                                                                  setState(() {
                                                                                    promoStatus = null;
                                                                                  });
                                                                                  if (widget.type != 1 && promoKey.text.isNotEmpty) {
                                                                                    await etaRequestWithPromo();
                                                                                  } else if (widget.type == 1 && promoKey.text.isNotEmpty) {
                                                                                    await rentalRequestWithPromo();
                                                                                  }
                                                                                } else {
                                                                                  promoKey.text = '';
                                                                                  promoStatus = null;
                                                                                  if (widget.type != 1) {
                                                                                    await etaRequest();
                                                                                  } else if (widget.type == 1) {
                                                                                    await rentalEta();
                                                                                  }
                                                                                }
                                                                                setState(() {
                                                                                  _isLoading = false;
                                                                                });
                                                                              },
                                                                              color: const Color(0xffFF0000),
                                                                              textcolor: Colors.black,
                                                                              borderRadius: 12.0,
                                                                            ),
                                                                          ),
                                                                          InkWell(
                                                                              onTap: () {
                                                                                setState(() {
                                                                                  promoStatus = false;
                                                                                  _addCoupon = false;
                                                                                });
                                                                              },
                                                                              child: const Icon(
                                                                                Icons.cancel,
                                                                                color: Color(0xffFF0000),
                                                                              ))
                                                                        ],
                                                                      ),
                                                                    ),
                                                            )
                                                          : Container(),
                                                      if (promoStatus != null &&
                                                          promoStatus == 2 &&
                                                          etaDetails[choosenVehicle]
                                                                  [
                                                                  'enable_bidding'] ==
                                                              false)
                                                        Container(
                                                          width:
                                                              media.width * 0.9,
                                                          padding:
                                                              EdgeInsets.only(
                                                                  top: media
                                                                          .width *
                                                                      0.025),
                                                          child: MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_promorejected'],
                                                            size: media.width *
                                                                twelve,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      (choosenVehicle != null)
                                                          ? SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.025,
                                                            )
                                                          : Container(),
                                                      (selectedGoodsId == '' &&
                                                              choosenTransportType ==
                                                                  1)
                                                          ? Container()
                                                          : SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.01,
                                                            ),
                                                      (selectedGoodsId == '' &&
                                                              choosenTransportType ==
                                                                  1)
                                                          ? Button(
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              onTap: () async {
                                                                var val = await Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                const ChooseGoods()));
                                                                if (val) {
                                                                  setState(
                                                                      () {});
                                                                }
                                                              },
                                                              text: languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_choose_goods'],
                                                            )
                                                          : SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  (userDetails['show_ride_later_feature'] == true &&
                                                                          ((widget.type == null)
                                                                              ? etaDetails[choosenVehicle]['enable_bidding'] ==
                                                                                  false
                                                                              : true))
                                                                      ? Button(
                                                                          color:
                                                                              page,
                                                                          borcolor:
                                                                              buttonColor,
                                                                          textcolor:
                                                                              buttonColor,
                                                                          width: media.width *
                                                                              0.42,
                                                                          onTap:
                                                                              () async {
                                                                            if (choosenVehicle !=
                                                                                null) {
                                                                              setState(() {
                                                                                choosenDateTime = DateTime.now().add(const Duration(minutes: 30));
                                                                                _dateTimePicker = true;
                                                                              });
                                                                            }
                                                                          },
                                                                          text: languages[choosenLanguage]
                                                                              [
                                                                              'text_ridelater'])
                                                                      : Container(),
                                                                  Button(
                                                                      width: ((userDetails['show_ride_later_feature'] ==
                                                                              true))
                                                                          ? ((widget.type == null)
                                                                                  ? etaDetails[choosenVehicle]['enable_bidding'] ==
                                                                                      false
                                                                                  : true)
                                                                              ? media.width *
                                                                                  0.42
                                                                              : media.width *
                                                                                  0.89
                                                                          : media.width *
                                                                              0.89,
                                                                      color:
                                                                          buttonColor,
                                                                      onTap:
                                                                          () async {
                                                                        // if (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                        //         'card' &&
                                                                        //     selectedPaymentIndex ==
                                                                        //         null) {
                                                                        //   _showCardModal(
                                                                        //       context,
                                                                        //       payingVia);
                                                                        //   return;
                                                                        // }
                                                                        if (((rentalOption.isEmpty && (double.parse(etaDetails[choosenVehicle]['user_wallet_balance'].toString()) >= etaDetails[choosenVehicle]['total'] && etaDetails[choosenVehicle]['has_discount'] == false) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['has_discount'] == true && etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['discounted_totel'])) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet')) ||
                                                                            ((rentalOption.isNotEmpty && etaDetails[0]['user_wallet_balance'] >= rentalOption[choosenVehicle]['fare_amount'] && rentalOption[choosenVehicle]['has_discount'] == false) ||
                                                                                (rentalOption.isNotEmpty && rentalOption[choosenVehicle]['has_discount'] == true && rentalOption[choosenVehicle]['user_wallet_balance'] >= rentalOption[choosenVehicle]['discounted_totel']) ||
                                                                                (rentalOption.isNotEmpty && rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet'))) {
                                                                          if ((widget.type == null)
                                                                              ? etaDetails[choosenVehicle]['enable_bidding'] == true
                                                                              : false) {
                                                                            setState(() {
                                                                              _showInfoInt = choosenVehicle;
                                                                              _showInfo = true;
                                                                              yourAmount.text = etaDetails[choosenVehicle]['total'].toStringAsFixed(0);
                                                                            });
                                                                          } else {
                                                                            setState(() {
                                                                              _isLoading = true;
                                                                            });

                                                                            dynamic
                                                                                result;
                                                                            if (choosenVehicle !=
                                                                                null) {
                                                                              if (widget.type != 1) {
                                                                                if (etaDetails[choosenVehicle]['has_discount'] == false) {
                                                                                  if (choosenTransportType == 0) {
                                                                                    dropStopList.clear();
                                                                                    if (addressList.length > 2) {
                                                                                      for (var i = 1; i < addressList.length; i++) {
                                                                                        dropStopList.add(DropStops(
                                                                                          order: addressList[i].id,
                                                                                          latitude: addressList[i].latlng.latitude,
                                                                                          longitude: addressList[i].latlng.longitude,
                                                                                          address: addressList[i].address,
                                                                                        ));
                                                                                      }
                                                                                      result = await createRequest(
                                                                                          jsonEncode({
                                                                                            'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                            'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                            'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                            'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                            'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                            'ride_type': 1,
                                                                                            'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                ? 0
                                                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                    ? 1
                                                                                                    : 2,
                                                                                            'stops': jsonEncode(dropStopList),
                                                                                            'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                            'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                            'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                                          }),
                                                                                          'api/v1/request/create');
                                                                                    } else {
                                                                                      result = await createRequest(
                                                                                          (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                                              ? jsonEncode({
                                                                                                  'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                  'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                  'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                  'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                  'ride_type': 1,
                                                                                                  'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                      ? 0
                                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                          ? 1
                                                                                                          : 2,
                                                                                                  'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                  'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                                  'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                                                })
                                                                                              : jsonEncode({
                                                                                                  'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                  'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                  'ride_type': 1,
                                                                                                  'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                      ? 0
                                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                          ? 1
                                                                                                          : 2,
                                                                                                  'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                  'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                                                }),
                                                                                          'api/v1/request/create');
                                                                                    }
                                                                                  } else {
                                                                                    if (dropStopList.isNotEmpty) {
                                                                                      result = await createRequest(
                                                                                          jsonEncode({
                                                                                            'pick_lat': addressList[0].latlng.latitude,
                                                                                            'pick_lng': addressList[0].latlng.longitude,
                                                                                            'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                            'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                            'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                            'ride_type': 1,
                                                                                            'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                ? 0
                                                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                    ? 1
                                                                                                    : 2,
                                                                                            'pick_address': addressList[0].address,
                                                                                            'drop_address': addressList[addressList.length - 1].address,
                                                                                            'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                            'pickup_poc_name': addressList[0].name,
                                                                                            'pickup_poc_mobile': addressList[0].number,
                                                                                            'pickup_poc_instruction': addressList[0].instructions,
                                                                                            'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                            'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                            'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                            'goods_type_id': selectedGoodsId.toString(),
                                                                                            'stops': jsonEncode(dropStopList),
                                                                                            'goods_type_quantity': goodsSize
                                                                                          }),
                                                                                          'api/v1/request/delivery/create');
                                                                                    } else {
                                                                                      result = await createRequest(
                                                                                          jsonEncode({
                                                                                            'pick_lat': addressList[0].latlng.latitude,
                                                                                            'pick_lng': addressList[0].latlng.longitude,
                                                                                            'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                            'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                            'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                            'ride_type': 1,
                                                                                            'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                ? 0
                                                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                    ? 1
                                                                                                    : 2,
                                                                                            'pick_address': addressList[0].address,
                                                                                            'drop_address': addressList[addressList.length - 1].address,
                                                                                            'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                            'pickup_poc_name': addressList[0].name,
                                                                                            'pickup_poc_mobile': addressList[0].number,
                                                                                            'pickup_poc_instruction': addressList[0].instructions,
                                                                                            'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                            'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                            'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                            'goods_type_id': selectedGoodsId.toString(),
                                                                                            'goods_type_quantity': goodsSize
                                                                                          }),
                                                                                          'api/v1/request/delivery/create');
                                                                                    }
                                                                                  }
                                                                                } else {
                                                                                  if (choosenTransportType == 0) {
                                                                                    dropStopList.clear();
                                                                                    if (addressList.length > 2) {
                                                                                      for (var i = 1; i < addressList.length; i++) {
                                                                                        dropStopList.add(DropStops(
                                                                                          order: addressList[i].id,
                                                                                          latitude: addressList[i].latlng.latitude,
                                                                                          longitude: addressList[i].latlng.longitude,
                                                                                          address: addressList[i].address,
                                                                                        ));
                                                                                      }
                                                                                      result = await createRequest(
                                                                                          jsonEncode({
                                                                                            'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                            'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                            'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                            'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                            'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                            'ride_type': 1,
                                                                                            'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                ? 0
                                                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                    ? 1
                                                                                                    : 2,
                                                                                            'stops': jsonEncode(dropStopList),
                                                                                            'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                            'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                            'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                            'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                                          }),
                                                                                          'api/v1/request/create');
                                                                                    } else {
                                                                                      result = await createRequest(
                                                                                          (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                                              ? jsonEncode({
                                                                                                  'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                  'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                  'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                  'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                  'ride_type': 1,
                                                                                                  'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                      ? 0
                                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                          ? 1
                                                                                                          : 2,
                                                                                                  'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                  'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                                  'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                  'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                                                })
                                                                                              : jsonEncode({
                                                                                                  'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                  'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                  'ride_type': 1,
                                                                                                  'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                      ? 0
                                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                          ? 1
                                                                                                          : 2,
                                                                                                  'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                  'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                  'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                                                }),
                                                                                          'api/v1/request/create');
                                                                                    }
                                                                                  } else {
                                                                                    if (dropStopList.isNotEmpty) {
                                                                                      result = await createRequest(
                                                                                          jsonEncode({
                                                                                            'pick_lat': addressList[0].latlng.latitude,
                                                                                            'pick_lng': addressList[0].latlng.longitude,
                                                                                            'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                            'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                            'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                            'ride_type': 1,
                                                                                            'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                ? 0
                                                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                    ? 1
                                                                                                    : 2,
                                                                                            'pick_address': addressList[0].address,
                                                                                            'drop_address': addressList[addressList.length - 1].address,
                                                                                            'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                            'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                            'pickup_poc_name': addressList[0].name,
                                                                                            'pickup_poc_mobile': addressList[0].number,
                                                                                            'pickup_poc_instruction': addressList[0].instructions,
                                                                                            'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                            'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                            'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                            'goods_type_id': selectedGoodsId.toString(),
                                                                                            'stops': jsonEncode(dropStopList),
                                                                                            'goods_type_quantity': goodsSize
                                                                                          }),
                                                                                          'api/v1/request/delivery/create');
                                                                                    } else {
                                                                                      result = await createRequest(
                                                                                          jsonEncode({
                                                                                            'pick_lat': addressList[0].latlng.latitude,
                                                                                            'pick_lng': addressList[0].latlng.longitude,
                                                                                            'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                            'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                            'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                            'ride_type': 1,
                                                                                            'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                ? 0
                                                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                    ? 1
                                                                                                    : 2,
                                                                                            'pick_address': addressList[0].address,
                                                                                            'drop_address': addressList[addressList.length - 1].address,
                                                                                            'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                            'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                            'pickup_poc_name': addressList[0].name,
                                                                                            'pickup_poc_mobile': addressList[0].number,
                                                                                            'pickup_poc_instruction': addressList[0].instructions,
                                                                                            'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                            'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                            'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                            'goods_type_id': selectedGoodsId.toString(),
                                                                                            'goods_type_quantity': goodsSize
                                                                                          }),
                                                                                          'api/v1/request/delivery/create');
                                                                                    }
                                                                                  }
                                                                                }
                                                                              } else {
                                                                                if (rentalOption[choosenVehicle]['has_discount'] == false) {
                                                                                  if (choosenTransportType == 0) {
                                                                                    result = await createRequest(
                                                                                        jsonEncode({
                                                                                          'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                          'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                          'ride_type': 1,
                                                                                          'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                              ? 0
                                                                                              : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                  ? 1
                                                                                                  : 2,
                                                                                          'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                          'rental_pack_id': etaDetails[rentalChoosenOption]['id']
                                                                                        }),
                                                                                        'api/v1/request/create');
                                                                                  } else {
                                                                                    result = await createRequest(
                                                                                        jsonEncode({
                                                                                          'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                          'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                          'ride_type': 1,
                                                                                          'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                              ? 0
                                                                                              : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                  ? 1
                                                                                                  : 2,
                                                                                          'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                          'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                          'pickup_poc_name': addressList[0].name,
                                                                                          'pickup_poc_mobile': addressList[0].number,
                                                                                          'pickup_poc_instruction': addressList[0].instructions,
                                                                                          'goods_type_id': selectedGoodsId.toString(),
                                                                                          'goods_type_quantity': goodsSize
                                                                                        }),
                                                                                        'api/v1/request/delivery/create');
                                                                                  }
                                                                                } else {
                                                                                  if (choosenTransportType == 0) {
                                                                                    result = await createRequest(
                                                                                        jsonEncode({
                                                                                          'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                          'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                          'ride_type': 1,
                                                                                          'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                              ? 0
                                                                                              : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                  ? 1
                                                                                                  : 2,
                                                                                          'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                          'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                                                                                          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                          'rental_pack_id': etaDetails[rentalChoosenOption]['id']
                                                                                        }),
                                                                                        'api/v1/request/create');
                                                                                  } else {
                                                                                    result = await createRequest(
                                                                                        jsonEncode({
                                                                                          'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                          'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                          'ride_type': 1,
                                                                                          'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                              ? 0
                                                                                              : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                  ? 1
                                                                                                  : 2,
                                                                                          'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                          'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                                                                                          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                          'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                          'goods_type_id': selectedGoodsId.toString(),
                                                                                          'goods_type_quantity': goodsSize,
                                                                                          'pickup_poc_name': addressList[0].name,
                                                                                          'pickup_poc_mobile': addressList[0].number,
                                                                                          'pickup_poc_instruction': addressList[0].instructions,
                                                                                        }),
                                                                                        'api/v1/request/delivery/create');
                                                                                  }
                                                                                }
                                                                              }
                                                                            }
                                                                            if (result ==
                                                                                'logout') {
                                                                              navigateLogout();
                                                                            } else if (result ==
                                                                                'success') {
                                                                              timer();
                                                                            }
                                                                            setState(() {
                                                                              _isLoading = false;
                                                                            });
                                                                          }
                                                                        } else {
                                                                          setState(
                                                                              () {
                                                                            islowwalletbalance =
                                                                                true;
                                                                          });
                                                                        }
                                                                      },
                                                                      text: languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_book_now']),
                                                                ],
                                                              ),
                                                            ),
                                                               (choosenTransportType ==
                                                              1)
                                                          ? Column(
                                                              children: [
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.04,
                                                                ),

                                                                InkWell(
                                                                  onTap: () {
                                                                    pickerName
                                                                            .text =
                                                                        addressList[0]
                                                                            .name;
                                                                    pickerNumber
                                                                        .text = addressList[
                                                                            0]
                                                                        .number;
                                                                    instructions
                                                                        .text = (addressList[0].instructions !=
                                                                            null)
                                                                        ? addressList[0]
                                                                            .instructions
                                                                        : '';
                                                                    _editUserDetails =
                                                                        true;
                                                                    setState(
                                                                        () {});
                                                                  },
                                                                  child: Column(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.9,
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            SizedBox(
                                                                              width: media.width * 0.35,
                                                                              child: Text(
                                                                                addressList[0].name,
                                                                                style: GoogleFonts.poppins(fontSize: media.width * twelve, color: buttonColor, fontWeight: FontWeight.w600),
                                                                                maxLines: 1,
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              width: media.width * 0.35,
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                                children: [
                                                                                  Text(
                                                                                    addressList[0].number,
                                                                                    style: GoogleFonts.poppins(fontSize: media.width * twelve, color: buttonColor, fontWeight: FontWeight.w600),
                                                                                    textAlign: TextAlign.end,
                                                                                    maxLines: 1,
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.025,
                                                                                  ),
                                                                                  Icon(
                                                                                    Icons.edit,
                                                                                    size: media.width * 0.04,
                                                                                    color: buttonColor,
                                                                                  )
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.02,
                                                                      ),
                                                                      (addressList[0].instructions !=
                                                                              null)
                                                                          ? SizedBox(
                                                                              width: media.width * 0.9,
                                                                              child: Text(
                                                                                languages[choosenLanguage]['text_instructions'] + ' : ' + addressList[0].instructions,
                                                                                style: GoogleFonts.poppins(fontSize: media.width * twelve, color: verifyDeclined, fontWeight: FontWeight.w600),
                                                                                maxLines: 1,
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ))
                                                                          : Container()
                                                                    ],
                                                                  ),
                                                                ),
                                                                // SizedBox(
                                                                //   height: media
                                                                //           .width *
                                                                //       0.02,
                                                                // ),
                                                              ],
                                                            )
                                                          : Container(),
                                                             (selectedGoodsId != '')
                                                          ? Container(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      top: media
                                                                              .width *
                                                                          0.03),
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              child: Column(
                                                                children: [
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child: Text(
                                                                      languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_goods_type'],
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        color:
                                                                            textColor,
                                                                        fontSize:
                                                                            media.width *
                                                                                fourteen,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.02),
                                                                  InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      var val = await Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => const ChooseGoods()));
                                                                      if (val) {
                                                                        setState(
                                                                            () {});
                                                                      }
                                                                    },
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.7,
                                                                          child:
                                                                              Text(
                                                                            goodsTypeList.firstWhere((e) => e['id'] == int.parse(selectedGoodsId))['goods_type_name'] +
                                                                                ' (' +
                                                                                goodsSize +
                                                                                ')',
                                                                            style:
                                                                                GoogleFonts.poppins(fontSize: media.width * twelve, color: buttonColor),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        Icon(
                                                                          Icons
                                                                              .arrow_forward_ios,
                                                                          size: media.width *
                                                                              0.04,
                                                                          color:
                                                                              buttonColor,
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : Container(),
                                                    ],
                                                  ),
                                                ),
                                              ))
                                          : Container()
                                      : Container(),

                                  //show vehicle info
                                  (_showInfo == true &&
                                          ((widget.type == null)
                                              ? etaDetails[_showInfoInt]
                                                      ['enable_bidding'] ==
                                                  false
                                              : true))
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            padding: EdgeInsets.only(
                                                bottom: media.width * 0.05),
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                SizedBox(
                                                  width: media.width * 0.9,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _showInfo = false;
                                                            _showInfoInt = null;
                                                          });
                                                        },
                                                        child: Container(
                                                          height:
                                                              media.width * 0.1,
                                                          width:
                                                              media.width * 0.1,
                                                          decoration:
                                                              BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: page),
                                                          child: const Icon(Icons
                                                              .cancel_outlined),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: media.width * 0.05),
                                                Container(
                                                  width: media.width * 0.9,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      color: page),
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  child: (widget.type != 1)
                                                      ? Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              etaDetails[
                                                                      _showInfoInt]
                                                                  ['name'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            Text(
                                                              etaDetails[
                                                                      _showInfoInt]
                                                                  [
                                                                  'description'],
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.05),
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_supported_vehicles'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            Text(
                                                              etaDetails[
                                                                      _showInfoInt]
                                                                  [
                                                                  'supported_vehicles'],
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.05),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.4,
                                                                  child: Text(
                                                                    languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_estimated_amount'],
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        color:
                                                                            textColor,
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                  ),
                                                                ),
                                                                (etaDetails[_showInfoInt]['has_discount'] !=
                                                                            true ||
                                                                        etaDetails[_showInfoInt]['enable_bidding'] ==
                                                                            true)
                                                                    ? Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        children: [
                                                                          Text(
                                                                            etaDetails[_showInfoInt]['currency'] +
                                                                                ' ' +
                                                                                etaDetails[_showInfoInt]['total'].toStringAsFixed(2),
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                        ],
                                                                      )
                                                                    : Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        children: [
                                                                          Text(
                                                                            etaDetails[_showInfoInt]['currency'] +
                                                                                ' ',
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                          Text(
                                                                            etaDetails[_showInfoInt]['total'].toStringAsFixed(2),
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600,
                                                                                decoration: TextDecoration.lineThrough),
                                                                          ),
                                                                          Text(
                                                                            ' ${etaDetails[_showInfoInt]['discounted_totel'].toStringAsFixed(2)}',
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          )
                                                                        ],
                                                                      )
                                                              ],
                                                            )
                                                          ],
                                                        )
                                                      : Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              rentalOption[
                                                                      _showInfoInt]
                                                                  ['name'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            Text(
                                                              rentalOption[
                                                                      _showInfoInt]
                                                                  [
                                                                  'description'],
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.05),
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_supported_vehicles'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            Text(
                                                              rentalOption[
                                                                      _showInfoInt]
                                                                  [
                                                                  'supported_vehicles'],
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.05),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_estimated_amount'],
                                                                  style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          media.width *
                                                                              sixteen,
                                                                      color:
                                                                          textColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                                ),
                                                                (rentalOption[_showInfoInt]
                                                                            [
                                                                            'has_discount'] !=
                                                                        true)
                                                                    ? Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        children: [
                                                                          Text(
                                                                            rentalOption[_showInfoInt]['currency'] +
                                                                                ' ' +
                                                                                rentalOption[_showInfoInt]['fare_amount'].toStringAsFixed(2),
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                        ],
                                                                      )
                                                                    : Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        children: [
                                                                          Text(
                                                                            rentalOption[_showInfoInt]['currency'],
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                          Text(
                                                                            ' ${rentalOption[_showInfoInt]['fare_amount'].toStringAsFixed(2)}',
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600,
                                                                                decoration: TextDecoration.lineThrough),
                                                                          ),
                                                                          Text(
                                                                            ' ${rentalOption[_showInfoInt]['discounted_totel'].toStringAsFixed(2)}',
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * fourteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                        ],
                                                                      )
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      : (_showInfo == true)
                                          ? Positioned(
                                              top: 0,
                                              child: Container(
                                                height: media.height * 1,
                                                width: media.width * 1,
                                                color: Colors.transparent
                                                    .withOpacity(0.6),
                                                child: Scaffold(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  body: SingleChildScrollView(
                                                    child: Container(
                                                      height: media.height * 1,
                                                      width: media.width * 1,
                                                      padding: EdgeInsets.only(
                                                          bottom: media.width *
                                                              0.05),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          SizedBox(
                                                            width: media.width *
                                                                0.9,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                InkWell(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      _showInfo =
                                                                          false;
                                                                      _showInfoInt =
                                                                          null;
                                                                      yourAmount
                                                                          .clear();
                                                                    });
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height:
                                                                        media.width *
                                                                            0.1,
                                                                    width: media
                                                                            .width *
                                                                        0.1,
                                                                    decoration: const BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: Colors
                                                                            .white),
                                                                    child: const Icon(
                                                                        Icons
                                                                            .cancel_outlined),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.05),
                                                          Container(
                                                            width: media.width *
                                                                0.9,
                                                            decoration: BoxDecoration(
                                                                border: Border.all(
                                                                    color:
                                                                        backgroundColor,
                                                                    width: 2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                color: page),
                                                            padding: EdgeInsets
                                                                .all(media
                                                                        .width *
                                                                    0.05),
                                                            child:
                                                                (widget.type !=
                                                                        1)
                                                                    ? Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Center(
                                                                            child:
                                                                                Text(
                                                                              'Vechile Info and Pricing',
                                                                              style: GoogleFonts.poppins(decoration: TextDecoration.underline, fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600),
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            etaDetails[_showInfoInt]['name'],
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * sixteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.025,
                                                                          ),
                                                                          Text(
                                                                            etaDetails[_showInfoInt]['description'],
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontSize: media.width * fourteen,
                                                                              color: textColor,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              height: media.width * 0.05),
                                                                          Text(
                                                                            languages[choosenLanguage]['text_supported_vehicles'],
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * sixteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.025,
                                                                          ),
                                                                          Text(
                                                                            etaDetails[_showInfoInt]['supported_vehicles'],
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontSize: media.width * fourteen,
                                                                              color: textColor,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              height: media.width * 0.05),
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              SizedBox(
                                                                                width: media.width * 0.4,
                                                                                child: Text(
                                                                                  languages[choosenLanguage]['text_recommended_fare'],
                                                                                  style: GoogleFonts.poppins(fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                ),
                                                                              ),
                                                                              (etaDetails[_showInfoInt]['has_discount'] != true || etaDetails[_showInfoInt]['enable_bidding'] == true)
                                                                                  ? Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                      children: [
                                                                                        Text(
                                                                                          etaDetails[_showInfoInt]['currency'] + ' ' + etaDetails[_showInfoInt]['total'].toStringAsFixed(2),
                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                        ),
                                                                                      ],
                                                                                    )
                                                                                  : Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                      children: [
                                                                                        Text(
                                                                                          etaDetails[_showInfoInt]['currency'] + ' ',
                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                        ),
                                                                                        Text(
                                                                                          etaDetails[_showInfoInt]['total'].toStringAsFixed(2),
                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                                                                        ),
                                                                                        Text(
                                                                                          ' ${etaDetails[_showInfoInt]['discounted_totel'].toStringAsFixed(2)}',
                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                        )
                                                                                      ],
                                                                                    )
                                                                            ],
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.05,
                                                                          ),
                                                                          TextField(
                                                                              keyboardType: TextInputType.number,
                                                                              controller: yourAmount,
                                                                              decoration: InputDecoration(
                                                                                  border: UnderlineInputBorder(borderSide: BorderSide(color: hintColor)),
                                                                                  prefixIcon: Container(
                                                                                      width: media.width * 0.07,
                                                                                      alignment: Alignment.centerLeft,
                                                                                      child: Text(
                                                                                        etaDetails[_showInfoInt]['currency'],
                                                                                        style: GoogleFonts.poppins(fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                      )),
                                                                                  prefixIconConstraints: BoxConstraints(maxWidth: media.width * 0.07),
                                                                                  hintText: languages[choosenLanguage]['text_offer_your_fare'],
                                                                                  hintStyle: GoogleFonts.poppins(fontSize: media.width * sixteen, color: hintColor, fontWeight: FontWeight.w600)),
                                                                              style: GoogleFonts.poppins(fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600)),
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.05,
                                                                          ),
                                                                          Button(
                                                                            onTap:
                                                                                () async {
                                                                              //if User leave it empty
                                                                              if (yourAmount.text.isEmpty) {
                                                                                setState(() {
                                                                                  yourAmount.text = etaDetails[_showInfoInt]['total'].toStringAsFixed(2);
                                                                                });
                                                                              }
                                                                              debugPrint("==================================");
                                                                              debugPrint(userDetails['enable_trip_low_price_limit']);
                                                                              debugPrint("==================================");
                                                                              if (userDetails['enable_trip_low_price_limit'] == "1") {
                                                                                var tripLowPriceGap = double.parse(userDetails['trip_low_price_gap']);
                                                                                var Gaptotal = etaDetails[_showInfoInt]['total'] - tripLowPriceGap;
                                                                                double userInput = double.tryParse(yourAmount.text) ?? 0.0;
                                                                                if (Gaptotal > userInput) {
                                                                                  setState(() {
                                                                                    biddingLowestAmount = Gaptotal;
                                                                                    incorrectAmount = true;
                                                                                  });
                                                                                  return;
                                                                                }
                                                                              }
                                                                              if (yourAmount.text.isNotEmpty) {
                                                                                setState(() {
                                                                                  _isLoading = true;
                                                                                });
                                                                                var g = geo.encode(addressList.firstWhere((element) => element.type == 'pickup').latlng.longitude, addressList.firstWhere((element) => element.type == 'pickup').latlng.latitude);
                                                                                dynamic result;

                                                                                if (choosenVehicle != null) {
                                                                                  if (widget.type != 1) {
                                                                                    if (etaDetails[choosenVehicle]['has_discount'] == false) {
                                                                                      if (choosenTransportType == 0) {
                                                                                        result = await createRequest(
                                                                                            (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                                                ? jsonEncode({
                                                                                                    'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                    'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                    'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                    'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                    'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                    'ride_type': 1,
                                                                                                    'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                        ? 0
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                            ? 1
                                                                                                            : 2,
                                                                                                    'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                    'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                                    'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                    'offerred_ride_fare': yourAmount.text,
                                                                                                    'is_bid_ride': 1,
                                                                                                    'stops': jsonEncode(dropStopList),
                                                                                                    'payment_method_id': selectedPaymentIndex
                                                                                                  })
                                                                                                : jsonEncode({
                                                                                                    'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                    'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                    'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                    'ride_type': 1,
                                                                                                    'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                        ? 0
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                            ? 1
                                                                                                            : 2,
                                                                                                    'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                    'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                    'offerred_ride_fare': yourAmount.text,
                                                                                                    'is_bid_ride': 1,
                                                                                                    'payment_method_id': selectedPaymentIndex
                                                                                                  }),
                                                                                            'api/v1/request/create');
                                                                                      } else {
                                                                                        if (dropStopList.isNotEmpty) {
                                                                                          result = await createRequest(
                                                                                              jsonEncode({
                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                'ride_type': 1,
                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                    ? 0
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                        ? 1
                                                                                                        : 2,
                                                                                                'pick_address': addressList[0].address,
                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                'goods_type_quantity': goodsSize,
                                                                                                'offerred_ride_fare': yourAmount.text,
                                                                                                'is_bid_ride': 1,
                                                                                                'payment_method_id': selectedPaymentIndex
                                                                                              }),
                                                                                              'api/v1/request/delivery/create');
                                                                                        } else {
                                                                                          result = await createRequest(
                                                                                              jsonEncode({
                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                'ride_type': 1,
                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                    ? 0
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                        ? 1
                                                                                                        : 2,
                                                                                                'pick_address': addressList[0].address,
                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                'goods_type_quantity': goodsSize,
                                                                                                'offerred_ride_fare': yourAmount.text,
                                                                                                'is_bid_ride': 1,
                                                                                                'payment_method_id': selectedPaymentIndex,
                                                                                              }),
                                                                                              'api/v1/request/delivery/create');
                                                                                        }
                                                                                      }
                                                                                    } else {
                                                                                      if (choosenTransportType == 0) {
                                                                                        result = await createRequest(
                                                                                            (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                                                ? jsonEncode({
                                                                                                    'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                    'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                    'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                    'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                    'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                    'ride_type': 1,
                                                                                                    'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                        ? 0
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                            ? 1
                                                                                                            : 2,
                                                                                                    'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                    'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                                    'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                    'offerred_ride_fare': yourAmount.text,
                                                                                                    'is_bid_ride': 1,
                                                                                                    'stops': jsonEncode(dropStopList),
                                                                                                    'payment_method_id': selectedPaymentIndex,
                                                                                                  })
                                                                                                : jsonEncode({
                                                                                                    'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                    'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                    'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                    'ride_type': 1,
                                                                                                    'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                        ? 0
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                            ? 1
                                                                                                            : 2,
                                                                                                    'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                    'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                    'offerred_ride_fare': yourAmount.text,
                                                                                                    'is_bid_ride': 1,
                                                                                                    'payment_method_id': selectedPaymentIndex,
                                                                                                  }),
                                                                                            'api/v1/request/create');
                                                                                      } else {
                                                                                        if (dropStopList.isNotEmpty) {
                                                                                          result = await createRequest(
                                                                                              jsonEncode({
                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                'ride_type': 1,
                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                    ? 0
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                        ? 1
                                                                                                        : 2,
                                                                                                'pick_address': addressList[0].address,
                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                'goods_type_quantity': goodsSize,
                                                                                                'offerred_ride_fare': yourAmount.text,
                                                                                                'is_bid_ride': 1,
                                                                                                'payment_method_id': selectedPaymentIndex,
                                                                                              }),
                                                                                              'api/v1/request/delivery/create');
                                                                                        } else {
                                                                                          result = await createRequest(
                                                                                              jsonEncode({
                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                'ride_type': 1,
                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                    ? 0
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                        ? 1
                                                                                                        : 2,
                                                                                                'pick_address': addressList[0].address,
                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                'goods_type_quantity': goodsSize,
                                                                                                'offerred_ride_fare': yourAmount.text,
                                                                                                'is_bid_ride': 1,
                                                                                                'payment_method_id': selectedPaymentIndex,
                                                                                              }),
                                                                                              'api/v1/request/delivery/create');
                                                                                        }
                                                                                      }
                                                                                    }
                                                                                  } else {
                                                                                    if (rentalOption[choosenVehicle]['has_discount'] == false) {
                                                                                      if (choosenTransportType == 0) {
                                                                                        result = await createRequest(
                                                                                            jsonEncode({
                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                              'ride_type': 1,
                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                  ? 0
                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                      ? 1
                                                                                                      : 2,
                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                              'offerred_ride_fare': yourAmount.text,
                                                                                              'is_bid_ride': 1,
                                                                                              'payment_method_id': selectedPaymentIndex,
                                                                                            }),
                                                                                            'api/v1/request/create');
                                                                                      } else {
                                                                                        result = await createRequest(
                                                                                            jsonEncode({
                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                              'ride_type': 1,
                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                  ? 0
                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                      ? 1
                                                                                                      : 2,
                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                              'pickup_poc_name': addressList[0].name,
                                                                                              'pickup_poc_mobile': addressList[0].number,
                                                                                              'pickup_poc_instruction': addressList[0].instructions,
                                                                                              'goods_type_id': selectedGoodsId.toString(),
                                                                                              'goods_type_quantity': goodsSize,
                                                                                              'offerred_ride_fare': yourAmount.text,
                                                                                              'is_bid_ride': 1,
                                                                                              'payment_method_id': selectedPaymentIndex,
                                                                                            }),
                                                                                            'api/v1/request/delivery/create');
                                                                                      }
                                                                                    } else {
                                                                                      if (choosenTransportType == 0) {
                                                                                        result = await createRequest(
                                                                                            jsonEncode({
                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                              'ride_type': 1,
                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                  ? 0
                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                      ? 1
                                                                                                      : 2,
                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                              'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                              'offerred_ride_fare': yourAmount.text,
                                                                                              'is_bid_ride': 1,
                                                                                              'payment_method_id': selectedPaymentIndex,
                                                                                            }),
                                                                                            'api/v1/request/create');
                                                                                      } else {
                                                                                        result = await createRequest(
                                                                                            jsonEncode({
                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                              'ride_type': 1,
                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                  ? 0
                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                      ? 1
                                                                                                      : 2,
                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                              'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                              'goods_type_id': selectedGoodsId.toString(),
                                                                                              'goods_type_quantity': goodsSize,
                                                                                              'pickup_poc_name': addressList[0].name,
                                                                                              'pickup_poc_mobile': addressList[0].number,
                                                                                              'pickup_poc_instruction': addressList[0].instructions,
                                                                                              'offerred_ride_fare': yourAmount.text,
                                                                                              'is_bid_ride': 1,
                                                                                              'payment_method_id': selectedPaymentIndex,
                                                                                            }),
                                                                                            'api/v1/request/delivery/create');
                                                                                      }
                                                                                    }
                                                                                  }
                                                                                }
                                                                                if (result == 'success') {
                                                                                  _showInfo = false;
                                                                                  FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}').update({
                                                                                    'user_id': userDetails['id'].toString(),
                                                                                    'price': userRequestData['offerred_ride_fare'],
                                                                                    'g': g,
                                                                                    'user_name': userDetails['name'],
                                                                                    'updated_at': ServerValue.timestamp,
                                                                                    'user_img': userDetails['profile_picture'],
                                                                                    'vehicle_type': userRequestData['vehicle_type_id'],
                                                                                    'request_id': userRequestData["id"],
                                                                                    'pick_address': userRequestData['pick_address'],
                                                                                    'drop_address': userRequestData['drop_address'],
                                                                                    'trip_stops': (dropStopList.isNotEmpty) ? jsonEncode(dropStopList) : 'null',
                                                                                    'goods': (userRequestData['transport_type'] != 'taxi' && userRequestData['goods_type'] != '-') ? '${userRequestData['goods_type']} - ${userRequestData['goods_type_quantity']}' : 'null',
                                                                                    'pick_lat': userRequestData['pick_lat'],
                                                                                    'drop_lat': userRequestData['drop_lat'],
                                                                                    'pick_lng': userRequestData['pick_lng'],
                                                                                    'drop_lng': userRequestData['drop_lng'],
                                                                                    'currency': userDetails['currency_symbol']
                                                                                  });
                                                                                }
                                                                                setState(() {
                                                                                  yourAmount.clear();
                                                                                  _isLoading = false;
                                                                                });
                                                                              }
                                                                            },
                                                                            text:
                                                                                languages[choosenLanguage]['text_create_request'],
                                                                            color: (yourAmount.text.isNotEmpty)
                                                                                ? buttonColor
                                                                                : Colors.grey,
                                                                            borcolor: (yourAmount.text.isNotEmpty)
                                                                                ? buttonColor
                                                                                : Colors.grey,
                                                                          )
                                                                        ],
                                                                      )
                                                                    : Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            rentalOption[_showInfoInt]['name'],
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * sixteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.025,
                                                                          ),
                                                                          Text(
                                                                            rentalOption[_showInfoInt]['description'],
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontSize: media.width * fourteen,
                                                                              color: textColor,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              height: media.width * 0.05),
                                                                          Text(
                                                                            languages[choosenLanguage]['text_supported_vehicles'],
                                                                            style: GoogleFonts.poppins(
                                                                                fontSize: media.width * sixteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.025,
                                                                          ),
                                                                          Text(
                                                                            rentalOption[_showInfoInt]['supported_vehicles'],
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontSize: media.width * fourteen,
                                                                              color: textColor,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              height: media.width * 0.05),
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Text(
                                                                                languages[choosenLanguage]['text_estimated_amount'],
                                                                                style: GoogleFonts.poppins(fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600),
                                                                              ),
                                                                              (rentalOption[_showInfoInt]['has_discount'] != true)
                                                                                  ? Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                      children: [
                                                                                        Text(
                                                                                          rentalOption[_showInfoInt]['currency'] + ' ' + rentalOption[_showInfoInt]['fare_amount'].toStringAsFixed(2),
                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                        ),
                                                                                      ],
                                                                                    )
                                                                                  : Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                      children: [
                                                                                        Text(
                                                                                          rentalOption[_showInfoInt]['currency'],
                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                        ),
                                                                                        Text(
                                                                                          ' ${rentalOption[_showInfoInt]['fare_amount'].toStringAsFixed(2)}',
                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                                                                        ),
                                                                                        Text(
                                                                                          ' ${rentalOption[_showInfoInt]['discounted_totel'].toStringAsFixed(2)}',
                                                                                          style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                        ),
                                                                                      ],
                                                                                    )
                                                                            ],
                                                                          )
                                                                        ],
                                                                      ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(),

                                  //no driver found
                                  (noDriverFound == true)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(
                                                                12))),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: media.width * 0.18,
                                                  width: media.width * 0.18,
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                              0xffFEF2F2)),
                                                  alignment: Alignment.center,
                                                  child: Container(
                                                    height: media.width * 0.14,
                                                    width: media.width * 0.14,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xffFF0000)),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_nodriver'],
                                                  style: GoogleFonts.poppins(
                                                      fontSize: media.width *
                                                          eighteen,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textColor),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () {
                                                      setState(() {
                                                        noDriverFound = false;
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_tryagain'])
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //internal server error
                                  (tripReqError == true)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(
                                                                12))),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: media.width * 0.18,
                                                  width: media.width * 0.18,
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                              0xffFEF2F2)),
                                                  alignment: Alignment.center,
                                                  child: Container(
                                                    height: media.width * 0.14,
                                                    width: media.width * 0.14,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xffFF0000)),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                SizedBox(
                                                  width: media.width * 0.8,
                                                  child: Text(
                                                      languages[choosenLanguage]
                                                          [
                                                          'text_internal_server_error'],
                                                      style: GoogleFonts
                                                          .poppins(
                                                              fontSize:
                                                                  media.width *
                                                                      eighteen,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: textColor),
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () {
                                                      setState(() {
                                                        tripReqError = false;
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_tryagain'])
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //service not available

                                  (serviceNotAvailable)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(
                                                                12))),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: media.width * 0.18,
                                                  width: media.width * 0.18,
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                              0xffFEF2F2)),
                                                  alignment: Alignment.center,
                                                  child: Container(
                                                    height: media.width * 0.14,
                                                    width: media.width * 0.14,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xffFF0000)),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                SizedBox(
                                                  width: media.width * 0.8,
                                                  child: Text(
                                                      languages[choosenLanguage]
                                                          ['text_no_service'],
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize:
                                                                  media.width *
                                                                      eighteen,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: textColor),
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        serviceNotAvailable =
                                                            false;
                                                      });
                                                      if (widget.type != 1) {
                                                        var val =
                                                            await etaRequest();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                      } else {
                                                        var val =
                                                            await rentalEta();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                      }
                                                      setState(() {});
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_tryagain'])
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //islowwallet balance popup
                                  (islowwalletbalance == true)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            height: media.height * 1,
                                            color:
                                                Colors.black.withOpacity(0.4),
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: media.width * 0.9,
                                              height: media.width * 0.4,
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              decoration: BoxDecoration(
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          media.width * 0.04)),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      languages[
                                                              choosenLanguage]
                                                          [
                                                          'text_wallet_balance_low'],
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: media
                                                                      .width *
                                                                  sixteen,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: textColor),
                                                      textAlign:
                                                          TextAlign.center),
                                                  Button(
                                                      width: media.width * 0.4,
                                                      height: media.width * 0.1,
                                                      onTap: () {
                                                        setState(() {
                                                          islowwalletbalance =
                                                              false;
                                                        });
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_ok'])
                                                ],
                                              ),
                                            ),
                                          ))
                                      : Container(),

                                  //Show Error if Bidding Amount is lower than Limit Amount
                                  (incorrectAmount == true)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(
                                                                12))),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: media.width * 0.18,
                                                  width: media.width * 0.18,
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                              0xffFEF2F2)),
                                                  alignment: Alignment.center,
                                                  child: Container(
                                                    height: media.width * 0.14,
                                                    width: media.width * 0.14,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xffFF0000)),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                SizedBox(
                                                  width: media.width * 0.8,
                                                  child: Text(
                                                      languages[choosenLanguage]
                                                              [
                                                              'text_incorrect_bidding_amount'] +
                                                          biddingLowestAmount
                                                              .toStringAsFixed(
                                                                  2),
                                                      style: GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  eighteen,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: textColor),
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        incorrectAmount = false;
                                                      });
                                                      yourAmount.text =
                                                          biddingLowestAmount
                                                              .toStringAsFixed(
                                                                  2);
                                                      if (widget.type != 1) {
                                                        var val =
                                                            await etaRequest();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                      } else {
                                                        var val =
                                                            await rentalEta();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                      }
                                                      setState(() {});
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_tryagain'])
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //choose payment method
                                  (_choosePayment == true)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Scaffold(
                                              backgroundColor:
                                                  Colors.transparent,
                                              body: SingleChildScrollView(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                child: SizedBox(
                                                  height: media.height * 1,
                                                  width: media.width * 1,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.9,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _choosePayment =
                                                                      false;
                                                                  promoKey
                                                                      .clear();
                                                                });
                                                              },
                                                              child: Container(
                                                                height: media
                                                                        .width *
                                                                    0.1,
                                                                width: media
                                                                        .width *
                                                                    0.1,
                                                                decoration: BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color:
                                                                        page),
                                                                child: const Icon(
                                                                    Icons
                                                                        .cancel_outlined),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Container(
                                                        width:
                                                            media.width * 0.9,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: page,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        padding: EdgeInsets.all(
                                                            media.width * 0.05),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_paymentmethod'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      twenty,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      textColor),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.015,
                                                            ),
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_choose_paynoworlater'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      textColor),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.015,
                                                            ),
                                                            (widget.type != 1)
                                                                ? Column(
                                                                    children: etaDetails[choosenVehicle]
                                                                            [
                                                                            'payment_type']
                                                                        .toString()
                                                                        .split(
                                                                            ',')
                                                                        .toList()
                                                                        .asMap()
                                                                        .map((i,
                                                                            value) {
                                                                          return MapEntry(
                                                                              i,
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    payingVia = i;
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  padding: EdgeInsets.all(media.width * 0.02),
                                                                                  width: media.width * 0.9,
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Row(
                                                                                        children: [
                                                                                          SizedBox(
                                                                                            width: media.width * 0.06,
                                                                                            child: (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                                ? Image.asset(
                                                                                                    'assets/images/cash.png',
                                                                                                    fit: BoxFit.contain,
                                                                                                  )
                                                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                    ? Image.asset(
                                                                                                        'assets/images/wallet.png',
                                                                                                        fit: BoxFit.contain,
                                                                                                      )
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                        ? Image.asset(
                                                                                                            'assets/images/card.png',
                                                                                                            fit: BoxFit.contain,
                                                                                                          )
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                            ? Image.asset(
                                                                                                                'assets/images/upi.png',
                                                                                                                fit: BoxFit.contain,
                                                                                                              )
                                                                                                            : Container(),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.05,
                                                                                          ),
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Text(
                                                                                                etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i].toString(),
                                                                                                style: GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                              ),
                                                                                              Text(
                                                                                                (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                                    ? languages[choosenLanguage]['text_paycash']
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                        ? languages[choosenLanguage]['text_paywallet']
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                            ? languages[choosenLanguage]['text_paycard']
                                                                                                            : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                                ? languages[choosenLanguage]['text_payupi']
                                                                                                                : '',
                                                                                                style: GoogleFonts.poppins(
                                                                                                  fontSize: media.width * ten,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                          Expanded(
                                                                                              child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                                                            children: [
                                                                                              Container(
                                                                                                height: media.width * 0.05,
                                                                                                width: media.width * 0.05,
                                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: page, border: Border.all(color: Colors.black, width: 1.2)),
                                                                                                alignment: Alignment.center,
                                                                                                child: (payingVia == i) ? Container(height: media.width * 0.03, width: media.width * 0.03, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)) : Container(),
                                                                                              )
                                                                                            ],
                                                                                          ))
                                                                                        ],
                                                                                      )
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ));
                                                                        })
                                                                        .values
                                                                        .toList(),
                                                                  )
                                                                : Column(
                                                                    children: rentalOption[choosenVehicle]
                                                                            [
                                                                            'payment_type']
                                                                        .toString()
                                                                        .split(
                                                                            ',')
                                                                        .toList()
                                                                        .asMap()
                                                                        .map((i,
                                                                            value) {
                                                                          return MapEntry(
                                                                              i,
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    payingVia = i;
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  padding: EdgeInsets.all(media.width * 0.02),
                                                                                  width: media.width * 0.9,
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Row(
                                                                                        children: [
                                                                                          SizedBox(
                                                                                            width: media.width * 0.06,
                                                                                            child: (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                                ? Image.asset(
                                                                                                    'assets/images/cash.png',
                                                                                                    fit: BoxFit.contain,
                                                                                                  )
                                                                                                : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                    ? Image.asset(
                                                                                                        'assets/images/wallet.png',
                                                                                                        fit: BoxFit.contain,
                                                                                                      )
                                                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                        ? Image.asset(
                                                                                                            'assets/images/card.png',
                                                                                                            fit: BoxFit.contain,
                                                                                                          )
                                                                                                        : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                            ? Image.asset(
                                                                                                                'assets/images/upi.png',
                                                                                                                fit: BoxFit.contain,
                                                                                                              )
                                                                                                            : Container(),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.05,
                                                                                          ),
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Text(
                                                                                                rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i].toString(),
                                                                                                style: GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                              ),
                                                                                              Text(
                                                                                                (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                                    ? languages[choosenLanguage]['text_paycash']
                                                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                        ? languages[choosenLanguage]['text_paywallet']
                                                                                                        : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                            ? languages[choosenLanguage]['text_paycard']
                                                                                                            : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                                ? languages[choosenLanguage]['text_payupi']
                                                                                                                : '',
                                                                                                style: GoogleFonts.poppins(
                                                                                                  fontSize: media.width * ten,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                          Expanded(
                                                                                              child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                                                            children: [
                                                                                              Container(
                                                                                                height: media.width * 0.05,
                                                                                                width: media.width * 0.05,
                                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: page, border: Border.all(color: Colors.black, width: 1.2)),
                                                                                                alignment: Alignment.center,
                                                                                                child: (payingVia == i) ? Container(height: media.width * 0.03, width: media.width * 0.03, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)) : Container(),
                                                                                              )
                                                                                            ],
                                                                                          ))
                                                                                        ],
                                                                                      )
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ));
                                                                        })
                                                                        .values
                                                                        .toList(),
                                                                  ),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.02,
                                                            ),
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                border: Border.all(
                                                                    color:
                                                                        borderLines,
                                                                    width: 1.2),
                                                              ),
                                                              padding: EdgeInsets
                                                                  .fromLTRB(
                                                                      media.width *
                                                                          0.025,
                                                                      0,
                                                                      media.width *
                                                                          0.025,
                                                                      0),
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              child: Row(
                                                                children: [
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.06,
                                                                    child: Image.asset(
                                                                        'assets/images/promocode.png',
                                                                        fit: BoxFit
                                                                            .contain),
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.05,
                                                                  ),
                                                                  Expanded(
                                                                    child: (promoStatus ==
                                                                            null)
                                                                        ? TextField(
                                                                            controller:
                                                                                promoKey,
                                                                            onChanged:
                                                                                (val) {
                                                                              setState(() {
                                                                                promoCode = val;
                                                                              });
                                                                            },
                                                                            decoration: InputDecoration(
                                                                                border: InputBorder.none,
                                                                                hintText: languages[choosenLanguage]['text_enterpromo'],
                                                                                hintStyle: GoogleFonts.poppins(fontSize: media.width * twelve, color: hintColor)),
                                                                          )
                                                                        : (promoStatus ==
                                                                                1)
                                                                            ? Container(
                                                                                padding: EdgeInsets.fromLTRB(0, media.width * 0.045, 0, media.width * 0.045),
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Column(
                                                                                      children: [
                                                                                        Text(promoKey.text, style: GoogleFonts.poppins(fontSize: media.width * ten, color: const Color(0xff319900))),
                                                                                        Text(languages[choosenLanguage]['text_promoaccepted'], style: GoogleFonts.poppins(fontSize: media.width * ten, color: const Color(0xff319900))),
                                                                                      ],
                                                                                    ),
                                                                                    InkWell(
                                                                                      onTap: () async {
                                                                                        setState(() {
                                                                                          _isLoading = true;
                                                                                        });
                                                                                        dynamic result;
                                                                                        if (widget.type != 1) {
                                                                                          result = await etaRequest();
                                                                                        } else {
                                                                                          result = await rentalEta();
                                                                                        }
                                                                                        setState(() {
                                                                                          _isLoading = false;
                                                                                          if (result == true) {
                                                                                            promoStatus = null;
                                                                                            promoCode = '';
                                                                                          } else if (result == 'logout') {
                                                                                            navigateLogout();
                                                                                          }
                                                                                        });
                                                                                      },
                                                                                      child: Text(languages[choosenLanguage]['text_remove'], style: GoogleFonts.poppins(fontSize: media.width * twelve, color: const Color(0xff319900))),
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              )
                                                                            : (promoStatus == 2)
                                                                                ? Container(
                                                                                    padding: EdgeInsets.fromLTRB(0, media.width * 0.045, 0, media.width * 0.045),
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                      children: [
                                                                                        Text(promoKey.text, style: GoogleFonts.poppins(fontSize: media.width * twelve, color: const Color(0xffFF0000))),
                                                                                        InkWell(
                                                                                          onTap: () async {
                                                                                            setState(() {
                                                                                              promoStatus = null;
                                                                                              promoCode = '';
                                                                                              promoKey.clear();
                                                                                            });
                                                                                            dynamic val;
                                                                                            // promoKey.text = promoCode;
                                                                                            if (widget.type != 1) {
                                                                                              val = await etaRequest();
                                                                                            } else {
                                                                                              val = await rentalEta();
                                                                                            }
                                                                                            if (val == 'logout') {
                                                                                              navigateLogout();
                                                                                            }
                                                                                            setState(() {});
                                                                                          },
                                                                                          child: Text(languages[choosenLanguage]['text_remove'], style: GoogleFonts.poppins(fontSize: media.width * twelve, color: const Color(0xffFF0000))),
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                  )
                                                                                : Container(),
                                                                  )
                                                                ],
                                                              ),
                                                            ),

                                                            //promo code status
                                                            (promoStatus == 2)
                                                                ? Container(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    padding: EdgeInsets.only(
                                                                        top: media.height *
                                                                            0.02),
                                                                    child: Text(
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_promorejected'],
                                                                        style: GoogleFonts.poppins(
                                                                            fontSize: media.width *
                                                                                ten,
                                                                            color:
                                                                                const Color(0xffFF0000))),
                                                                  )
                                                                : Container(),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.02,
                                                            ),
                                                            Button(
                                                                onTap:
                                                                    () async {
                                                                  if (promoCode ==
                                                                      '') {
                                                                    setState(
                                                                        () {
                                                                      _choosePayment =
                                                                          false;
                                                                    });
                                                                  } else {
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          true;
                                                                    });
                                                                    dynamic val;
                                                                    if (widget
                                                                            .type !=
                                                                        1) {
                                                                      val =
                                                                          await etaRequestWithPromo();
                                                                    } else {
                                                                      val =
                                                                          await rentalRequestWithPromo();
                                                                    }
                                                                    if (val ==
                                                                        'logout') {
                                                                      navigateLogout();
                                                                    }
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          false;
                                                                    });
                                                                  }
                                                                },
                                                                text: languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_confirm'])
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ))
                                      : Container(),

                                  //bottom nav bar after request accepted
                                  (userRequestData['accepted_at'] != null)
                                      ? Positioned(
                                          top: MediaQuery.of(context)
                                                  .padding
                                                  .top +
                                              25,
                                          child: Container(
                                            padding: EdgeInsets.fromLTRB(
                                                media.width * 0.05,
                                                media.width * 0.025,
                                                media.width * 0.05,
                                                media.width * 0.025),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: backgroundColor),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                      blurRadius: 2,
                                                      color: backgroundColor
                                                          .withOpacity(0.2),
                                                      spreadRadius: 2)
                                                ],
                                                color: page),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: 10,
                                                  width: 10,
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color:
                                                              backgroundColor),
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                            blurRadius: 2,
                                                            color:
                                                                backgroundColor
                                                                    .withOpacity(
                                                                        0.2),
                                                            spreadRadius: 2)
                                                      ],
                                                      color: (userRequestData[
                                                                      'accepted_at'] !=
                                                                  null &&
                                                              userRequestData[
                                                                      'arrived_at'] ==
                                                                  null)
                                                          ? const Color(
                                                              0xff2E67D5)
                                                          : (userRequestData[
                                                                          'accepted_at'] !=
                                                                      null &&
                                                                  userRequestData[
                                                                          'arrived_at'] !=
                                                                      null &&
                                                                  userRequestData[
                                                                          'is_trip_start'] ==
                                                                      0)
                                                              ? const Color(
                                                                  0xff319900)
                                                              : (userRequestData['accepted_at'] != null &&
                                                                      userRequestData[
                                                                              'arrived_at'] !=
                                                                          null &&
                                                                      userRequestData[
                                                                              'is_trip_start'] !=
                                                                          0)
                                                                  ? const Color(
                                                                      0xffFF0000)
                                                                  : Colors
                                                                      .transparent),
                                                ),
                                                SizedBox(
                                                  width: media.width * 0.02,
                                                ),
                                                Text(
                                                    (userRequestData['accepted_at'] != null &&
                                                            userRequestData['arrived_at'] ==
                                                                null &&
                                                            _dist != null)
                                                        ? languages[choosenLanguage][
                                                                'text_arrive_eta'] +
                                                            ' ' +
                                                            double.parse(((_dist * 2))
                                                                    .toString())
                                                                .round()
                                                                .toString() +
                                                            ' ' +
                                                            languages[choosenLanguage]
                                                                ['text_mins']
                                                        : (userRequestData['accepted_at'] != null &&
                                                                userRequestData['arrived_at'] !=
                                                                    null &&
                                                                userRequestData['is_trip_start'] ==
                                                                    0)
                                                            ? languages[choosenLanguage]
                                                                ['text_arrived']
                                                            : (userRequestData['accepted_at'] !=
                                                                        null &&
                                                                    userRequestData['arrived_at'] !=
                                                                        null &&
                                                                    userRequestData['is_trip_start'] !=
                                                                        null)
                                                                ? (userRequestData['transport_type'] == 'taxi' &&
                                                                        _dist !=
                                                                            null)
                                                                    ? languages[choosenLanguage]['text_onride_min'] +
                                                                        ' ' +
                                                                        double.parse(((_dist * 2)).toString())
                                                                            .round()
                                                                            .toString() +
                                                                        'mins'
                                                                    : languages[choosenLanguage]
                                                                        ['text_onride']
                                                                : '',
                                                    style: GoogleFonts.poppins(
                                                      fontSize:
                                                          media.width * twelve,
                                                      color: (userRequestData[
                                                                      'accepted_at'] !=
                                                                  null &&
                                                              userRequestData[
                                                                      'arrived_at'] ==
                                                                  null)
                                                          ? const Color(
                                                              0xff2E67D5)
                                                          : (userRequestData[
                                                                          'accepted_at'] !=
                                                                      null &&
                                                                  userRequestData[
                                                                          'arrived_at'] !=
                                                                      null &&
                                                                  userRequestData[
                                                                          'is_trip_start'] ==
                                                                      0)
                                                              ? const Color(
                                                                  0xff319900)
                                                              : (userRequestData['accepted_at'] != null &&
                                                                      userRequestData[
                                                                              'arrived_at'] !=
                                                                          null &&
                                                                      userRequestData[
                                                                              'is_trip_start'] ==
                                                                          1)
                                                                  ? const Color(
                                                                      0xffFF0000)
                                                                  : Colors
                                                                      .transparent,
                                                    ))
                                              ],
                                            ),
                                          ))
                                      : Container(),
                                  (userRequestData.isNotEmpty &&
                                              userRequestData['is_later'] ==
                                                  null &&
                                              userRequestData['accepted_at'] ==
                                                  null ||
                                          userRequestData.isNotEmpty &&
                                              userRequestData['is_later'] ==
                                                  0 &&
                                              userRequestData['accepted_at'] ==
                                                  null)
                                      ? userRequestData.isNotEmpty &&
                                              userRequestData['is_bid_ride'] ==
                                                  1
                                          ? Positioned(
                                              bottom: 0,
                                              child: StreamBuilder<Object>(
                                                  stream: FirebaseDatabase
                                                      .instance
                                                      .ref()
                                                      .child(
                                                          'bid-meta/${userRequestData["id"]}')
                                                      .onValue
                                                      .asBroadcastStream(),
                                                  builder: (context,
                                                      AsyncSnapshot event) {
                                                    List driverList = [];
                                                    Map rideList = {};
                                                    // rideList = event.data!.snapshot;
                                                    if (event.data != null) {
                                                      DataSnapshot snapshots =
                                                          event.data!.snapshot;
                                                      if (snapshots.value !=
                                                          null) {
                                                        rideList = jsonDecode(
                                                            jsonEncode(snapshots
                                                                .value));
                                                        if (rideList[
                                                                'drivers'] !=
                                                            null) {
                                                          Map driver = rideList[
                                                              'drivers'];
                                                          driver.forEach(
                                                              (key, value) {
                                                            if (driver[key][
                                                                    'is_rejected'] ==
                                                                'none') {
                                                              driverList
                                                                  .add(value);

                                                              if (driverList
                                                                  .isNotEmpty) {
                                                                audioPlayers.play(
                                                                    AssetSource(
                                                                        audio));
                                                              }
                                                            }
                                                          });
                                                          // driver.forEach((e){
                                                          //   if(e['is_rejected'] == 'none'){
                                                          //     driverList.add(e);
                                                          //   }
                                                          // });
                                                          // driverList = rideList['drivers'];
                                                          if (driverList
                                                              .isNotEmpty) {
                                                            if (driverBck
                                                                    .isNotEmpty &&
                                                                driverList[0][
                                                                        'user_id'] !=
                                                                    driverBck[0]
                                                                        [
                                                                        'user_id']) {
                                                              driverBck =
                                                                  driverList;
                                                            } else if (driverBck
                                                                .isEmpty) {
                                                              driverBck =
                                                                  driverList;
                                                            }
                                                          } else {
                                                            driverBck =
                                                                driverList;
                                                          }
                                                        } else {
                                                          driverBck =
                                                              driverList;
                                                        }
                                                      }
                                                    }

                                                    return Container(
                                                      width: media.width * 1,
                                                      height: media.height * 1,
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: Container(
                                                        width: media.width * 1,
                                                        height: (driverList
                                                                .isNotEmpty)
                                                            ? media.height * 1
                                                            : media.width *
                                                                0.72,
                                                        // height:(driverList.isNotEmpty) ? media.height*1 : media.width*1,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  backgroundColor),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          12),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          12)),
                                                          color: page,
                                                        ),
                                                        padding: (driverList
                                                                .isNotEmpty)
                                                            ? EdgeInsets.fromLTRB(
                                                                0,
                                                                media.width *
                                                                        0.05 +
                                                                    MediaQuery.of(
                                                                            context)
                                                                        .padding
                                                                        .top,
                                                                0,
                                                                0)
                                                            : EdgeInsets.fromLTRB(
                                                                0,
                                                                media.width *
                                                                    0.05,
                                                                0,
                                                                media.width *
                                                                    0.05),
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    _cancel =
                                                                        true;
                                                                  });
                                                                },
                                                                child: Text(
                                                                  languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_cancel'],
                                                                  style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          media.width *
                                                                              sixteen,
                                                                      color: Colors
                                                                          .red),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.05,
                                                            ),
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_findingdriver'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            (driverList
                                                                    .isNotEmpty)
                                                                ? Expanded(
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          media.width *
                                                                              1,
                                                                      padding: EdgeInsets.fromLTRB(
                                                                          media.width * 0.05,
                                                                          media.width * 0.02,
                                                                          // media.width * 0.05 +
                                                                          //     MediaQuery.of(context)
                                                                          //         .padding
                                                                          //         .top,
                                                                          media.width * 0.05,
                                                                          media.width * 0.05),
                                                                      // color: Colors.transparent.withOpacity(0.4),
                                                                      child:
                                                                          SingleChildScrollView(
                                                                        child: Column(
                                                                            children: driverList
                                                                                .asMap()
                                                                                .map((key, value) {
                                                                                  return MapEntry(
                                                                                      key,
                                                                                      ValueListenableBuilder(
                                                                                          valueListenable: valueNotifierTimer.value,
                                                                                          builder: (context, value, child) {
                                                                                            var val = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(driverList[key]['bid_time'])).inSeconds - 140;
                                                                                            var calcDistance = calculateDistance(userRequestData['pick_lat'], userRequestData['pick_lng'], double.parse(driverList[key]['lat'].toString()), double.parse(driverList[key]['lng'].toString()));
                                                                                            if (int.parse(val.toString()) >= int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString())) {
                                                                                              FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}/drivers/${driverList[key]["driver_id"]}').update({
                                                                                                "is_rejected": 'by_user'
                                                                                              });
                                                                                            }
                                                                                            return Container(
                                                                                              margin: EdgeInsets.all(media.width * 0.020),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: backgroundColor), color: page, boxShadow: [
                                                                                                BoxShadow(blurRadius: 2, spreadRadius: 2, color: backgroundColor.withOpacity(0.4))
                                                                                              ]),
                                                                                              child: Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                  Container(
                                                                                                    height: 5,
                                                                                                    decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(15),
                                                                                                      color: backgroundColor,
                                                                                                    ),
                                                                                                    width: (val < int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString())) ? (media.width * 0.85 / int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString())) * (int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString()) - double.parse(val.toString())) : 0,
                                                                                                  ),
                                                                                                  Container(
                                                                                                    padding: EdgeInsets.all(media.width * 0.05),
                                                                                                    child: Column(
                                                                                                      children: [
                                                                                                        Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              width: media.width * 0.1,
                                                                                                              height: media.width * 0.1,
                                                                                                              decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(driverList[key]['driver_img']), fit: BoxFit.cover)),
                                                                                                            ),
                                                                                                            SizedBox(
                                                                                                              width: media.width * 0.05,
                                                                                                            ),
                                                                                                            Column(
                                                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                                                              children: [
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.4,
                                                                                                                  child: Text(
                                                                                                                    driverList[key]['driver_name'],
                                                                                                                    style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                                    textAlign: TextAlign.left,
                                                                                                                    maxLines: 1,
                                                                                                                  ),
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  height: media.width * 0.025,
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.4,
                                                                                                                  child: Text(
                                                                                                                    '${driverList[key]['vehicle_make']} ${driverList[key]['vehicle_model']}',
                                                                                                                    style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                                    textAlign: TextAlign.left,
                                                                                                                    maxLines: 1,
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ],
                                                                                                            ),
                                                                                                            SizedBox(
                                                                                                              width: media.width * 0.05,
                                                                                                            ),
                                                                                                            Column(
                                                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                                                              children: [
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.15,
                                                                                                                  child: Text(
                                                                                                                    rideList['currency'] + driverList[key]['price'],
                                                                                                                    style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                                    textAlign: TextAlign.center,
                                                                                                                    maxLines: 1,
                                                                                                                  ),
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  height: media.width * 0.025,
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.15,
                                                                                                                  child: Text(
                                                                                                                    (calcDistance != null) ? '${double.parse((calcDistance / 1000).toString()).toStringAsFixed(0)} km' : '',
                                                                                                                    style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                                    textAlign: TextAlign.center,
                                                                                                                    maxLines: 1,
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ],
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                        SizedBox(
                                                                                                          height: media.width * 0.05,
                                                                                                        ),
                                                                                                        Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                          children: [
                                                                                                            Button(
                                                                                                              onTap: () async {
                                                                                                                setState(() {
                                                                                                                  _isLoading = true;
                                                                                                                });
                                                                                                                var val = await acceptRequest(jsonEncode({
                                                                                                                  'driver_id': driverList[key]['driver_id'],
                                                                                                                  'request_id': userRequestData['id'],
                                                                                                                  'accepted_ride_fare': driverList[key]['price'].toString(),
                                                                                                                  'offerred_ride_fare': rideList['price'],
                                                                                                                }));
                                                                                                                if (val == 'success') {
                                                                                                                  await FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}').remove();
                                                                                                                }
                                                                                                                setState(() {
                                                                                                                  _isLoading = false;
                                                                                                                });
                                                                                                              },
                                                                                                              text: languages[choosenLanguage]['text_accept'],
                                                                                                              width: media.width * 0.35,
                                                                                                            ),
                                                                                                            // SizedBox(height: media.width*0.025,),
                                                                                                            Button(
                                                                                                              onTap: () async {
                                                                                                                setState(() {
                                                                                                                  _isLoading = true;
                                                                                                                });
                                                                                                                await FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}/drivers/driver_${driverList[key]["driver_id"]}').update({"is_rejected": 'by_user'});
                                                                                                                setState(() {
                                                                                                                  _isLoading = false;
                                                                                                                });
                                                                                                              },
                                                                                                              text: languages[choosenLanguage]['text_decline'],
                                                                                                              width: media.width * 0.35,
                                                                                                            )
                                                                                                          ],
                                                                                                        )
                                                                                                      ],
                                                                                                    ),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            );
                                                                                          }));
                                                                                })
                                                                                .values
                                                                                .toList()),
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Container(),
                                                            if (driverList
                                                                .isEmpty)
                                                              Column(
                                                                children: [
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.01,
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child: Text(
                                                                      '${languages[choosenLanguage]['text_offered_fare']} : ${rideList['currency']} ${rideList['price']}',
                                                                      style: GoogleFonts.poppins(
                                                                          fontSize: media.width *
                                                                              sixteen,
                                                                          color:
                                                                              textColor,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.01,
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child: Text(
                                                                      languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_current_fare'],
                                                                      style: GoogleFonts.poppins(
                                                                          fontSize: media.width *
                                                                              eighteen,
                                                                          color:
                                                                              textColor,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    padding: EdgeInsets.only(
                                                                        top: media.width *
                                                                            0.02),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceEvenly,
                                                                      children: [
                                                                        InkWell(
                                                                          onTap:
                                                                              () {
                                                                            if ((updateAmount.text.isNotEmpty &&
                                                                                double.parse(updateAmount.text.toString()) > double.parse(rideList['price'].toString()))) {
                                                                              setState(() {
                                                                                updateAmount.text = (updateAmount.text.isEmpty) ? (double.parse(rideList['price'].toString()) - 10).toString() : (double.parse(updateAmount.text.toString()) - 10).toString();
                                                                              });
                                                                            }
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                media.width * 0.2,
                                                                            alignment:
                                                                                Alignment.center,
                                                                            decoration:
                                                                                BoxDecoration(color: (updateAmount.text.isNotEmpty && double.parse(updateAmount.text.toString()) > double.parse(rideList['price'].toString())) ? buttonColor : borderLines, borderRadius: BorderRadius.circular(media.width * 0.04)),
                                                                            padding:
                                                                                EdgeInsets.all(media.width * 0.025),
                                                                            child:
                                                                                Text(
                                                                              '-10',
                                                                              style: GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: page),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.4,
                                                                          child:
                                                                              TextField(
                                                                            enabled:
                                                                                false,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            keyboardType:
                                                                                TextInputType.number,
                                                                            controller:
                                                                                updateAmount,
                                                                            decoration:
                                                                                InputDecoration(
                                                                              hintText: (rideList.isNotEmpty) ? rideList['price'].toString() : '',
                                                                              hintStyle: GoogleFonts.poppins(fontSize: media.width * sixteen, color: textColor),
                                                                              border: UnderlineInputBorder(borderSide: BorderSide(color: hintColor)),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        InkWell(
                                                                          onTap:
                                                                              () {
                                                                            setState(() {
                                                                              updateAmount.text = (updateAmount.text.isEmpty) ? (double.parse(rideList['price'].toString()) + 10).toString() : (double.parse(updateAmount.text.toString()) + 10).toString();
                                                                            });
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                media.width * 0.2,
                                                                            alignment:
                                                                                Alignment.center,
                                                                            decoration:
                                                                                BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(media.width * 0.04)),
                                                                            padding:
                                                                                EdgeInsets.all(media.width * 0.025),
                                                                            child:
                                                                                Text(
                                                                              '+10',
                                                                              style: GoogleFonts.poppins(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: page),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.02,
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child:
                                                                        Button(
                                                                      onTap:
                                                                          () async {
                                                                        if (updateAmount
                                                                            .text
                                                                            .isNotEmpty) {
                                                                          setState(
                                                                              () {
                                                                            _isLoading =
                                                                                true;
                                                                          });
                                                                          await FirebaseDatabase
                                                                              .instance
                                                                              .ref()
                                                                              .child('bid-meta/${userRequestData["id"]}')
                                                                              .update({
                                                                            'price':
                                                                                updateAmount.text,
                                                                            'updated_at':
                                                                                ServerValue.timestamp,
                                                                          });
                                                                          await FirebaseDatabase
                                                                              .instance
                                                                              .ref()
                                                                              .child('bid-meta/${userRequestData["id"]}/drivers')
                                                                              .remove();
                                                                          setState(
                                                                              () {
                                                                            updateAmount.clear();
                                                                            _isLoading =
                                                                                false;
                                                                          });
                                                                        }
                                                                      },
                                                                      text: languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_update'],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                            )
                                          : Positioned(
                                              bottom: 0,
                                              child: Container(
                                                width: media.width * 1,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  12),
                                                          topRight:
                                                              Radius.circular(
                                                                  12)),
                                                  color: page,
                                                ),
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                      width: media.width * 0.9,
                                                      child: MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_search_captain'],
                                                        size: media.width *
                                                            fourteen,
                                                        fontweight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    MyText(
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_finddriverdesc'],
                                                      size: media.width *
                                                          fourteen,
                                                      // textAlign: TextAlign.center,
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    SizedBox(
                                                      height: media.width * 0.4,
                                                      child: Image.asset(
                                                        'assets/images/ridesearching.png',
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    Container(
                                                      height:
                                                          media.width * 0.048,
                                                      width: media.width * 0.9,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(media
                                                                          .width *
                                                                      0.024),
                                                          color: Colors.grey),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Container(
                                                        height:
                                                            media.width * 0.048,
                                                        width: (media.width *
                                                            0.9 *
                                                            (timing /
                                                                userDetails[
                                                                    'maximum_time_for_find_drivers_for_regular_ride'])),
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius
                                                                .circular(media
                                                                        .width *
                                                                    0.024),
                                                            color: buttonColor),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        (timing != null)
                                                            ? Text(
                                                                '${Duration(seconds: timing).toString().substring(3, 7)} mins',
                                                                style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        media.width *
                                                                            ten,
                                                                    color: textColor
                                                                        .withOpacity(
                                                                            0.4)),
                                                              )
                                                            : Container()
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    Button(
                                                        width:
                                                            media.width * 0.5,
                                                        onTap: () async {
                                                          var val =
                                                              await cancelRequest();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          }
                                                        },
                                                        text: languages[
                                                                choosenLanguage]
                                                            ['text_cancel'])
                                                  ],
                                                ),
                                              ),
                                            )
                                      : Container(),
                                  (userRequestData.isNotEmpty &&
                                          userRequestData['accepted_at'] !=
                                              null)
                                      ? Positioned(
                                          bottom: 0,
                                          child: GestureDetector(
                                            onVerticalDragStart: (v) {
                                              start = v.globalPosition.dy;
                                              gesture.clear();
                                            },
                                            onVerticalDragUpdate: (v) {
                                              gesture.add(v.globalPosition.dy);
                                            },
                                            onVerticalDragEnd: (v) {
                                              if (gesture.isNotEmpty &&
                                                  start >
                                                      gesture[
                                                          gesture.length - 1] &&
                                                  _ontripBottom == false) {
                                                setState(() {
                                                  _ontripBottom = true;
                                                });
                                              } else if (gesture.isNotEmpty &&
                                                  start <
                                                      gesture[
                                                          gesture.length - 1] &&
                                                  _ontripBottom == true) {
                                                setState(() {
                                                  _ontripBottom = false;
                                                });
                                              }
                                            },
                                            child: Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.02),
                                                width: media.width * 1,
                                                // height: _ontripBottom == true?media.height*0.9:media.height*0.5,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: backgroundColor),
                                                    color: page,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    12),
                                                            topRight:
                                                                Radius.circular(
                                                                    12))),
                                                child: SingleChildScrollView(
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                          width:
                                                              media.width * 0.9,
                                                          child: Row(
                                                            // mainAxisAlignment:
                                                            //     MainAxisAlignment
                                                            //         .spaceEvenly,
                                                            children: [
                                                              SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.5,
                                                                  child: MyText(
                                                                    text: (userRequestData['accepted_at'] !=
                                                                                null &&
                                                                            userRequestData['arrived_at'] ==
                                                                                null)
                                                                        ? languages[choosenLanguage]
                                                                            [
                                                                            'text_driver_nearby']
                                                                        : (userRequestData['accepted_at'] != null &&
                                                                                userRequestData['arrived_at'] != null &&
                                                                                userRequestData['is_trip_start'] == 0)
                                                                            ? languages[choosenLanguage]['text_captain_wait']
                                                                            : (userRequestData['accepted_at'] != null && userRequestData['arrived_at'] != null && userRequestData['is_trip_start'] == 1)
                                                                                ? languages[choosenLanguage]['text_onride']
                                                                                : '',
                                                                    size: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontweight:
                                                                        FontWeight
                                                                            .bold,
                                                                    maxLines: 1,
                                                                  )),
                                                              // SizedBox(
                                                              //   width: media
                                                              //           .width *
                                                              //       0.4,
                                                              //   child: (userRequestData['is_trip_start'] !=
                                                              //               1 &&
                                                              //           userRequestData['show_otp_feature'] ==
                                                              //               true)
                                                              //       ? Row(
                                                              //           mainAxisAlignment:
                                                              //               MainAxisAlignment.end,
                                                              //           children: [
                                                              //             MyText(
                                                              //               text:
                                                              //                   'OTP : ',
                                                              //               size:
                                                              //                   media.width * fourteen,
                                                              //               textAlign:
                                                              //                   TextAlign.end,
                                                              //               color:
                                                              //                   backgroundColor,
                                                              //               fontweight:
                                                              //                   FontWeight.bold,
                                                              //               maxLines:
                                                              //                   1,
                                                              //             ),
                                                              //             MyText(
                                                              //               text:
                                                              //                   '${userRequestData['ride_otp']}',
                                                              //               size:
                                                              //                   media.width * sixteen,
                                                              //               textAlign:
                                                              //                   TextAlign.end,
                                                              //               color:
                                                              //                   Colors.green,
                                                              //               fontweight:
                                                              //                   FontWeight.bold,
                                                              //               maxLines:
                                                              //                   1,
                                                              //             ),
                                                              //           ],
                                                              //         )
                                                              //       : Container(),
                                                              // )
                                                            ],
                                                          )),
                                                      if ((userRequestData[
                                                              'is_trip_start'] !=
                                                          1))
                                                        SizedBox(
                                                          width:
                                                              media.width * 0.4,
                                                          child: (userRequestData[
                                                                          'is_trip_start'] !=
                                                                      1 &&
                                                                  userRequestData[
                                                                          'show_otp_feature'] ==
                                                                      true)
                                                              ? Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    MyText(
                                                                      text:
                                                                          'OTP : ',
                                                                      size: media
                                                                              .width *
                                                                          fourteen,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .end,
                                                                      color:
                                                                          backgroundColor,
                                                                      fontweight:
                                                                          FontWeight
                                                                              .bold,
                                                                      maxLines:
                                                                          1,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 15,
                                                                    ),
                                                                    MyText(
                                                                      text:
                                                                          '${userRequestData['ride_otp']}',
                                                                      size: media
                                                                              .width *
                                                                          eighteen,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .end,
                                                                      color: Colors
                                                                          .green,
                                                                      fontweight:
                                                                          FontWeight
                                                                              .bold,
                                                                      maxLines:
                                                                          1,
                                                                    ),
                                                                  ],
                                                                )
                                                              : Container(),
                                                        ),

                                                      //   Container(
                                                      //     margin: EdgeInsets.only(
                                                      //         top: media.width *
                                                      //             0.02),
                                                      //     padding:
                                                      //         EdgeInsets.all(
                                                      //             media.width *
                                                      //                 0.02),
                                                      //     decoration:
                                                      //         BoxDecoration(
                                                      //       border: Border.all(
                                                      //           color:
                                                      //               backgroundColor),
                                                      //       borderRadius:
                                                      //           BorderRadius
                                                      //               .circular(
                                                      //                   20),
                                                      //       color: (isDarkTheme ==
                                                      //               true)
                                                      //           ? Colors.black
                                                      //           : const Color(
                                                      //                   0xff5D2E8E)
                                                      //               .withOpacity(
                                                      //                   0.2),
                                                      //     ),
                                                      //     child: Row(
                                                      //       children: [
                                                      //         Image.asset(
                                                      //             'assets/images/car.png',
                                                      //             width: media
                                                      //                     .width *
                                                      //                 0.085,
                                                      //             height: media
                                                      //                     .width *
                                                      //                 0.085,
                                                      //             fit: BoxFit
                                                      //                 .contain,
                                                      //             color:
                                                      //                 textColor),
                                                      //         SizedBox(
                                                      //           width: media
                                                      //                   .width *
                                                      //               0.05,
                                                      //         ),
                                                      //         SizedBox(
                                                      //           width: media
                                                      //                   .width *
                                                      //               0.7,
                                                      //           child: MyText(
                                                      //               text: (userRequestData['accepted_at'] !=
                                                      //                           null &&
                                                      //                       userRequestData['arrived_at'] ==
                                                      //                           null)
                                                      //                   ? languages[choosenLanguage]['text_captain_nearby_desc'].replaceAll(
                                                      //                       '2',
                                                      //                       (_dist != null)
                                                      //                           ? double.parse(((_dist * 2)).toString())
                                                      //                               .round()
                                                      //                               .toString()
                                                      //                           : '-')
                                                      //                   : languages[choosenLanguage]['text_captain_arrived_desc'].replaceAll(
                                                      //                       '3',
                                                      //                       userRequestData['free_waiting_time_in_mins_before_trip_start']
                                                      //                           .toString()),
                                                      //               size: media
                                                      //                       .width *
                                                      //                   fourteen,
                                                      //               color:
                                                      //                   textColor),
                                                      //         )
                                                      //       ],
                                                      //     ),
                                                      //   ),

                                                      SizedBox(
                                                        height:
                                                            media.height * 0.02,
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                            media.width * 0.04),
                                                        decoration: BoxDecoration(
                                                            border: Border.all(
                                                                color:
                                                                    backgroundColor),
                                                            color: page,
                                                            borderRadius: BorderRadius.circular(10),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                  color: textColor
                                                                      .withOpacity(
                                                                          0.4),
                                                                  spreadRadius:
                                                                      2,
                                                                  blurRadius: 2)
                                                            ]),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.106,
                                                                      width: media
                                                                              .width *
                                                                          0.106,
                                                                      decoration: BoxDecoration(
                                                                          shape: BoxShape
                                                                              .circle,
                                                                          image: DecorationImage(
                                                                              image: NetworkImage(userRequestData['driverDetail']['data']['profile_picture']),
                                                                              fit: BoxFit.cover)),
                                                                    ),
                                                                    Column(
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.4,
                                                                          child:
                                                                              MyText(
                                                                            text:
                                                                                userRequestData['driverDetail']['data']['name'],
                                                                            size:
                                                                                media.width * fourteen,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.4,
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              Text(
                                                                                userRequestData['driverDetail']['data']['rating'].toString(),
                                                                                style: GoogleFonts.poppins(fontSize: media.width * twelve, color: textColor),
                                                                              ),
                                                                              Icon(
                                                                                Icons.star,
                                                                                color: isDarkTheme == true ? const Color(0xFFFF0000) : buttonColor,
                                                                                size: media.width * 0.04,
                                                                              )
                                                                            ],
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    MyText(
                                                                        text: userRequestData['payment_type_string']
                                                                            .toString(),
                                                                        size: media.width *
                                                                            sixteen,
                                                                        color:
                                                                            textColor),
                                                                    (userRequestData['is_bid_ride'] ==
                                                                            1)
                                                                        ? MyText(
                                                                            textAlign:
                                                                                TextAlign.end,
                                                                            text: userRequestData['requested_currency_symbol'] +
                                                                                ' ' +
                                                                                userRequestData['accepted_ride_fare'].toString(),
                                                                            size:
                                                                                media.width * eighteen,
                                                                            color:
                                                                                textColor,
                                                                          )
                                                                        : MyText(
                                                                            textAlign:
                                                                                TextAlign.end,
                                                                            text: userRequestData['requested_currency_symbol'] +
                                                                                ' ' +
                                                                                userRequestData['request_eta_amount'].toString(),
                                                                            size:
                                                                                media.width * eighteen,
                                                                            color:
                                                                                textColor,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            // Expanded(
                                                            //   child:
                                                            //       SingleChildScrollView(
                                                            //           scrollDirection:
                                                            //               Axis
                                                            //                   .horizontal,
                                                            //           child:
                                                            //               Row(
                                                            //             mainAxisAlignment:
                                                            //                 MainAxisAlignment.end,
                                                            //             children: [
                                                            //               Column(
                                                            //                 children: [
                                                            //                   SizedBox(width: media.width * 0.03),
                                                            //                   (widget.type == null)
                                                            //                       ? Column(
                                                            //                           children: [
                                                            //                             // Row(
                                                            //                             //   children: [
                                                            //                             // (userRequestData['payment_opt'].toString() == '1')
                                                            //                             //     ? Image.asset(
                                                            //                             //         'assets/images/cash.png',
                                                            //                             //         fit: BoxFit.contain,
                                                            //                             //       )
                                                            //                             //         : (userRequestData['payment_opt'].toString() == '2')
                                                            //                             //             ? Image.asset(
                                                            //                             //                 'assets/images/wallet.png',
                                                            //                             //                 fit: BoxFit.contain,
                                                            //                             //               )
                                                            //                             //             : (userRequestData['payment_opt'].toString() == '0')
                                                            //                             //                 ? Image.asset(
                                                            //                             //                     'assets/images/card.png',
                                                            //                             //                     fit: BoxFit.contain,
                                                            //                             //                   )
                                                            //                             //                 : Container(),
                                                            //                             //     SizedBox(width: media.width * 0.03),
                                                            //                             //     MyText(text: userRequestData['payment_type_string'].toString(), size: media.width * sixteen, color: textColor),
                                                            //                             //   ],
                                                            //                             // ),
                                                            //                             SizedBox(
                                                            //                               width: media.width * 0.02,
                                                            //                             ),
                                                            //                             // (userRequestData['is_bid_ride'] == 1)
                                                            //                             //     ? MyText(
                                                            //                             //         textAlign: TextAlign.end,
                                                            //                             //         text: userRequestData['requested_currency_symbol'] + ' ' + userRequestData['accepted_ride_fare'].toString(),
                                                            //                             //         size: media.width * eighteen,
                                                            //                             //         color: textColor,
                                                            //                             //       )
                                                            //                             //     : MyText(
                                                            //                             //         textAlign: TextAlign.end,
                                                            //                             //         text: userRequestData['requested_currency_symbol'] + ' ' + userRequestData['request_eta_amount'].toString(),
                                                            //                             //         size: media.width * eighteen,
                                                            //                             //         color: textColor,
                                                            //                             //         maxLines: 1,
                                                            //                             //       ),
                                                            //                           ],
                                                            //                         )
                                                            //                       : Container(),
                                                            //                   (widget.type != 1) ? SizedBox(height: media.width * 0.03) : Container(),
                                                            //                   // SizedBox(
                                                            //                   //   width: media.width * 0.4,
                                                            //                   //   child: MyText(
                                                            //                   //     text: userRequestData['driverDetail']['data']['car_number'],
                                                            //                   //     textAlign: TextAlign.end,
                                                            //                   //     size: media.width * sixteen,
                                                            //                   //     maxLines: 1,
                                                            //                   //     fontweight: FontWeight.bold,
                                                            //                   //   ),
                                                            //                   // ),
                                                            //                   SizedBox(height: media.width * 0.03),
                                                            //                   // SizedBox(
                                                            //                   //   width: media.width * 0.4,
                                                            //                   //   child: MyText(
                                                            //                   //     text: '${userRequestData['driverDetail']['data']['car_color']},${userRequestData['driverDetail']['data']['car_make_name']},${userRequestData['driverDetail']['data']['car_model_name']}',
                                                            //                   //     size: media.width * fourteen,
                                                            //                   //     textAlign: TextAlign.end,
                                                            //                   //     maxLines: 1,
                                                            //                   //   ),
                                                            //                   // ),
                                                            //                   SizedBox(
                                                            //                     height: media.width * 0.02,
                                                            //                   ),
                                                            //                   if (userRequestData['is_trip_start'] != 1)
                                                            //                     SizedBox(
                                                            //                       width: media.width * 0.4,
                                                            //                       child: Row(
                                                            //                         mainAxisAlignment: MainAxisAlignment.end,
                                                            //                         children: [
                                                            //                           InkWell(
                                                            //                             onTap: () async {
                                                            //                               var result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                                                            //                               if (result) {
                                                            //                                 setState(() {});
                                                            //                               }
                                                            //                             },
                                                            //                             child: Stack(
                                                            //                               children: [
                                                            //                                 // Container(
                                                            //                                 //   height: media.width * 0.096,
                                                            //                                 //   width: media.width * 0.096,
                                                            //                                 //   decoration: BoxDecoration(border: Border.all(color: const Color(0xffF3F3F3), width: 1.5), borderRadius: BorderRadius.circular(8)),
                                                            //                                 //   alignment: Alignment.center,
                                                            //                                 //   child: Image.asset(
                                                            //                                 //     'assets/images/chat.png',
                                                            //                                 //     height: media.width * 0.05,
                                                            //                                 //     width: media.width * 0.05,
                                                            //                                 //     fit: BoxFit.contain,
                                                            //                                 //   ),
                                                            //                                 // ),
                                                            //                                 if (chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).isNotEmpty)
                                                            //                                   Positioned(
                                                            //                                       top: media.width * 0.01,
                                                            //                                       right: media.width * 0.01,
                                                            //                                       child: Text(
                                                            //                                         chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).length.toString(),
                                                            //                                         style: GoogleFonts.poppins(fontSize: media.width * twelve, color: const Color(0xffFF0000)),
                                                            //                                       ))
                                                            //                               ],
                                                            //                             ),
                                                            //                           ),
                                                            //                           SizedBox(
                                                            //                             width: media.width * 0.025,
                                                            //                           ),
                                                            // InkWell(
                                                            //   onTap: () {
                                                            //     makingPhoneCall(userRequestData['driverDetail']['data']['mobile']);
                                                            //   },
                                                            //   child: Container(
                                                            //     height: media.width * 0.096,
                                                            //     width: media.width * 0.096,
                                                            //     decoration: BoxDecoration(border: Border.all(color: const Color(0xffF3F3F3), width: 1.5), borderRadius: BorderRadius.circular(8)),
                                                            //     alignment: Alignment.center,
                                                            //     child: Image.asset(
                                                            //       'assets/images/call.png',
                                                            //       height: media.width * 0.05,
                                                            //       width: media.width * 0.05,
                                                            //       fit: BoxFit.contain,
                                                            //     ),
                                                            //   ),
                                                            // )
                                                            //                         ],
                                                            //                       ),
                                                            //                     )
                                                            //                 ],
                                                            //               ),
                                                            //             ],
                                                            //           )),
                                                            // ),

                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Column(
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        MyText(
                                                                          text:
                                                                              'Vechile No: ',
                                                                          textAlign:
                                                                              TextAlign.end,
                                                                          size: media.width *
                                                                              fourteen,
                                                                          maxLines:
                                                                              1,
                                                                          fontweight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                        MyText(
                                                                          text:
                                                                              ' ${userRequestData['driverDetail']['data']['car_number']}',
                                                                          textAlign:
                                                                              TextAlign.end,
                                                                          size: media.width *
                                                                              sixteen,
                                                                          maxLines:
                                                                              1,
                                                                          fontweight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    MyText(
                                                                      text:
                                                                          '${userRequestData['driverDetail']['data']['car_color']}, ${userRequestData['driverDetail']['data']['car_make_name']}, ${userRequestData['driverDetail']['data']['car_model_name']}',
                                                                      size: media
                                                                              .width *
                                                                          fourteen,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .end,
                                                                      maxLines:
                                                                          1,
                                                                    ),
                                                                  ],
                                                                ),
                                                                InkWell(
                                                                  onTap: () {
                                                                    makingPhoneCall(userRequestData['driverDetail']
                                                                            [
                                                                            'data']
                                                                        [
                                                                        'mobile']);
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height: media
                                                                            .width *
                                                                        0.096,
                                                                    width: media
                                                                            .width *
                                                                        0.096,
                                                                    decoration: BoxDecoration(
                                                                        border: Border.all(
                                                                            color: const Color(
                                                                                0xffF3F3F3),
                                                                            width:
                                                                                1.5),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8)),
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/images/call.png',
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                      width: media
                                                                              .width *
                                                                          0.05,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (_ontripBottom == true)
                                                        SizedBox(
                                                          height: media.width *
                                                              0.05,
                                                        ),
                                                      if (_ontripBottom == true)
                                                        Container(
                                                            decoration: BoxDecoration(
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      color: textColor.withOpacity(
                                                                          0.4),
                                                                      blurRadius:
                                                                          2,
                                                                      spreadRadius:
                                                                          2)
                                                                ],
                                                                color: page,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12)),
                                                            width: media.width *
                                                                0.9,
                                                            child: Column(
                                                              children: [
                                                                (userRequestData['is_rental'] !=
                                                                            true &&
                                                                        userRequestData['drop_address'] !=
                                                                            null)
                                                                    ? Container(
                                                                        padding:
                                                                            EdgeInsets.all(media.width *
                                                                                0.05),
                                                                        child:
                                                                            SingleChildScrollView(
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                children: [
                                                                                  Container(
                                                                                    height: media.width * 0.05,
                                                                                    width: media.width * 0.05,
                                                                                    alignment: Alignment.center,
                                                                                    child: Image.asset('assets/images/circle_icon.png'),
                                                                                    // decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                                                                    // child: Container(
                                                                                    //   height: media.width * 0.025,
                                                                                    //   width: media.width * 0.025,
                                                                                    //   decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                                    // ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.06,
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: MyText(
                                                                                      text: userRequestData['pick_address'],
                                                                                      size: media.width * twelve,
                                                                                      // maxLines: 1,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              SizedBox(
                                                                                height: media.width * 0.02,
                                                                              ),
                                                                              (tripStops.isNotEmpty)
                                                                                  ? Column(
                                                                                      children: tripStops
                                                                                          .asMap()
                                                                                          .map((i, value) {
                                                                                            return MapEntry(
                                                                                                i,
                                                                                                (i < tripStops.length - 1)
                                                                                                    ? Container(
                                                                                                        padding: EdgeInsets.only(top: media.width * 0.02, bottom: media.width * 0.02),
                                                                                                        child: Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              height: media.width * 0.06,
                                                                                                              width: media.width * 0.06,
                                                                                                              alignment: Alignment.center,
                                                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                              child: MyText(
                                                                                                                text: (i + 1).toString(),
                                                                                                                // maxLines: 1,
                                                                                                                color: const Color(0xFFFF0000),
                                                                                                                fontweight: FontWeight.w600,
                                                                                                                size: media.width * twelve,
                                                                                                              ),
                                                                                                            ),
                                                                                                            SizedBox(
                                                                                                              width: media.width * 0.05,
                                                                                                            ),
                                                                                                            Expanded(
                                                                                                              child: MyText(
                                                                                                                text: tripStops[i]['address'],
                                                                                                                // maxLines: 1,
                                                                                                                size: media.width * twelve,
                                                                                                              ),
                                                                                                            ),
                                                                                                          ],
                                                                                                        ),
                                                                                                      )
                                                                                                    : Container());
                                                                                          })
                                                                                          .values
                                                                                          .toList(),
                                                                                    )
                                                                                  : Container(),
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                children: [
                                                                                  Container(
                                                                                    height: media.width * 0.05,
                                                                                    width: media.width * 0.05,
                                                                                    alignment: Alignment.center,
                                                                                    child: Image.asset('assets/images/drop_icon.png'),
                                                                                    // decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                    // child: Icon(
                                                                                    //   Icons.location_on_outlined,
                                                                                    //   size: media.width * 0.03,
                                                                                    //   color: const Color(0xFFFF0000),
                                                                                    // ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.05,
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: MyText(
                                                                                      text: userRequestData['drop_address'],
                                                                                      size: media.width * twelve,
                                                                                      // maxLines: 1,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : Container(
                                                                        height: media.width *
                                                                            0.1,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        padding: EdgeInsets.only(
                                                                            left: media.width *
                                                                                0.05,
                                                                            right:
                                                                                media.width * 0.05),
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Container(
                                                                              height: media.width * 0.05,
                                                                              width: media.width * 0.05,
                                                                              alignment: Alignment.center,
                                                                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
                                                                              child: Container(
                                                                                height: media.width * 0.025,
                                                                                width: media.width * 0.025,
                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              width: media.width * 0.06,
                                                                            ),
                                                                            Expanded(
                                                                              child: MyText(
                                                                                text: userRequestData['pick_address'],
                                                                                size: media.width * twelve,
                                                                                // maxLines: 1,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                              ],
                                                            )),
                                                      (userRequestData[
                                                                  'is_trip_start'] !=
                                                              1)
                                                          ? Column(
                                                              children: [
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.05,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    (userRequestData['is_trip_start'] !=
                                                                            1)
                                                                        ? InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              setState(() {
                                                                                _isLoading = true;
                                                                              });
                                                                              var reason = await cancelReason((userRequestData['is_driver_arrived'] == 0) ? 'before' : 'after');
                                                                              if (reason == true) {
                                                                                setState(() {
                                                                                  _cancellingError = '';
                                                                                  _cancelReason = '';
                                                                                  _cancelling = true;
                                                                                });
                                                                              }
                                                                              setState(() {
                                                                                _isLoading = false;
                                                                              });
                                                                            },
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                // Image.asset(
                                                                                //   'assets/images/cancelimage.png',
                                                                                //   height: media.width * 0.064,
                                                                                //   width: media.width * 0.064,
                                                                                //   fit: BoxFit.contain,
                                                                                // ),
                                                                                MyText(
                                                                                  text: languages[choosenLanguage]['text_cancel_booking'],
                                                                                  size: media.width * sixteen,
                                                                                  fontweight: FontWeight.bold,
                                                                                  color: const Color(0xffF95858),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          )
                                                                        : Container(),
                                                                  ],
                                                                ),
                                                              ],
                                                            )
                                                          : Container(),
                                                    ],
                                                  ),
                                                )),
                                          ))
                                      : Container(),

                                  //cancel request
                                  (_cancelling == true)
                                      ? Positioned(
                                          child: Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          color: Colors.transparent
                                              .withOpacity(0.6),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                width: media.width * 0.9,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: backgroundColor),
                                                    color: page,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                child: Column(children: [
                                                  Container(
                                                    height: media.width * 0.18,
                                                    width: media.width * 0.18,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xffFEF2F2)),
                                                    alignment: Alignment.center,
                                                    child: Container(
                                                      height:
                                                          media.width * 0.14,
                                                      width: media.width * 0.14,
                                                      decoration:
                                                          const BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: Color(
                                                                  0xffFF0000)),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.cancel_outlined,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: cancelReasonsList
                                                        .asMap()
                                                        .map((i, value) {
                                                          return MapEntry(
                                                              i,
                                                              InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    _cancelReason =
                                                                        cancelReasonsList[i]
                                                                            [
                                                                            'reason'];
                                                                  });
                                                                },
                                                                child:
                                                                    Container(
                                                                  padding: EdgeInsets
                                                                      .all(media
                                                                              .width *
                                                                          0.01),
                                                                  child: Row(
                                                                    children: [
                                                                      Container(
                                                                        height: media.height *
                                                                            0.05,
                                                                        width: media.width *
                                                                            0.05,
                                                                        decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            border: Border.all(color: textColor, width: 1.2)),
                                                                        alignment:
                                                                            Alignment.center,
                                                                        child: (_cancelReason ==
                                                                                cancelReasonsList[i]['reason'])
                                                                            ? Container(
                                                                                height: media.width * 0.03,
                                                                                width: media.width * 0.03,
                                                                                decoration: BoxDecoration(
                                                                                  shape: BoxShape.circle,
                                                                                  color: textColor,
                                                                                ),
                                                                              )
                                                                            : Container(),
                                                                      ),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.05,
                                                                      ),
                                                                      SizedBox(
                                                                          width: media.width *
                                                                              0.65,
                                                                          child:
                                                                              MyText(
                                                                            text:
                                                                                cancelReasonsList[i]['reason'],
                                                                            size:
                                                                                media.width * twelve,
                                                                          ))
                                                                    ],
                                                                  ),
                                                                ),
                                                              ));
                                                        })
                                                        .values
                                                        .toList(),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _cancelReason =
                                                            'others';
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.01),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.height *
                                                                    0.05,
                                                            width: media.width *
                                                                0.05,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    color:
                                                                        textColor,
                                                                    width:
                                                                        1.2)),
                                                            alignment: Alignment
                                                                .center,
                                                            child:
                                                                (_cancelReason ==
                                                                        'others')
                                                                    ? Container(
                                                                        height: media.width *
                                                                            0.03,
                                                                        width: media.width *
                                                                            0.03,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          color:
                                                                              textColor,
                                                                        ),
                                                                      )
                                                                    : Container(),
                                                          ),
                                                          SizedBox(
                                                            width: media.width *
                                                                0.05,
                                                          ),
                                                          MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                ['text_others'],
                                                            size: media.width *
                                                                twelve,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  (_cancelReason == 'others')
                                                      ? Container(
                                                          margin: EdgeInsets
                                                              .fromLTRB(
                                                                  0,
                                                                  media.width *
                                                                      0.025,
                                                                  0,
                                                                  media.width *
                                                                      0.025),
                                                          padding:
                                                              EdgeInsets.all(
                                                                  media.width *
                                                                      0.05),
                                                          // height: media.width*0.2,
                                                          width:
                                                              media.width * 0.9,
                                                          decoration: BoxDecoration(
                                                              border: Border.all(
                                                                  color: (isDarkTheme ==
                                                                          true)
                                                                      ? textColor
                                                                      : borderLines,
                                                                  width: 1.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                          child: TextField(
                                                            decoration: InputDecoration(
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                                hintText: languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_cancelRideReason'],
                                                                hintStyle: GoogleFonts.poppins(
                                                                    color: textColor
                                                                        .withOpacity(
                                                                            0.4),
                                                                    fontSize: media
                                                                            .width *
                                                                        twelve)),
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    color:
                                                                        textColor),
                                                            maxLines: 4,
                                                            minLines: 2,
                                                            onChanged: (val) {
                                                              setState(() {
                                                                _cancelCustomReason =
                                                                    val;
                                                              });
                                                            },
                                                          ),
                                                        )
                                                      : Container(),
                                                  (_cancellingError != '')
                                                      ? Container(
                                                          padding: EdgeInsets.only(
                                                              top: media.width *
                                                                  0.02,
                                                              bottom:
                                                                  media.width *
                                                                      0.02),
                                                          width:
                                                              media.width * 0.9,
                                                          child: Text(
                                                              _cancellingError,
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve,
                                                                  color: Colors
                                                                      .red)))
                                                      : Container(),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Button(
                                                          color: page,
                                                          textcolor:
                                                              buttonColor,
                                                          borcolor: buttonColor,
                                                          width: media.width *
                                                              0.39,
                                                          onTap: () async {
                                                            setState(() {
                                                              _isLoading = true;
                                                            });
                                                            if (_cancelReason !=
                                                                '') {
                                                              if (_cancelReason ==
                                                                  'others') {
                                                                if (_cancelCustomReason !=
                                                                        '' &&
                                                                    _cancelCustomReason
                                                                        .isNotEmpty) {
                                                                  _cancellingError =
                                                                      '';
                                                                  var val =
                                                                      await cancelRequestWithReason(
                                                                          _cancelCustomReason);
                                                                  if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  }
                                                                  setState(() {
                                                                    _cancelling =
                                                                        false;
                                                                  });
                                                                } else {
                                                                  setState(() {
                                                                    _cancellingError =
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_add_cancel_reason'];
                                                                  });
                                                                }
                                                              } else {
                                                                var val =
                                                                    await cancelRequestWithReason(
                                                                        _cancelReason);
                                                                if (val ==
                                                                    'logout') {
                                                                  navigateLogout();
                                                                }
                                                                setState(() {
                                                                  _cancelling =
                                                                      false;
                                                                });
                                                              }
                                                            } else {}
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_cancel']),
                                                      Button(
                                                          width: media.width *
                                                              0.39,
                                                          onTap: () {
                                                            setState(() {
                                                              _cancelling =
                                                                  false;
                                                            });
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              [
                                                              'tex_dontcancel'])
                                                    ],
                                                  )
                                                ]),
                                              ),
                                            ],
                                          ),
                                        ))
                                      : Container(),

                                  //date picker for ride later
                                  (_dateTimePicker == true)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: media.width * 0.9,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                          height: media.height *
                                                              0.1,
                                                          width: media.width *
                                                              0.1,
                                                          decoration:
                                                              BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: page),
                                                          child: InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _dateTimePicker =
                                                                      false;
                                                                });
                                                              },
                                                              child: Icon(
                                                                  Icons
                                                                      .cancel_outlined,
                                                                  color:
                                                                      textColor))),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  height: media.width * 0.5,
                                                  width: media.width * 0.9,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      color: topBar),
                                                  child: CupertinoDatePicker(
                                                      minimumDate: DateTime.now()
                                                          .add(Duration(
                                                              minutes: int.parse(
                                                                  userDetails[
                                                                      'user_can_make_a_ride_after_x_miniutes']))),
                                                      initialDateTime: DateTime.now()
                                                          .add(Duration(
                                                              minutes: int.parse(
                                                                  userDetails[
                                                                      'user_can_make_a_ride_after_x_miniutes']))),
                                                      maximumDate:
                                                          DateTime.now().add(
                                                              const Duration(
                                                                  days: 4)),
                                                      onDateTimeChanged: (val) {
                                                        choosenDateTime = val;
                                                      }),
                                                ),
                                                Container(
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.05),
                                                    child: Button(
                                                        onTap: () {
                                                          setState(() {
                                                            _dateTimePicker =
                                                                false;
                                                            _confirmRideLater =
                                                                true;
                                                          });
                                                        },
                                                        text: languages[
                                                                choosenLanguage]
                                                            ['text_confirm']))
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //confirm ride later
                                  (_confirmRideLater == true)
                                      ? Positioned(
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: media.width * 0.9,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                          height: media.height *
                                                              0.1,
                                                          width: media.width *
                                                              0.1,
                                                          decoration:
                                                              BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: page),
                                                          child: InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _dateTimePicker =
                                                                      true;
                                                                  _confirmRideLater =
                                                                      false;
                                                                });
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .cancel_outlined))),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  width: media.width * 0.9,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      color: page),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_confirmridelater'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Text(
                                                        DateFormat()
                                                            .format(
                                                                choosenDateTime)
                                                            .toString(),
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    sixteen,
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Button(
                                                          onTap: () async {
                                                            if (widget.type !=
                                                                1) {
                                                              if (etaDetails[
                                                                          choosenVehicle]
                                                                      [
                                                                      'has_discount'] ==
                                                                  false) {
                                                                dynamic val;
                                                                setState(() {
                                                                  _isLoading =
                                                                      true;
                                                                });
                                                                if (choosenTransportType ==
                                                                    0) {
                                                                  val = await createRequestLater(
                                                                      (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                          ? jsonEncode({
                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                              'drop_lat': addressList.firstWhere((e) => e.type == 'drop').latlng.latitude,
                                                                              'drop_lng': addressList.firstWhere((e) => e.type == 'drop').latlng.longitude,
                                                                              'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                              'ride_type': 1,
                                                                              'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                  ? 0
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                      ? 1
                                                                                      : 2,
                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                              'drop_address': addressList.firstWhere((e) => e.type == 'drop').address,
                                                                              'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                              'is_later': true,
                                                                              'stops': jsonEncode(dropStopList),
                                                                              'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                            })
                                                                          : jsonEncode({
                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                              'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                              'ride_type': 1,
                                                                              'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                  ? 0
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                      ? 1
                                                                                      : 2,
                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                              'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                              'is_later': true,
                                                                              'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                            }),
                                                                      'api/v1/request/create');
                                                                } else {
                                                                  if (dropStopList
                                                                      .isNotEmpty) {
                                                                    val = await createRequestLater(
                                                                        jsonEncode({
                                                                          'pick_lat': addressList[0]
                                                                              .latlng
                                                                              .latitude,
                                                                          'pick_lng': addressList[0]
                                                                              .latlng
                                                                              .longitude,
                                                                          'drop_lat': addressList[addressList.length - 1]
                                                                              .latlng
                                                                              .latitude,
                                                                          'drop_lng': addressList[addressList.length - 1]
                                                                              .latlng
                                                                              .longitude,
                                                                          'vehicle_type':
                                                                              etaDetails[choosenVehicle]['zone_type_id'],
                                                                          'ride_type':
                                                                              1,
                                                                          'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                              ? 0
                                                                              : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                  ? 1
                                                                                  : 2,
                                                                          'pick_address':
                                                                              addressList[0].address,
                                                                          'drop_address':
                                                                              addressList[addressList.length - 1].address,
                                                                          'trip_start_time': choosenDateTime.toString().substring(
                                                                              0,
                                                                              19),
                                                                          'is_later':
                                                                              true,
                                                                          'pickup_poc_name':
                                                                              addressList[0].name,
                                                                          'pickup_poc_mobile':
                                                                              addressList[0].number,
                                                                          'pickup_poc_instruction':
                                                                              addressList[0].instructions,
                                                                          'drop_poc_name':
                                                                              addressList[addressList.length - 1].name,
                                                                          'drop_poc_mobile':
                                                                              addressList[addressList.length - 1].number,
                                                                          'drop_poc_instruction':
                                                                              addressList[addressList.length - 1].instructions,
                                                                          'goods_type_id':
                                                                              selectedGoodsId.toString(),
                                                                          'stops':
                                                                              jsonEncode(dropStopList),
                                                                          'goods_type_quantity':
                                                                              goodsSize
                                                                        }),
                                                                        'api/v1/request/delivery/create');
                                                                  } else {
                                                                    val = await createRequestLater(
                                                                        jsonEncode({
                                                                          'pick_lat': addressList[0]
                                                                              .latlng
                                                                              .latitude,
                                                                          'pick_lng': addressList[0]
                                                                              .latlng
                                                                              .longitude,
                                                                          'drop_lat': addressList[addressList.length - 1]
                                                                              .latlng
                                                                              .latitude,
                                                                          'drop_lng': addressList[addressList.length - 1]
                                                                              .latlng
                                                                              .longitude,
                                                                          'vehicle_type':
                                                                              etaDetails[choosenVehicle]['zone_type_id'],
                                                                          'ride_type':
                                                                              1,
                                                                          'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                              ? 0
                                                                              : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                  ? 1
                                                                                  : 2,
                                                                          'pick_address':
                                                                              addressList[0].address,
                                                                          'drop_address':
                                                                              addressList[addressList.length - 1].address,
                                                                          'trip_start_time': choosenDateTime.toString().substring(
                                                                              0,
                                                                              19),
                                                                          'is_later':
                                                                              true,
                                                                          'pickup_poc_name':
                                                                              addressList[0].name,
                                                                          'pickup_poc_mobile':
                                                                              addressList[0].number,
                                                                          'pickup_poc_instruction':
                                                                              addressList[0].instructions,
                                                                          'drop_poc_name':
                                                                              addressList[addressList.length - 1].name,
                                                                          'drop_poc_mobile':
                                                                              addressList[addressList.length - 1].number,
                                                                          'drop_poc_instruction':
                                                                              addressList[addressList.length - 1].instructions,
                                                                          'goods_type_id':
                                                                              selectedGoodsId.toString(),
                                                                          'goods_type_quantity':
                                                                              goodsSize
                                                                        }),
                                                                        'api/v1/request/delivery/create');
                                                                  }
                                                                }
                                                                setState(() {
                                                                  if (val ==
                                                                      'success') {
                                                                    _isLoading =
                                                                        false;
                                                                    _confirmRideLater =
                                                                        false;
                                                                    _rideLaterSuccess =
                                                                        true;
                                                                  } else if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  }
                                                                });
                                                              } else {
                                                                dynamic val;
                                                                setState(() {
                                                                  _isLoading =
                                                                      true;
                                                                });

                                                                if (choosenTransportType ==
                                                                    0) {
                                                                  val = await createRequestLater(
                                                                      (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                          ? jsonEncode({
                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                              'drop_lat': addressList.firstWhere((e) => e.type == 'drop').latlng.latitude,
                                                                              'drop_lng': addressList.firstWhere((e) => e.type == 'drop').latlng.longitude,
                                                                              'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                              'ride_type': 1,
                                                                              'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                  ? 0
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                      ? 1
                                                                                      : 2,
                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                              'drop_address': addressList.firstWhere((e) => e.type == 'drop').address,
                                                                              'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                              'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                              'is_later': true,
                                                                              'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                            })
                                                                          : jsonEncode({
                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                              'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                              'ride_type': 1,
                                                                              'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                  ? 0
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                      ? 1
                                                                                      : 2,
                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                              'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                              'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                              'is_later': true,
                                                                              'request_eta_amount': etaDetails[choosenVehicle]['total']
                                                                            }),
                                                                      'api/v1/request/create');
                                                                } else {
                                                                  if (dropStopList
                                                                      .isNotEmpty) {
                                                                    val = await createRequestLater(
                                                                        jsonEncode({
                                                                          'pick_lat': addressList[0]
                                                                              .latlng
                                                                              .latitude,
                                                                          'pick_lng': addressList[0]
                                                                              .latlng
                                                                              .longitude,
                                                                          'drop_lat': addressList[addressList.length - 1]
                                                                              .latlng
                                                                              .latitude,
                                                                          'drop_lng': addressList[addressList.length - 1]
                                                                              .latlng
                                                                              .longitude,
                                                                          'vehicle_type':
                                                                              etaDetails[choosenVehicle]['zone_type_id'],
                                                                          'ride_type':
                                                                              1,
                                                                          'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                              ? 0
                                                                              : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                  ? 1
                                                                                  : 2,
                                                                          'pick_address':
                                                                              addressList[0].address,
                                                                          'drop_address':
                                                                              addressList[addressList.length - 1].address,
                                                                          'promocode_id':
                                                                              etaDetails[choosenVehicle]['promocode_id'],
                                                                          'trip_start_time': choosenDateTime.toString().substring(
                                                                              0,
                                                                              19),
                                                                          'is_later':
                                                                              true,
                                                                          'pickup_poc_name':
                                                                              addressList[0].name,
                                                                          'pickup_poc_mobile':
                                                                              addressList[0].number,
                                                                          'pickup_poc_instruction':
                                                                              addressList[0].instructions,
                                                                          'drop_poc_name':
                                                                              addressList[addressList.length - 1].name,
                                                                          'drop_poc_mobile':
                                                                              addressList[addressList.length - 1].number,
                                                                          'drop_poc_instruction':
                                                                              addressList[addressList.length - 1].instructions,
                                                                          'goods_type_id':
                                                                              selectedGoodsId.toString(),
                                                                          'stops':
                                                                              jsonEncode(dropStopList),
                                                                          'goods_type_quantity':
                                                                              goodsSize
                                                                        }),
                                                                        'api/v1/request/delivery/create');
                                                                  } else {
                                                                    val = await createRequestLater(
                                                                        jsonEncode({
                                                                          'pick_lat': addressList[0]
                                                                              .latlng
                                                                              .latitude,
                                                                          'pick_lng': addressList[0]
                                                                              .latlng
                                                                              .longitude,
                                                                          'drop_lat': addressList[addressList.length - 1]
                                                                              .latlng
                                                                              .latitude,
                                                                          'drop_lng': addressList[addressList.length - 1]
                                                                              .latlng
                                                                              .longitude,
                                                                          'vehicle_type':
                                                                              etaDetails[choosenVehicle]['zone_type_id'],
                                                                          'ride_type':
                                                                              1,
                                                                          'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                              ? 0
                                                                              : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                  ? 1
                                                                                  : 2,
                                                                          'pick_address':
                                                                              addressList[0].address,
                                                                          'drop_address':
                                                                              addressList[addressList.length - 1].address,
                                                                          'promocode_id':
                                                                              etaDetails[choosenVehicle]['promocode_id'],
                                                                          'trip_start_time': choosenDateTime.toString().substring(
                                                                              0,
                                                                              19),
                                                                          'is_later':
                                                                              true,
                                                                          'pickup_poc_name':
                                                                              addressList[0].name,
                                                                          'pickup_poc_mobile':
                                                                              addressList[0].number,
                                                                          'pickup_poc_instruction':
                                                                              addressList[0].instructions,
                                                                          'drop_poc_name':
                                                                              addressList[addressList.length - 1].name,
                                                                          'drop_poc_mobile':
                                                                              addressList[addressList.length - 1].number,
                                                                          'drop_poc_instruction':
                                                                              addressList[addressList.length - 1].instructions,
                                                                          'goods_type_id':
                                                                              selectedGoodsId.toString(),
                                                                          'goods_type_quantity':
                                                                              goodsSize
                                                                        }),
                                                                        'api/v1/request/delivery/create');
                                                                  }
                                                                }
                                                                setState(() {
                                                                  if (val ==
                                                                      'success') {
                                                                    _isLoading =
                                                                        false;

                                                                    _confirmRideLater =
                                                                        false;
                                                                    _rideLaterSuccess =
                                                                        true;
                                                                  } else if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  }
                                                                });
                                                              }
                                                            } else {
                                                              if (rentalOption[
                                                                          choosenVehicle]
                                                                      [
                                                                      'has_discount'] ==
                                                                  false) {
                                                                dynamic val;
                                                                setState(() {
                                                                  _isLoading =
                                                                      true;
                                                                });

                                                                if (choosenTransportType ==
                                                                    0) {
                                                                  val = await createRequestLater(
                                                                      jsonEncode({
                                                                        'pick_lat': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .latitude,
                                                                        'pick_lng': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .longitude,
                                                                        'vehicle_type':
                                                                            rentalOption[choosenVehicle]['zone_type_id'],
                                                                        'ride_type':
                                                                            1,
                                                                        'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                                'card')
                                                                            ? 0
                                                                            : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                ? 1
                                                                                : 2,
                                                                        'pick_address': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .address,
                                                                        'trip_start_time': choosenDateTime
                                                                            .toString()
                                                                            .substring(0,
                                                                                19),
                                                                        'is_later':
                                                                            true,
                                                                        'request_eta_amount':
                                                                            rentalOption[choosenVehicle]['fare_amount'],
                                                                        'rental_pack_id':
                                                                            etaDetails[rentalChoosenOption]['id']
                                                                      }),
                                                                      'api/v1/request/create');
                                                                } else {
                                                                  val = await createRequestLater(
                                                                      jsonEncode({
                                                                        'pick_lat': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .latitude,
                                                                        'pick_lng': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .longitude,
                                                                        'vehicle_type':
                                                                            rentalOption[choosenVehicle]['zone_type_id'],
                                                                        'ride_type':
                                                                            1,
                                                                        'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                                'card')
                                                                            ? 0
                                                                            : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                ? 1
                                                                                : 2,
                                                                        'pick_address': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .address,
                                                                        'trip_start_time': choosenDateTime
                                                                            .toString()
                                                                            .substring(0,
                                                                                19),
                                                                        'is_later':
                                                                            true,
                                                                        'request_eta_amount':
                                                                            rentalOption[choosenVehicle]['fare_amount'],
                                                                        'rental_pack_id':
                                                                            etaDetails[rentalChoosenOption]['id'],
                                                                        'goods_type_id':
                                                                            selectedGoodsId.toString(),
                                                                        'goods_type_quantity':
                                                                            goodsSize,
                                                                        'pickup_poc_name':
                                                                            addressList[0].name,
                                                                        'pickup_poc_mobile':
                                                                            addressList[0].number,
                                                                        'pickup_poc_instruction':
                                                                            addressList[0].instructions,
                                                                      }),
                                                                      'api/v1/request/delivery/create');
                                                                }
                                                                setState(() {
                                                                  if (val ==
                                                                      'success') {
                                                                    _isLoading =
                                                                        false;
                                                                    _confirmRideLater =
                                                                        false;
                                                                    _rideLaterSuccess =
                                                                        true;
                                                                  } else if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  }
                                                                });
                                                              } else {
                                                                dynamic val;
                                                                setState(() {
                                                                  _isLoading =
                                                                      true;
                                                                });

                                                                if (choosenTransportType ==
                                                                    0) {
                                                                  val = await createRequestLater(
                                                                      jsonEncode({
                                                                        'pick_lat': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .latitude,
                                                                        'pick_lng': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .longitude,
                                                                        'vehicle_type':
                                                                            rentalOption[choosenVehicle]['zone_type_id'],
                                                                        'ride_type':
                                                                            1,
                                                                        'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                                'card')
                                                                            ? 0
                                                                            : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                ? 1
                                                                                : 2,
                                                                        'pick_address': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .address,
                                                                        'promocode_id':
                                                                            rentalOption[choosenVehicle]['promocode_id'],
                                                                        'trip_start_time': choosenDateTime
                                                                            .toString()
                                                                            .substring(0,
                                                                                19),
                                                                        'is_later':
                                                                            true,
                                                                        'request_eta_amount':
                                                                            rentalOption[choosenVehicle]['fare_amount'],
                                                                        'rental_pack_id':
                                                                            etaDetails[rentalChoosenOption]['id'],
                                                                      }),
                                                                      'api/v1/request/create');
                                                                } else {
                                                                  val = await createRequestLater(
                                                                      jsonEncode({
                                                                        'pick_lat': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .latitude,
                                                                        'pick_lng': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .longitude,
                                                                        'vehicle_type':
                                                                            rentalOption[choosenVehicle]['zone_type_id'],
                                                                        'ride_type':
                                                                            1,
                                                                        'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                                'card')
                                                                            ? 0
                                                                            : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                ? 1
                                                                                : 2,
                                                                        'pick_address': addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .address,
                                                                        'promocode_id':
                                                                            rentalOption[choosenVehicle]['promocode_id'],
                                                                        'trip_start_time': choosenDateTime
                                                                            .toString()
                                                                            .substring(0,
                                                                                19),
                                                                        'is_later':
                                                                            true,
                                                                        'request_eta_amount':
                                                                            rentalOption[choosenVehicle]['fare_amount'],
                                                                        'rental_pack_id':
                                                                            etaDetails[rentalChoosenOption]['id'],
                                                                        'goods_type_id':
                                                                            selectedGoodsId.toString(),
                                                                        'goods_type_quantity':
                                                                            goodsSize,
                                                                        'pickup_poc_name':
                                                                            addressList[0].name,
                                                                        'pickup_poc_mobile':
                                                                            addressList[0].number,
                                                                        'pickup_poc_instruction':
                                                                            addressList[0].instructions,
                                                                      }),
                                                                      'api/v1/request/delivery/create');
                                                                }
                                                                setState(() {
                                                                  if (val ==
                                                                      'success') {
                                                                    _isLoading =
                                                                        false;

                                                                    _confirmRideLater =
                                                                        false;
                                                                    _rideLaterSuccess =
                                                                        true;
                                                                  } else if (val ==
                                                                      'logout') {
                                                                    navigateLogout();
                                                                  }
                                                                });
                                                              }
                                                              setState(() {
                                                                _isLoading =
                                                                    false;
                                                              });
                                                            }
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_confirm'])
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(),

                                  //ride later success
                                  (_rideLaterSuccess == true)
                                      ? Positioned(
                                          child: Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          color: Colors.transparent
                                              .withOpacity(0.6),
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: media.width * 0.9,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      color: page),
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_rideLaterSuccess'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Button(
                                                          onTap: () {
                                                            addressList.removeWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop');
                                                            _rideLaterSuccess =
                                                                false;
                                                            myMarker.clear();
                                                            Navigator.pushAndRemoveUntil(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Maps()),
                                                                (route) =>
                                                                    false);
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_confirm'])
                                                    ],
                                                  ),
                                                )
                                              ]),
                                        ))
                                      : Container(),

                                  //sos popup
                                  (showSos == true)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: media.width * 0.7,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              notifyCompleted =
                                                                  false;
                                                              showSos = false;
                                                            });
                                                          },
                                                          child: Container(
                                                            height:
                                                                media.width *
                                                                    0.1,
                                                            width: media.width *
                                                                0.1,
                                                            decoration:
                                                                BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color:
                                                                        page),
                                                            child: Icon(
                                                              Icons
                                                                  .cancel_outlined,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.05),
                                                    height: media.height * 0.5,
                                                    width: media.width * 0.7,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        color: page),
                                                    child:
                                                        SingleChildScrollView(
                                                            physics:
                                                                const BouncingScrollPhysics(),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                InkWell(
                                                                  onTap:
                                                                      () async {
                                                                    setState(
                                                                        () {
                                                                      notifyCompleted =
                                                                          false;
                                                                    });
                                                                    var val =
                                                                        await notifyAdmin();
                                                                    if (val ==
                                                                        true) {
                                                                      setState(
                                                                          () {
                                                                        notifyCompleted =
                                                                            true;
                                                                      });
                                                                    }
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    padding: EdgeInsets.all(
                                                                        media.width *
                                                                            0.05),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              languages[choosenLanguage]['text_notifyadmin'],
                                                                              style: GoogleFonts.poppins(fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w600),
                                                                            ),
                                                                            (notifyCompleted == true)
                                                                                ? Container(
                                                                                    padding: EdgeInsets.only(top: media.width * 0.01),
                                                                                    child: Text(
                                                                                      languages[choosenLanguage]['text_notifysuccess'],
                                                                                      style: GoogleFonts.poppins(
                                                                                        fontSize: media.width * twelve,
                                                                                        color: const Color(0xff319900),
                                                                                      ),
                                                                                    ),
                                                                                  )
                                                                                : Container()
                                                                          ],
                                                                        ),
                                                                        Icon(
                                                                          Icons
                                                                              .notification_add,
                                                                          color:
                                                                              textColor,
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                (sosData.isNotEmpty)
                                                                    ? Column(
                                                                        children: sosData
                                                                            .asMap()
                                                                            .map((i, value) {
                                                                              return MapEntry(
                                                                                  i,
                                                                                  InkWell(
                                                                                    onTap: () {
                                                                                      makingPhoneCall(sosData[i]['number'].toString().replaceAll(' ', ''));
                                                                                    },
                                                                                    child: Container(
                                                                                      padding: EdgeInsets.all(media.width * 0.05),
                                                                                      child: Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                        children: [
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              SizedBox(
                                                                                                width: media.width * 0.4,
                                                                                                child: Text(
                                                                                                  sosData[i]['name'],
                                                                                                  style: GoogleFonts.poppins(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(
                                                                                                height: media.width * 0.01,
                                                                                              ),
                                                                                              Text(
                                                                                                sosData[i]['number'],
                                                                                                style: GoogleFonts.poppins(
                                                                                                  fontSize: media.width * twelve,
                                                                                                  color: textColor,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                          Icon(
                                                                                            Icons.call,
                                                                                            color: textColor,
                                                                                          )
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ));
                                                                            })
                                                                            .values
                                                                            .toList(),
                                                                      )
                                                                    : Container(
                                                                        width: media.width *
                                                                            0.7,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        child:
                                                                            Text(
                                                                          languages[choosenLanguage]
                                                                              [
                                                                              'text_noDataFound'],
                                                                          style: GoogleFonts.poppins(
                                                                              fontSize: media.width * eighteen,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: textColor),
                                                                        ),
                                                                      ),
                                                              ],
                                                            )),
                                                  )
                                                ]),
                                          ))
                                      : Container(),

                                  (_locationDenied == true)
                                      ? Positioned(
                                          child: Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          color: Colors.transparent
                                              .withOpacity(0.6),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: media.width * 0.9,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          _locationDenied =
                                                              false;
                                                        });
                                                      },
                                                      child: Container(
                                                        height:
                                                            media.height * 0.05,
                                                        width:
                                                            media.height * 0.05,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: page,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                            Icons.cancel,
                                                            color: buttonColor),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                  height: media.width * 0.025),
                                              Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                width: media.width * 0.9,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    color: page,
                                                    boxShadow: [
                                                      BoxShadow(
                                                          blurRadius: 2.0,
                                                          spreadRadius: 2.0,
                                                          color: Colors.black
                                                              .withOpacity(0.2))
                                                    ]),
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                        width:
                                                            media.width * 0.8,
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_open_loc_settings'],
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                        )),
                                                    SizedBox(
                                                        height:
                                                            media.width * 0.05),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        InkWell(
                                                            onTap: () async {
                                                              await perm
                                                                  .openAppSettings();
                                                            },
                                                            child: Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_open_settings'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      buttonColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            )),
                                                        InkWell(
                                                            onTap: () async {
                                                              setState(() {
                                                                _locationDenied =
                                                                    false;
                                                                _isLoading =
                                                                    true;
                                                              });

                                                              if (locationAllowed ==
                                                                  true) {
                                                                if (positionStream ==
                                                                        null ||
                                                                    positionStream!
                                                                        .isPaused) {
                                                                  positionStreamData();
                                                                }
                                                              }
                                                            },
                                                            child: Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  ['text_done'],
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      buttonColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ))
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ))
                                      : Container(),

                                  //displaying address details for edit
                                  ((_chooseGoodsType == false &&
                                              userRequestData.isEmpty &&
                                              addressList.isNotEmpty &&
                                              choosenTransportType == 1) ||
                                          (dropConfirmed == false &&
                                              userRequestData.isEmpty))
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  color: page,
                                                  border: Border.all(
                                                      color: backgroundColor)),
                                              width: media.width * 1,
                                              padding: EdgeInsets.all(
                                                  media.width * 0.03),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    width: media.width * 0.9,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                            languages[choosenLanguage]
                                                                [
                                                                'text_confirm_details'],
                                                            style: GoogleFonts.poppins(
                                                                fontSize: media
                                                                        .width *
                                                                    sixteen,
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                        (addressList.length <
                                                                    5 &&
                                                                widget.type !=
                                                                    1)
                                                            ? InkWell(
                                                                onTap:
                                                                    () async {
                                                                  var nav = await Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => DropLocation(
                                                                                from: 'add stop',
                                                                              )));
                                                                  if (nav) {
                                                                    setState(
                                                                        () {});
                                                                    Future.delayed(
                                                                        const Duration(
                                                                            milliseconds:
                                                                                100),
                                                                        () {
                                                                      addPickDropMarker();
                                                                    });
                                                                  }
                                                                },
                                                                child: Text(
                                                                    ' +' +
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_add_stop'],
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w600,
                                                                        color:
                                                                            buttonColor)),
                                                              )
                                                            : Container(),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.025,
                                                  ),
                                                  InkWell(
                                                    onTap: () async {
                                                      var nav =
                                                          await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          DropLocation(
                                                                            from:
                                                                                addressList[0].id,
                                                                          )));
                                                      if (nav) {
                                                        setState(() {});
                                                        Future.delayed(
                                                            const Duration(
                                                                milliseconds:
                                                                    100), () {
                                                          addPickDropMarker();
                                                        });
                                                      }
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                          bottom: media.width *
                                                              0.025),
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                              media.width *
                                                                  0.03,
                                                              media.width *
                                                                  0.02,
                                                              media.width *
                                                                  0.03,
                                                              media.width *
                                                                  0.02),
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: Colors.grey,
                                                            width: 1.5,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      media.width *
                                                                          0.02),
                                                          color: page),
                                                      alignment:
                                                          Alignment.center,
                                                      height: media.width * 0.1,
                                                      width: media.width * 0.9,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.width *
                                                                    0.05,
                                                            width: media.width *
                                                                0.05,
                                                            alignment: Alignment
                                                                .center,
                                                            child: Image.asset(
                                                                'assets/images/circle_icon.png'),
                                                            // decoration:
                                                            //     BoxDecoration(
                                                            //   shape: BoxShape
                                                            //       .circle,
                                                            //   color: const Color(
                                                            //           0xff319900)
                                                            //       .withOpacity(
                                                            //           0.3),
                                                            // ),
                                                            // child: Container(
                                                            //   height:
                                                            //       media.width *
                                                            //           0.01,
                                                            //   width:
                                                            //       media.width *
                                                            //           0.01,
                                                            //   decoration: const BoxDecoration(
                                                            //       shape: BoxShape
                                                            //           .circle,
                                                            //       color: Color(
                                                            //           0xff319900)),
                                                            // ),
                                                          ),
                                                          SizedBox(
                                                            width: media.width *
                                                                0.02,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              addressList[0]
                                                                  .address
                                                                  .toString(),
                                                              style: GoogleFonts.poppins(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: media.width *
                                                                0.02,
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.07,
                                                              child: Icon(
                                                                Icons.edit,
                                                                color:
                                                                    textColor,
                                                                size: media
                                                                        .width *
                                                                    0.05,
                                                              ))
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: (addressList
                                                                .length <=
                                                            4)
                                                        ? media.width *
                                                            0.125 *
                                                            (addressList
                                                                    .length -
                                                                1)
                                                        : media.width *
                                                            0.125 *
                                                            4,
                                                    child: ReorderableListView(
                                                        onReorder: (oldIndex,
                                                            newIndex) {
                                                          if (oldIndex != 0 &&
                                                              newIndex != 0 &&
                                                              newIndex <
                                                                  addressList
                                                                      .length) {
                                                            var val1 =
                                                                addressList[
                                                                    oldIndex]; //1
                                                            var id1 =
                                                                addressList[
                                                                        oldIndex]
                                                                    .id;
                                                            var val2 =
                                                                addressList[
                                                                    newIndex]; //2
                                                            var id2 =
                                                                addressList[
                                                                        newIndex]
                                                                    .id;

                                                            addressList[
                                                                    oldIndex] =
                                                                val2; //2
                                                            addressList[
                                                                    oldIndex]
                                                                .id = id1; //1
                                                            addressList[
                                                                    newIndex] =
                                                                val1; //1
                                                            addressList[
                                                                    newIndex]
                                                                .id = id2; //2
                                                          } else if (newIndex >
                                                              addressList
                                                                      .length -
                                                                  1) {
                                                            var newIndexEdit =
                                                                addressList
                                                                        .length -
                                                                    1;

                                                            var val1 =
                                                                addressList[
                                                                    oldIndex]; //1
                                                            var id1 =
                                                                addressList[
                                                                        oldIndex]
                                                                    .id;
                                                            var val2 = addressList[
                                                                newIndexEdit]; //2
                                                            var id2 = addressList[
                                                                    newIndexEdit]
                                                                .id;
                                                            addressList[
                                                                    oldIndex] =
                                                                val2; //2
                                                            addressList[
                                                                    oldIndex]
                                                                .id = id1; //1
                                                            addressList[
                                                                    newIndexEdit] =
                                                                val1; //1
                                                            addressList[
                                                                    newIndexEdit]
                                                                .id = id2; //2
                                                          }
                                                          setState(() {
                                                            addPickDropMarker();
                                                          });
                                                        },
                                                        children: addressList
                                                            .asMap()
                                                            .map((i, value) {
                                                              return MapEntry(
                                                                i,
                                                                (i != 0)
                                                                    ? Container(
                                                                        key: ValueKey(
                                                                            i),
                                                                        margin: EdgeInsets.only(
                                                                            bottom:
                                                                                media.width * 0.025),
                                                                        alignment:
                                                                            Alignment.center,
                                                                        height: media.width *
                                                                            0.1,
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          children: [
                                                                            InkWell(
                                                                              onTap: () async {
                                                                                var val = await Navigator.push(
                                                                                    context,
                                                                                    MaterialPageRoute(
                                                                                        builder: (context) => DropLocation(
                                                                                              from: addressList[i].id,
                                                                                            )));
                                                                                if (val) {
                                                                                  setState(() {});
                                                                                  Future.delayed(const Duration(milliseconds: 100), () {
                                                                                    addPickDropMarker();
                                                                                  });
                                                                                }
                                                                              },
                                                                              child: Container(
                                                                                padding: EdgeInsets.fromLTRB(media.width * 0.03, media.width * 0.02, media.width * 0.03, media.width * 0.02),
                                                                                decoration: BoxDecoration(
                                                                                    border: Border.all(
                                                                                      color: Colors.grey,
                                                                                      width: 1.5,
                                                                                    ),
                                                                                    borderRadius: BorderRadius.circular(media.width * 0.02),
                                                                                    color: page),
                                                                                alignment: Alignment.center,
                                                                                height: media.width * 0.1,
                                                                                width: (addressList.length > 2) ? media.width * 0.8 : media.width * 0.9,
                                                                                child: Row(
                                                                                  children: [
                                                                                    Container(
                                                                                      height: media.width * 0.05,
                                                                                      width: media.width * 0.05,
                                                                                      alignment: Alignment.center,
                                                                                      child: Image.asset('assets/images/drop_icon.png'),
                                                                                      //decoration: BoxDecoration(shape: BoxShape.circle, color: (i == 0) ? const Color(0xff319900).withOpacity(0.3) : const Color(0xffFF0000).withOpacity(0.3)),
                                                                                      // child: Container(
                                                                                      //   height: media.width * 0.01,
                                                                                      //   width: media.width * 0.01,
                                                                                      //   decoration: BoxDecoration(shape: BoxShape.circle, color: (i == 0) ? const Color(0xff319900) : const Color(0xffFF0000)),
                                                                                      // ),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.02,
                                                                                    ),
                                                                                    Expanded(
                                                                                      child: Text(
                                                                                        addressList[i].address.toString(),
                                                                                        style: GoogleFonts.poppins(
                                                                                          fontSize: media.width * twelve,
                                                                                          color: textColor,
                                                                                        ),
                                                                                        maxLines: 1,
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.02,
                                                                                    ),
                                                                                    SizedBox(
                                                                                        height: media.width * 0.07,
                                                                                        child: (addressList.length > 2)
                                                                                            ? Icon(
                                                                                                Icons.move_down_rounded,
                                                                                                size: media.width * 0.05,
                                                                                                color: textColor,
                                                                                              )
                                                                                            : Icon(
                                                                                                Icons.edit,
                                                                                                color: textColor,
                                                                                                size: media.width * 0.05,
                                                                                              ))
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            (addressList.length > 2)
                                                                                ? InkWell(
                                                                                    onTap: () {
                                                                                      setState(() {
                                                                                        addressList.removeAt(i);
                                                                                        myMarker.removeWhere((element) => element.markerId.toString().contains('car') != true);
                                                                                        addPickDropMarker();
                                                                                      });
                                                                                    },
                                                                                    child: Icon(
                                                                                      Icons.delete,
                                                                                      size: media.width * 0.07,
                                                                                      color: textColor,
                                                                                    ))
                                                                                : Container()
                                                                          ],
                                                                        ),
                                                                      )
                                                                    : Container(
                                                                        key: ValueKey(
                                                                            addressList[i].id),
                                                                      ),
                                                              );
                                                            })
                                                            .values
                                                            .toList()),
                                                  ),
                                                  Button(
                                                      onTap: () async {
                                                        setState(() {
                                                          _isLoading = true;
                                                          dropStopList.clear();
                                                          if (addressList
                                                                  .length >
                                                              2) {
                                                            for (var i = 1;
                                                                i <
                                                                    addressList
                                                                        .length;
                                                                i++) {
                                                              dropStopList.add(DropStops(
                                                                  order: i
                                                                      .toString(),
                                                                  latitude:
                                                                      addressList[i]
                                                                          .latlng
                                                                          .latitude,
                                                                  longitude:
                                                                      addressList[i]
                                                                          .latlng
                                                                          .longitude,
                                                                  pocName:
                                                                      addressList[i]
                                                                          .name
                                                                          .toString(),
                                                                  pocNumber:
                                                                      addressList[i]
                                                                          .number
                                                                          .toString(),
                                                                  pocInstruction: (addressList[i]
                                                                              .instructions !=
                                                                          null)
                                                                      ? addressList[
                                                                              i]
                                                                          .instructions
                                                                      : null,
                                                                  address: addressList[
                                                                          i]
                                                                      .address
                                                                      .toString()));
                                                            }
                                                          }
                                                        });

                                                        if (widget.type != 1) {
                                                          var val =
                                                              await etaRequest();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          }
                                                        } else {
                                                          var val =
                                                              await rentalEta();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          }
                                                        }
                                                        if (choosenTransportType ==
                                                            0) {
                                                          setState(() {
                                                            dropConfirmed =
                                                                true;
                                                            _isLoading = false;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            dropConfirmed =
                                                                true;
                                                            selectedGoodsId =
                                                                '';
                                                            _chooseGoodsType =
                                                                true;
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_confirm'])
                                                ],
                                              )),
                                        )
                                      : Container(),

                                  //edit pick user contact

                                  (_editUserDetails == true)
                                      ? Positioned(
                                          child: Scaffold(
                                          backgroundColor: Colors.transparent,
                                          body: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                SizedBox(
                                                  width: media.width * 0.9,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _editUserDetails =
                                                                false;
                                                          });
                                                        },
                                                        child: Container(
                                                          height:
                                                              media.width * 0.1,
                                                          width:
                                                              media.width * 0.1,
                                                          decoration:
                                                              BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: page),
                                                          child: Icon(
                                                              Icons
                                                                  .cancel_outlined,
                                                              color: textColor),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: media.width * 0.05),
                                                Container(
                                                  color: page,
                                                  width: media.width * 1,
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.9,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Give User Data',
                                                              style: GoogleFonts.poppins(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            InkWell(
                                                                onTap:
                                                                    () async {
                                                                  var nav = await Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              const PickContact(from: '1')));
                                                                  if (nav) {
                                                                    setState(
                                                                        () {
                                                                      pickerName
                                                                              .text =
                                                                          pickedName;
                                                                      pickerNumber
                                                                              .text =
                                                                          pickedNumber;
                                                                    });
                                                                  }
                                                                },
                                                                child: Icon(
                                                                    Icons
                                                                        .contact_page_rounded,
                                                                    color:
                                                                        textColor))
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.025,
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.fromLTRB(
                                                            media.width * 0.03,
                                                            (languageDirection ==
                                                                    'rtl')
                                                                ? media.width *
                                                                    0.04
                                                                : 0,
                                                            media.width * 0.03,
                                                            media.width * 0.01),
                                                        height:
                                                            media.width * 0.1,
                                                        width:
                                                            media.width * 0.9,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 1.5,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        media.width *
                                                                            0.02),
                                                                color: page),
                                                        child: TextField(
                                                          controller:
                                                              pickerName,
                                                          decoration:
                                                              InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            hintText: languages[
                                                                    choosenLanguage]
                                                                ['text_name'],
                                                            hintStyle:
                                                                GoogleFonts
                                                                    .poppins(
                                                              fontSize:
                                                                  media.width *
                                                                      twelve,
                                                              color: textColor
                                                                  .withOpacity(
                                                                      0.4),
                                                            ),
                                                          ),
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.025,
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.fromLTRB(
                                                            media.width * 0.03,
                                                            (languageDirection ==
                                                                    'rtl')
                                                                ? media.width *
                                                                    0.04
                                                                : 0,
                                                            media.width * 0.03,
                                                            media.width * 0.01),
                                                        height:
                                                            media.width * 0.1,
                                                        width:
                                                            media.width * 0.9,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 1.5,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        media.width *
                                                                            0.02),
                                                                color: page),
                                                        child: TextField(
                                                          controller:
                                                              pickerNumber,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          decoration:
                                                              InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            counterText: '',
                                                            hintText: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_givenumber'],
                                                            hintStyle: GoogleFonts.poppins(
                                                                color: textColor
                                                                    .withOpacity(
                                                                        0.4),
                                                                fontSize: media
                                                                        .width *
                                                                    twelve),
                                                          ),
                                                          maxLength: 20,
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.025,
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.fromLTRB(
                                                            media.width * 0.03,
                                                            (languageDirection ==
                                                                    'rtl')
                                                                ? media.width *
                                                                    0.04
                                                                : 0,
                                                            media.width * 0.03,
                                                            media.width * 0.01),
                                                        // height: media.width * 0.1,
                                                        width:
                                                            media.width * 0.9,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 1.5,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        media.width *
                                                                            0.02),
                                                                color: page),
                                                        child: TextField(
                                                          controller:
                                                              instructions,
                                                          decoration:
                                                              InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            counterText: '',
                                                            hintText: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_instructions'],
                                                            hintStyle: GoogleFonts.poppins(
                                                                color: textColor
                                                                    .withOpacity(
                                                                        0.4),
                                                                fontSize: media
                                                                        .width *
                                                                    twelve),
                                                          ),
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve),
                                                          maxLines: 4,
                                                          minLines: 2,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.03,
                                                      ),
                                                      Button(
                                                          onTap: () async {
                                                            setState(() {
                                                              addressList[0]
                                                                      .name =
                                                                  pickerName
                                                                      .text;
                                                              addressList[0]
                                                                      .number =
                                                                  pickerNumber
                                                                      .text;
                                                              addressList[0]
                                                                      .instructions =
                                                                  (instructions
                                                                          .text
                                                                          .isNotEmpty)
                                                                      ? instructions
                                                                          .text
                                                                      : null;
                                                              _editUserDetails =
                                                                  false;
                                                            });
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_confirm'])
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ))
                                      : Container(),

                                  if (_cancel == true)
                                    Positioned(
                                        child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.2),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                    height: media.height * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: page),
                                                    child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _cancel = false;
                                                          });
                                                        },
                                                        child: const Icon(Icons
                                                            .cancel_outlined))),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: backgroundColor),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: page),
                                            child: Column(
                                              children: [
                                                Text(
                                                  languages[choosenLanguage][
                                                      'text_cancel_confirmation'],
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        _isLoading = true;
                                                      });
                                                      var val =
                                                          await cancelRequest();
                                                      updateAmount.clear();

                                                      if (val == 'logout') {
                                                        navigateLogout();
                                                        setState(() {
                                                          yourAmount.clear();
                                                        });
                                                      }
                                                      setState(() {
                                                        _isLoading = false;
                                                        _cancel = false;
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'])
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    )),

                                  //loader
                                  (_isLoading == true)
                                      ? const Positioned(
                                          top: 0, child: Loading())
                                      : Container(),

                                  //no internet
                                  (internet == false)
                                      ? Positioned(
                                          top: 0,
                                          child: NoInternet(
                                            onTap: () {
                                              setState(() {
                                                internetTrue();
                                              });
                                            },
                                          ))
                                      : Container(),

                                  //pick drop marker
                                  Positioned(
                                    top: media.height * 1.6,
                                    child: RepaintBoundary(
                                        key: iconKey,
                                        child: Column(
                                          children: [
                                            Container(
                                                decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        colors: [
                                                          (isDarkTheme == true)
                                                              ? const Color(
                                                                  0xff000000)
                                                              : const Color(
                                                                  0xffFFFFFF),
                                                          (isDarkTheme == true)
                                                              ? const Color(
                                                                  0xff808080)
                                                              : const Color(
                                                                  0xffEFEFEF),
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                // width: (platform ==
                                                //         TargetPlatform.android)
                                                //     ? media.width * 0.7
                                                //     : media.width * 0.9,
                                                padding:
                                                    const EdgeInsets.all(5),
                                                child: (userRequestData
                                                        .isNotEmpty)
                                                    ? Text(
                                                        userRequestData[
                                                            'pick_address'],
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.fade,
                                                        softWrap: false,
                                                        style: GoogleFonts.poppins(
                                                            color: textColor,
                                                            fontSize: (platform ==
                                                                    TargetPlatform
                                                                        .android)
                                                                ? media.width *
                                                                    twelve
                                                                : media.width *
                                                                    sixteen),
                                                      )
                                                    : (addressList
                                                            .where((element) =>
                                                                element.type ==
                                                                'pickup')
                                                            .isNotEmpty)
                                                        ? Text(
                                                            addressList
                                                                .firstWhere(
                                                                    (element) =>
                                                                        element
                                                                            .type ==
                                                                        'pickup')
                                                                .address,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .fade,
                                                            softWrap: false,
                                                            style: GoogleFonts.poppins(
                                                                color:
                                                                    textColor,
                                                                fontSize: (platform ==
                                                                        TargetPlatform
                                                                            .android)
                                                                    ? media.width *
                                                                        twelve
                                                                    : media.width *
                                                                        sixteen),
                                                          )
                                                        : Container()),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/pick_icon.png'),
                                                      fit: BoxFit.contain)),
                                              height: (platform ==
                                                      TargetPlatform.android)
                                                  ? media.width * 0.07
                                                  : media.width * 0.12,
                                              width: (platform ==
                                                      TargetPlatform.android)
                                                  ? media.width * 0.07
                                                  : media.width * 0.12,
                                            ),
                                          ],
                                        )),
                                  ),
                                  (widget.type != 1)
                                      ? Positioned(
                                          top: media.height * 2,
                                          child: Column(
                                            children: addressList
                                                .asMap()
                                                .map((i, value) {
                                                  iconDropKeys[i] = GlobalKey();
                                                  return MapEntry(
                                                    i,
                                                    (i > 0)
                                                        ? RepaintBoundary(
                                                            key:
                                                                iconDropKeys[i],
                                                            child: Column(
                                                              children: [
                                                                (i ==
                                                                        addressList.length -
                                                                            1)
                                                                    ? Column(
                                                                        children: [
                                                                          Container(
                                                                            decoration: BoxDecoration(
                                                                                gradient: LinearGradient(colors: [
                                                                                  (isDarkTheme == true) ? const Color(0xff000000) : const Color(0xffFFFFFF),
                                                                                  (isDarkTheme == true) ? const Color(0xff808080) : const Color(0xffEFEFEF),
                                                                                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                                                                borderRadius: BorderRadius.circular(5)),
                                                                            // width: (platform == TargetPlatform.android)
                                                                            //     ? media.width * 0.7
                                                                            //     : media.width * 0.9,
                                                                            padding:
                                                                                const EdgeInsets.all(5),
                                                                            child: (addressList[i].address.isNotEmpty)
                                                                                ? Text(
                                                                                    addressList[i].address,
                                                                                    maxLines: 1,
                                                                                    overflow: TextOverflow.fade,
                                                                                    softWrap: false,
                                                                                    style: GoogleFonts.poppins(fontSize: (platform == TargetPlatform.android) ? media.width * twelve : media.width * sixteen, color: textColor),
                                                                                  )
                                                                                : Container(),
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                10,
                                                                          ),
                                                                          Container(
                                                                            decoration:
                                                                                const BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: AssetImage('assets/images/drop_icon.png'), fit: BoxFit.contain)),
                                                                            height: (platform == TargetPlatform.android)
                                                                                ? media.width * 0.07
                                                                                : media.width * 0.12,
                                                                            width: (platform == TargetPlatform.android)
                                                                                ? media.width * 0.07
                                                                                : media.width * 0.12,
                                                                          ),
                                                                        ],
                                                                      )
                                                                    : Text(
                                                                        (i).toString(),
                                                                        style: GoogleFonts.poppins(
                                                                            fontSize: media.width *
                                                                                sixteen,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color: Colors.red),
                                                                      ),
                                                              ],
                                                            ))
                                                        : Container(),
                                                  );
                                                })
                                                .values
                                                .toList(),
                                          ))
                                      : Container(),

                                  (widget.type != 1)
                                      ? Positioned(
                                          top: media.height * 2,
                                          child: RepaintBoundary(
                                              key: iconDistanceKey,
                                              child: Stack(
                                                children: [
                                                  Icon(Icons.chat_bubble,
                                                      size: media.width * 0.2,
                                                      color: page,
                                                      shadows: [
                                                        BoxShadow(
                                                            spreadRadius: 2,
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2))
                                                      ]),
                                                  if (etaDetails.isNotEmpty)
                                                    if (etaDetails[0]
                                                            ['distance'] !=
                                                        null)
                                                      Positioned(
                                                          left: media.width *
                                                              0.03,
                                                          top: media.width *
                                                              0.03,
                                                          child: Container(
                                                              width:
                                                                  media.width *
                                                                      0.14,
                                                              height:
                                                                  media.width *
                                                                      0.1,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                "${etaDetails[0]['distance'].toString()} ${etaDetails[0]['unit_in_words'].toString()} ",
                                                                style: GoogleFonts.poppins(
                                                                    fontSize: media
                                                                            .width *
                                                                        twelve,
                                                                    color:
                                                                        textColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              )))
                                                ],
                                              )),
                                        )
                                      : Container()
                                ],
                              );
                            });
                      });
                }),
          ),
        ),
      ),
    );
  }

  double getBearing(LatLng begin, LatLng end) {
    double lat = (begin.latitude - end.latitude).abs();

    double lng = (begin.longitude - end.longitude).abs();

    if (begin.latitude < end.latitude && begin.longitude < end.longitude) {
      return vector.degrees(atan(lng / lat));
    } else if (begin.latitude >= end.latitude &&
        begin.longitude < end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 90;
    } else if (begin.latitude >= end.latitude &&
        begin.longitude >= end.longitude) {
      return vector.degrees(atan(lng / lat)) + 180;
    } else if (begin.latitude < end.latitude &&
        begin.longitude >= end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 270;
    }

    return -1;
  }

  Future<void> animateCar(
      double fromLat, //Starting latitude

      double fromLong, //Starting longitude

      double toLat, //Ending latitude

      double toLong, //Ending longitude

      StreamSink<List<Marker>>
          mapMarkerSink, //Stream build of map to update the UI

      TickerProvider
          provider, //Ticker provider of the widget. This is used for animation

      GoogleMapController controller, //Google map controller of our widget

      markerid,
      markerBearing,
      icon) async {
    final double bearing =
        getBearing(LatLng(fromLat, fromLong), LatLng(toLat, toLong));

    myBearings[markerBearing.toString()] = bearing;

    var carMarker = Marker(
        markerId: MarkerId(markerid),
        position: LatLng(fromLat, fromLong),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        draggable: false);

    myMarker.add(carMarker);

    mapMarkerSink.add(Set<Marker>.from(myMarker).toList());

    Tween<double> tween = Tween(begin: 0, end: 1);

    _animation = tween.animate(animationController)
      ..addListener(() async {
        myMarker
            .removeWhere((element) => element.markerId == MarkerId(markerid));

        final v = _animation!.value;

        double lng = v * toLong + (1 - v) * fromLong;

        double lat = v * toLat + (1 - v) * fromLat;

        LatLng newPos = LatLng(lat, lng);

        //New marker location

        carMarker = Marker(
            markerId: MarkerId(markerid),
            position: newPos,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: bearing,
            draggable: false);

        //Adding new marker to our list and updating the google map UI.

        myMarker.add(carMarker);

        mapMarkerSink.add(Set<Marker>.from(myMarker).toList());
      });

    //Starting the animation

    animationController.forward();
  }
}
