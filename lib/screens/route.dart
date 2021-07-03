import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_utils/google_maps_utils.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:zero_hunger/models/report.dart';
import 'package:zero_hunger/models/route.dart';
import 'package:zero_hunger/widgets/report.dart';

import '../constants.dart';

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

  late Stream<RouteModel?> _routeStream;
  late Stream<List<ReportModel>> _routeReportsStream;
  late StreamSubscription<List<ReportModel>> _reportsSubscription;
  late StreamSubscription<Position> _positionSubscription;
  int _placeCount = 10;
  List<ReportModel>? _reports;
  Position? _currentPosition;
  List<String> _generatedReportsIds = [];
  List<String> _currentReportsIds = [];

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

    _routeStream = _firestore
        .collection('routes')
        .doc(widget.user.uid)
        .snapshots()
        .map(RouteModel.parseDocumentSnapshot);

    _routeReportsStream = _firestore
        .collection('reports')
        .where('taken', isEqualTo: widget.user.uid)
        .snapshots()
        .map(ReportModel.parseQuerySnapshot);

    _reportsSubscription = _firestore
        .collection('reports')
        .where('taken', isNull: true)
        .snapshots()
        .map(ReportModel.parseQuerySnapshot)
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

  Widget _buildScreen(
      BuildContext context, AsyncSnapshot<RouteModel?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingScreen(context);
    } else if (snapshot.data != null) {
      return _buildCurrentRouteScreen(context, snapshot.data!);
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

  Widget _buildCurrentRouteScreen(BuildContext context, RouteModel route) =>
      Scaffold(
        appBar: _buildAppBar(context, "Current route"),
        body: _buildCurrentRouteBody(context, route),
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
              leading: Icon(Icons.local_drink),
              title: Text("Water units:"),
              trailing: _reports != null
                  ? Text("$_waterUnits")
                  : CircularProgressIndicator(),
            ),
            Divider(),
            ElevatedButton(
              onPressed: _generateRoute,
              child: Text("Accept"),
            ),
          ],
        ),
      );

  _buildCurrentRouteBody(BuildContext context, RouteModel route) {
    final target = LatLng(
        (route.southwest?.latitude ?? 0) - (route.northeast?.latitude ?? 0),
        (route.southwest?.longitude ?? 0) - (route.northeast?.longitude ?? 0));
    final camera = CameraPosition(target: target);
    final polylines = Set<Polyline>();
    final pl = route.polyline;
    if (pl != null) {
      final points = PolyUtils.decode(pl);
      final polyline = Polyline(
        polylineId: PolylineId(route.id),
        points:
            points.map((p) => LatLng(p.x.toDouble(), p.y.toDouble())).toList(),
        color: Colors.red,
        width: 5,
      );
      polylines.add(polyline);
    }
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ReportModel>>(
            stream: _routeReportsStream,
            builder: (context, snapshot) {
              return GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                initialCameraPosition: camera,
                polylines: polylines,
                onMapCreated: (controller) => _onMapCreated(controller, route),
                markers: (snapshot.data ?? []).map(_markerFor).toSet(),
              );
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.food_bank),
          title: Text("Food units:"),
          trailing: Text("${route.foodUnits}"),
        ),
        ListTile(
          leading: Icon(Icons.local_drink),
          title: Text("Water units:"),
          trailing: Text("${route.waterUnits}"),
        ),
        ListTile(
          leading: Icon(Icons.timer),
          title: Text("Duration:"),
          trailing: Text("${(route.duration / 3600).toStringAsFixed(1)} h"),
        ),
        ListTile(
          leading: Icon(Icons.directions),
          title: Text("Distance:"),
          trailing: Text("${(route.distance / 1000).toStringAsFixed(2)} km"),
        ),
        Divider(),
        ElevatedButton(
          onPressed: _completeRoute,
          child: Text("Mark as Completed"),
        ),
        SizedBox(
          height: 24,
        ),
      ],
    );
  }

  Marker _markerFor(ReportModel report) => Marker(
        markerId: MarkerId(report.id),
        position: report.latLng,
        onTap: () => _onReportTap(report),
        icon: report.icon,
      );

  _onReportTap(ReportModel report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReportWidget(
        report: report,
        navigationButton: true,
      ),
      backgroundColor: Colors.transparent,
    );
  }

  _onMapCreated(GoogleMapController controller, RouteModel route) {
    //controller.setMapStyle(google_maps_style);
    final bounds = LatLngBounds(
        southwest: route.southwest?.latLng ?? LatLng(0, 0),
        northeast: route.northeast?.latLng ?? LatLng(0, 0));
    final update = CameraUpdate.newLatLngBounds(bounds, 16);
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      controller.moveCamera(update);
    });
  }

  _onReportsUpdate(List<ReportModel> reports) {
    reports.sort((r1, r2) => r2.severity.compareTo(r1.severity));
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
      waypoints: reports
          .map((report) => DirectionsWaypoint(location: report.locationString))
          .toList(),
    );

    _generatedReportsIds = reports.map((report) => report.id).toList();

    await service.route(request, _onRouteGenerated);
  }

  _onRouteGenerated(DirectionsResult result, DirectionsStatus? status) async {
    if (status != DirectionsStatus.ok) return;
    final route = result.routes!.first;
    final distance = route.legs?.fold<num>(
            0,
            (previousValue, leg) =>
                previousValue + (leg.distance?.value ?? 0)) ??
        0; //meters
    final duration = route.legs?.fold<num>(
            0,
            (previousValue, leg) =>
                previousValue + (leg.duration?.value ?? 0)) ??
        0; //seconds

    final data = {
      'distance': distance,
      'duration': duration,
      'polyline': route.overviewPolyline?.points,
      'foodUnits': _foodUnits,
      'waterUnits': _waterUnits,
      'southwest': route.bounds?.southwest.geoPoint,
      'northeast': route.bounds?.northeast.geoPoint,
    };

    final batch = _firestore.batch();

    final routeRef = _firestore.collection('routes').doc(widget.user.uid);

    batch.set(routeRef, data);

    _generatedReportsIds.forEach((reportId) {
      final reportRef = _firestore.collection('reports').doc(reportId);
      batch.update(reportRef, {'taken': widget.user.uid});
    });

    await batch.commit();
  }

  _completeRoute() async {
    final reports = await _firestore
        .collection('reports')
        .where('taken', isEqualTo: widget.user.uid).get();

    final batch = _firestore.batch();

    final routeRef = _firestore.collection('routes').doc(widget.user.uid);


    batch.delete(routeRef);

    reports.docs.map((r) => r.id).forEach((reportId) {
      final reportRef = _firestore.collection('reports').doc(reportId);
      batch.delete(reportRef);
    });

    await batch.commit();
  }
}

extension GeoCoordParse on GeoCoord {
  GeoPoint get geoPoint => GeoPoint(this.latitude, this.longitude);
}

extension GeoPointParse on GeoPoint {
  LatLng get latLng => LatLng(this.latitude, this.longitude);
}
