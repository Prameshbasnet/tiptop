import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import 'firebase_options.dart';
import 'functions/functions.dart';
import 'functions/notifications.dart';
import 'pages/loadingPage/loadingpage.dart';

Future<
  void
>
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (
    e
  ) {
    // Firebase init failed, continue for UI only
    debugPrint(
      'Firebase init failed: $e',
    );
  }
  try {
    checkInternetConnection();
    if (firebaseReady) {
      await initMessaging();
    }
  } catch (
    e
  ) {
    debugPrint(
      'InitMessaging or checkInternetConnection failed: $e',
    );
  }
  runApp(
    const MyApp(),
  );
}

class MyApp
    extends
        StatelessWidget {
  const MyApp({
    super.key,
  });

  // This widget is the root of your application.
  @override
  Widget build(
    BuildContext context,
  ) {
    platform = Theme.of(
      context,
    ).platform;
    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(
          context,
        );
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild !=
                null) {
          currentFocus.unfocus();
        }
      },
      child: ValueListenableBuilder(
        valueListenable: valueNotifierBook.value,
        builder:
            (
              context,
              value,
              child,
            ) {
              return ToastificationWrapper(
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: productName,
                  theme: ThemeData(),
                  home: const LoadingPage(),
                ),
              );
            },
      ),
    );
  }
}
