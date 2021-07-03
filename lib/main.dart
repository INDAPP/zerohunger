import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:zero_hunger/screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  DirectionsService.init("AIzaSyA3hn_UnY7nWc0nE5kY3Te_XRgi6YQ5e1w");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
