import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zero_hunger/models/report.dart';
import 'package:zero_hunger/screens/report.dart';
import 'package:zero_hunger/screens/routes.dart';
import 'package:zero_hunger/widgets/report.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Completer<GoogleMapController> _mapControllerCompleter = Completer();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _centerPositionToUser();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context),
        floatingActionButton: _buildFab(context),
      );

  _buildAppBar(BuildContext context) => AppBar(
        title: Text("Help Reports"),
        actions: [
          IconButton(
            icon: Text("NGO"),
            onPressed: _onNgoPressed,
          ),
        ],
      );

  _buildBody(BuildContext context) => StreamBuilder(
        stream: _firestore
            .collection('reports')
            .snapshots()
            .map(Report.parseQuerySnapshot),
        builder: _buildMap,
      );

  _buildFab(BuildContext context) => FloatingActionButton.extended(
        onPressed: _onHelpPressed,
        label: Text("Help me!"),
        icon: Icon(Icons.flag),
      );

  Widget _buildMap(BuildContext context, AsyncSnapshot<List<Report>> snapshot) {
    final reports = snapshot.data ?? [];
    final markers = reports.map(_markerFor).toSet();
    return GoogleMap(
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      initialCameraPosition: _kGooglePlex,
      zoomControlsEnabled: false,
      onMapCreated: _onMapCreated,
      markers: markers,
    );
  }

  Widget _buildReportPage(BuildContext context) => ReportPage();

  Widget _buildRoutesPage(BuildContext context) => RoutesPage(
        user: _auth.currentUser!,
      );

  Widget _buildLoginDialog(BuildContext context) {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(hintText: "Email"),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(hintText: "Password"),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop([
            _emailController.text,
            _passwordController.text,
          ]),
          child: Text("Login"),
        ),
      ],
    );
  }

  Marker _markerFor(Report report) => Marker(
        markerId: MarkerId(report.id),
        position: report.latLng,
        onTap: () => _onReportTap(report),
        icon: _iconFor(report),
      );

  void _centerPositionToUser() async {
    final position = await _getCurrentePosition();

    if (position != null) {
      final mapController = await _mapControllerCompleter.future;

      final latLng = LatLng(position.latitude, position.longitude);
      final cameraUpdate = CameraUpdate.newLatLng(latLng);

      await mapController.moveCamera(cameraUpdate);
    }
  }

  _onHelpPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: _buildReportPage),
    );
  }

  _onReportTap(Report report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReportWidget(report: report),
      backgroundColor: Colors.transparent,
    );
  }

  _onMapCreated(GoogleMapController controller) {
    _mapControllerCompleter.complete(controller);
  }

  _onNgoPressed() async {
    var user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      final List<String>? credentials = await showDialog(
        context: context,
        builder: _buildLoginDialog,
      );
      if (credentials != null) {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: credentials.first,
          password: credentials.last,
        );
        user = userCredential.user;
      }
    }
    if (user == null || user.isAnonymous) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: _buildRoutesPage),
    );
  }

  BitmapDescriptor _iconFor(Report report) {
    final severity = report.severity;
    if (severity > 5)
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    else if (severity > 3)
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    else
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  Future<Position?> _getCurrentePosition() async {
    if (!(await Geolocator.isLocationServiceEnabled())) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    final position = Geolocator.getCurrentPosition();
    return position;
  }
}
