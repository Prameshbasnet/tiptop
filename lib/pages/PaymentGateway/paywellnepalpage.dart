import 'package:flutter/material.dart';
import 'package:tiptop/functions/functions.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore: must_be_immutable
class PayWellNepalPage
    extends
        StatefulWidget {
  dynamic from;
  PayWellNepalPage({
    super.key,
    this.from,
  });

  @override
  State<
    PayWellNepalPage
  >
  createState() => _PayWellNepalPage();
}

class _PayWellNepalPage
    extends
        State<
          PayWellNepalPage
        > {
  bool pop = true;
  late final WebViewController _controller;

  @override
  void initState() {
    // #docregion platform_features
    dynamic paymentUrl;
    if (widget.from ==
        '1') {
      paymentUrl = '${url}paywellnepal-checkout?amount=$addMoney&user_id=${userDetails['id']}&request_for=${userRequestData['id']}';
    } else {
      paymentUrl = '${url}paywellnepal-checkout?amount=$addMoney&user_id=${userDetails['id']}&request_for=add-money-to-wallet';
    }
    late final PlatformWebViewControllerCreationParams params;

    params = const PlatformWebViewControllerCreationParams();

    final WebViewController controller = WebViewController.fromPlatformCreationParams(
      params,
    );
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setBackgroundColor(
        const Color(
          0x00000000,
        ),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError:
              (
                WebResourceError error,
              ) {
                debugPrint(
                  '''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''',
                );
              },
          onNavigationRequest:
              (
                NavigationRequest request,
              ) {
                if (request.url.startsWith(
                  '${url}paywellnepal-success',
                )) {
                  setState(
                    () {
                      pop = true;
                    },
                  );
                } else if (request.url.startsWith(
                  '${url}paywellnepal-failure',
                )) {
                  setState(
                    () {
                      pop = true;
                    },
                  );
                }
                return NavigationDecision.navigate;
              },
        ),
      )
      ..loadRequest(
        Uri.parse(
          paymentUrl,
        ),
      );

    _controller = controller;
    super.initState();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    var media = MediaQuery.of(
      context,
    ).size;
    return PopScope(
      canPop: false,
      child: Material(
        child: Container(
          height: media.height,
          width: media.width,
          padding: EdgeInsets.only(
            top: MediaQuery.of(
              context,
            ).padding.top,
          ),
          // child: Container(),
          child: Column(
            children: [
              if (pop ==
                  true)
                Container(
                  width: media.width,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.all(
                    media.width *
                        0.05,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(
                        context,
                        true,
                      );
                    },
                    child: const Icon(
                      Icons.arrow_back,
                    ),
                  ),
                ),
              Expanded(
                child: WebViewWidget(
                  controller: _controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
