import 'dart:async';

import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

class ReportPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _currentValue = 2;
  DateTime selectedDate = DateTime.now();
  late StreamSubscription<Position> _positionSubscription;
  Position? _currentPosition;


  @override
  void initState(){
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
      padding: const EdgeInsets.all(16.0),
      child: Container(
        child: Column(children: [
          Text('Your position: $_currentPosition'),

          SizedBox(height: 16,),

          Text('When was your last meal?'),

          SizedBox(height: 8,),

          ElevatedButton(
            onPressed: () {
              _pickDate;
            },
            child: Text("Pick Date"),
          ),

          SizedBox(height: 16,),

          CheckboxListTile(
            title: Text('Need Water?'),
            activeColor: Colors.deepOrangeAccent,
            value: timeDilation != 1.0,
            onChanged: (bool? value) {
              setState(() {
                timeDilation = value! ? 2.0 : 1.0;
              });
            },
          ),

          SizedBox(height: 16,),

          Text(
            'Select the number of people needing food: $_currentValue',
          ),

          SizedBox(height: 8,),

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
              border: Border.all(color: Colors.deepOrangeAccent),
            ),
          ),

          SizedBox(height: 16,),

          TextButton(
            child: Text("Send Request"),
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
      lastDate: DateTime(2031, 1, 1),
    );
    if(picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  void _sendRequest() {
    final navigator = Navigator.of(context);
    navigator.pop();
  }


  void _onPositionUpdate(Position position) {
    setState(() {
      _currentPosition = position;
    });
  }
}

