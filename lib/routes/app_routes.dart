import 'package:flutter/material.dart';
import 'package:crm_app/screens/home_screen.dart';
// import 'package:crm_app/screens/login_screen.dart';
import 'package:crm_app/screens/clients_list_screen.dart';
import 'package:crm_app/screens/calendar_screen.dart';
import 'package:crm_app/screens/add_client_screen.dart';
import 'package:crm_app/screens/today_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String home = '/home';
  static const String clients = '/clients';
  static const String calendar = '/calendar';
  static const String addClient = '/add-client';
  static const String todayScreen = '/today-screen';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    clients: (context) => const ClientsListScreen(),
    calendar: (context) => const CalendarScreen(),
    addClient: (context) => const AddClientScreen(),
    todayScreen: (context) => const TodayScreen(),
  };
}
