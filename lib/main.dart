import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:zero_hunger/screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final defaultConfig = await FirebaseFirestore.instance
      .collection('configs')
      .doc('default')
      .get();
  final directionsApiKey = defaultConfig.data()?['DirectionsApiKey'] ?? "";

  DirectionsService.init(directionsApiKey);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Color(0xFFB8CC6A),
        accentColor: Color(0xFF3C693D),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            shape: StadiumBorder(),
            minimumSize: Size(170, 50),
          )
        ),
        textTheme: TextTheme(

          bodyText1: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          bodyText2: TextStyle(
            fontSize: 16,

          ),
         /* headline4: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Color(0xfff4a045),
          ),*/
        ),
      ),
      home: HomePage(),
    );
  }
}
