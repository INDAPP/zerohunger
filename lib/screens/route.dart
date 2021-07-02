import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:zero_hunger/models/report.dart';

class RoutePage extends StatefulWidget {
  final User user;

  const RoutePage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  late Stream _routeStream;
  late StreamSubscription<List<Report>> _reportsSubscription;
  late StreamSubscription<Position> _positionSubscription;
  int _placeCount = 10;
  List<Report>? _reports;
  Position? _currentPosition;

  int get _foodUnits =>
      _reports
          ?.take(_placeCount)
          .fold(0, (previousValue, report) => previousValue! + report.people) ??
      0;

  int get _waterUnits =>
      _reports?.take(_placeCount).fold(
          0,
          (previousValue, report) =>
              previousValue! + (report.water ? report.people : 0)) ??
      0;



  @override
  void initState() {
    super.initState();

    _routeStream =
        _firestore.collection('routes').doc(widget.user.uid).snapshots();

    _reportsSubscription = _firestore
        .collection('reports')
        .snapshots()
        .map(Report.parseQuerySnapshot)
        .listen(_onReportsUpdate);

    _positionSubscription =
        Geolocator.getPositionStream().listen(_onPositionUpdate);
  }

  @override
  void dispose() {
    _reportsSubscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: _routeStream,
        builder: _buildScreen,
      );

  _buildAppBar(BuildContext context, String title) => AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _logout,
            child: Text("Logout"),
            style: TextButton.styleFrom(
              primary: Theme.of(context).accentTextTheme.button?.color,
            ),
          ),
        ],
      );

  Widget _buildScreen(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingScreen(context);
    } else if (snapshot.data != null) {
      return _buildCurrentRouteScreen(context);
    } else {
      return _buildNewRouteScreen(context);
    }
  }

  Widget _buildLoadingScreen(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context, "Loading..."),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );

  Widget _buildNewRouteScreen(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context, "Setup your route"),
        body: _buildNewRouteBody(context),
      );

  Widget _buildCurrentRouteScreen(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context, "Current route"),
      );

  _logout() async {
    await _auth.signOut();
    Navigator.of(context).pop();
  }

  _buildNewRouteBody(BuildContext context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("How many places can you reach today?"),
            ),
            NumberPicker(
              minValue: 1,
              maxValue: 50,
              itemCount: 3,
              value: _placeCount,
              onChanged: _onPlaceCountChange,
              axis: Axis.horizontal,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.food_bank),
              title: Text("Food units:"),
              trailing: _reports != null
                  ? Text("$_foodUnits")
                  : CircularProgressIndicator(),
            ),
            ListTile(
              leading: Icon(Icons.food_bank),
              title: Text("Water units:"),
              trailing: _reports != null
                  ? Text("$_waterUnits")
                  : CircularProgressIndicator(),
            ),
            Divider(),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Back"),
                ),
                ElevatedButton(
                  onPressed: _generateRoute,
                  child: Text("Accept"),
                ),
              ],
            ),
          ],
        ),
      );

  _onReportsUpdate(List<Report> reports) {
    //TODO: ordinare per priorità
    setState(() {
      _reports = reports;
    });
  }

  _onPositionUpdate(Position position) {
    setState(() {
      _currentPosition = position;
    });
  }

  _onPlaceCountChange(int count) {
    setState(() {
      _placeCount = count;
    });
  }

  _generateRoute() async {
    final position = _currentPosition;
    if (position == null) return;

    final reports = _reports?.take(_placeCount);
    if (reports == null) return;

    final currentPositionString = "${position.latitude} ${position.longitude}";

    final service = DirectionsService();

    final request = DirectionsRequest(
      origin: currentPositionString,
      destination: currentPositionString,
      optimizeWaypoints: true,
      waypoints: reports.map((report) => DirectionsWaypoint(location: report.locationString)).toList(),
    );

    await service.route(request, _onRouteGenerated);
  }

  _onRouteGenerated(DirectionsResult result, DirectionsStatus? status) {
    //TODO
  }
}
