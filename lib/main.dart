import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  timeago.setLocaleMessages('uk', timeago.UkMessages());
  await initializeDateFormatting('uk_UA', null);
  await Firebase.initializeApp();

  // ❌ Цей рядок можеш прибрати або оновити, якщо потрібна кастомна поведінка
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(const MyApp());
}
