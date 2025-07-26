import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'dart:async';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:toastification/toastification.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';

class FortuneWheelPage extends StatefulWidget {
  const FortuneWheelPage({super.key});

  @override
  _FortuneWheelPageState createState() => _FortuneWheelPageState();
}

class _FortuneWheelPageState extends State<FortuneWheelPage> {
  final StreamController<int> _controller = StreamController<int>.broadcast();
  int _selectedIndex = 0;
  bool _isLoading = true;
  double randomInRange(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  int total = 60;
  int progress = 0;
  Timer? _confettiTimer; // Declare the timer variable


  @override
  void initState() {
    super.initState();
    getWheelItems(); // Fetch items when the page initializes
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  getWheelItems() async {
    var val=await GetFortuneWheelItems();
    if (val == 'success') {
      _isLoading = false;
      valueNotifierBook.incrementNotifier();
    }
  }


  Future<void> spinWheel() async {
    setState(() {
      _isLoading = true;
    });
    var val=await getFortuneWheelSpinResult();
    if (val == 'success') {
      _isLoading = false;
      setState(() {
        // Loop through the items and find the index of the selected item based on the id
        for (var i = 0; i < FortuneWheelItems.length; i++) {
          if (FortuneWheelItems[i]['id'] == FortuneWheelSpinResult['id']) {
            _selectedIndex = i;
            break;
          }
        }
        _controller.add(_selectedIndex);
      });
      // _controller.add(_selectedIndex);
      valueNotifierBook.incrementNotifier();
    }else{
      setState(() {
        _isLoading = false;
      });
      showErrorDialog(FortuneWheelSpinErrorMessage);
    }
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
                                  ['text_enable_wallet'],
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
                          Column(
                            //center of the page
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 300,
                                child:FortuneWheelItems.isNotEmpty?
                                FortuneWheel(
                                  selected: _controller.stream,
                                  physics:NoPanPhysics(),
                                  animateFirst: false,
                                  indicators: const <FortuneIndicator>[
                                    FortuneIndicator(
                                      alignment: Alignment.topCenter, // <-- changing the position of the indicator
                                      child: TriangleIndicator(
                                        color: Colors.green, // <-- changing the color of the indicator
                                        width: 20.0, // <-- changing the width of the indicator
                                        height: 20.0, // <-- changing the height of the indicator
                                        elevation: 0, // <-- changing the elevation of the indicator
                                      ),
                                    ),
                                  ],
                                  items: [
                                    for (var item in FortuneWheelItems)
                                      FortuneItem(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (item['image'] != null)
                                              Image.asset(
                                                item['image'],
                                                height: 40,
                                                width: 40,
                                              ),
                                            const SizedBox(height: 8),
                                            if (item['image'] == null)
                                              Text(item['display_name']),
                                          ],
                                        ),
                                      ),
                                  ],
                                  onAnimationEnd: () {
                                    if(FortuneWheelItems[_selectedIndex]['points']==0){
                                      showErrorDialog('Better Luck Next Time');
                                      return;
                                    }else {
                                      _confettiTimer = Timer.periodic(
                                          const Duration(milliseconds: 250), (
                                          timer) {
                                        progress++;

                                        if (progress >= total) {
                                          timer.cancel();
                                          return;
                                        }

                                        int count = ((1 - progress / total) *
                                            50).toInt();

                                        Confetti.launch(
                                          context,
                                          options: ConfettiOptions(
                                              particleCount: count,
                                              startVelocity: 30,
                                              spread: 360,
                                              ticks: 60,
                                              x: randomInRange(0.1, 0.3),
                                              y: Random().nextDouble() - 0.2),
                                        );
                                        Confetti.launch(
                                          context,
                                          options: ConfettiOptions(
                                              particleCount: count,
                                              startVelocity: 30,
                                              spread: 360,
                                              ticks: 60,
                                              x: randomInRange(0.7, 0.9),
                                              y: Random().nextDouble() - 0.2),
                                        );
                                      });


                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            content: Text(
                                                'You won ${FortuneWheelItems[_selectedIndex]['display_name']}!'),
                                            actions: [
                                              TextButton(
                                                onPressed: (){
                                                  _confettiTimer?.cancel(); // Cancel timer on dialog close
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                ):Container(),
                              ),
                              const SizedBox(height: 50),
                              Button(
                                  onTap: spinWheel,
                                  text: 'Spin the Wheel'),

                            ],
                          )
                        ],
                      ),
                    ),
                    //loader

                    (_isLoading == true)
                        ? const Positioned(child: Loading())
                        : Container(),
                    (internet == false)
                        ? Positioned(
                        top: 0,
                        child: NoInternet(
                          onTap: () {
                            setState(() {
                              internetTrue();
                              _isLoading = true;
                              getWheelItems();
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
