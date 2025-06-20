import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <– Додано
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/splash_wrapper.dart';

// import 'app.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    // statusBarColor: Colors.white, // Під splash
    // statusBarIconBrightness: Brightness.dark,
  ));

  timeago.setLocaleMessages('uk', timeago.UkMessages());
  await initializeDateFormatting('uk_UA', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // 🔐 AppCheck: Web через reCAPTCHA, Android — debug
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    webProvider: kIsWeb
        ? ReCaptchaV3Provider('6LeEa14rAAAAABwOEw0sDWHR3k-XTzOGkbJBFQjP')
        : null,
  );

  runApp(const SplashWrapper());
}
