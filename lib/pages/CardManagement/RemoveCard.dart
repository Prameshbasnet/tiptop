import 'package:flutter/material.dart';

import '../../functions/functions.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import 'CustomCreditCardWidget.dart';

class RemoveCard extends StatefulWidget {
  final Map<String, dynamic> cardDetail;

  const RemoveCard({super.key, required this.cardDetail});

  @override
  State<RemoveCard> createState() => _RemoveCardState(cardDetail: cardDetail);
}

class _RemoveCardState extends State<RemoveCard> {
  Map<String, dynamic> cardDetail;
  bool _isLoading = false;

  _RemoveCardState({required this.cardDetail});

  void navigateLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'Card details',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                  child: CustomCreditCardWidget(
                    cardNumber: '**** **** **** ${cardDetail['card']['last4']}',
                    expiryDate:
                        '${cardDetail['card']['exp_month']} / ${cardDetail['card']['exp_year']}',
                    cardHolderName: cardDetail['billing_details']['name'] ?? '',
                    brand: cardDetail['card']['brand'],
                  ),
                ),

                //no internet
                (internet == false)
                    ? NoInternet(
                        onTap: () {
                          setState(() {
                            internetTrue();
                            _isLoading = true;
                          });
                        },
                      )
                    : Container(),

                // Button
                // Button with Padding
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        var val = await removeStripeCard(cardDetail['id']);
                        if (val == 'success') {
                          setState(() {
                            _isLoading = false;
                            Navigator.pop(context, true);
                          });
                        } else if (val == 'logout') {
                          navigateLogout();
                        }else{

                          setState(() {
                            _isLoading = false;
                          });

                        }
                      },
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: Text(
                            'Remove this card from wallet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),

          // Loader Overlay
          if (_isLoading) const Loading(),
        ],
      ),
    );
  }
}
