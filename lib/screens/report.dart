import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:geolocator/geolocator.dart';

class ReportPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _currentValue = 2;
  DateTime selectedDate = DateTime.now();
  late StreamSubscription<Position> _positionSubscription;
  Position? _currentPosition;
  bool _water = false;


  @override
  void initState() {
    _positionSubscription =
        Geolocator.getPositionStream().listen(_onPositionUpdate);
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) =>
      Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      );

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text("Help Request"),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 30, 15, 20),
      child: Container(
        child: Column(children: [
          Text(
            'Your position',
            style: Theme
                .of(context).textTheme.bodyText1,
          ),
          SizedBox(height: 16,),
          Text('$_currentPosition'),

          SizedBox(height: 24,),

          Text(
            'Last registered meal:',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          SizedBox(height: 16,),
          Text(
            '$selectedDate'
          ),

          SizedBox(height: 16,),

          ElevatedButton(
            onPressed: () => _pickDate(context),
            child: Text("PICK DATE"),
          ),

          SizedBox(height: 24,),

          CheckboxListTile(
            title: Text('Water Demand', style: Theme.of(context).textTheme.bodyText1,),
            activeColor: Colors.green,
            value: _water,
            onChanged: (bool? value) {
              setState(() {
                _water = value == true;
              });
            },
          ),

          SizedBox(height: 16,),

          Text(
            'People in need: $_currentValue',
          ),

          SizedBox(height: 16,),

          NumberPicker(
            minValue: 1,
            maxValue: 20,
            step: 1,
            axis: Axis.horizontal,
            itemHeight: 60,
            value: _currentValue,
            onChanged: (value) => setState(() => _currentValue = value),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green),
            ),
          ),

          SizedBox(height: 32,),

          ElevatedButton(
            child: Text("SEND REQUEST"),
            onPressed: _sendRequest,
          ),
        ]),
      ),
    );
  }

  void _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2021, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  void _sendRequest() async {
    //TODO: se l'utente non è autenticato, fare il login anonimo
    if (FirebaseAuth.instance.currentUser == null)
      final user = await FirebaseAuth.instance.signInAnonymously();

    if (_currentPosition != null) {
      final data = {
        "coordinates": GeoPoint(
            _currentPosition!.latitude, _currentPosition!.longitude),
        "date": selectedDate,
        "people": _currentValue,
        "water": _water,
        "taken": null,
      };
    }
    else {
      print('Impossibile trovare la posizione!');
    }

    //  await FirebaseFirestore.instance.collection('reports').doc(user.user.uid).set(data);

    Navigator.of(context).pop();
  }

  void _onPositionUpdate(Position position) {
    setState(() {
      _currentPosition = position;
    });
  }
}

