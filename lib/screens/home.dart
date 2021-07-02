import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zero_hunger/screens/report.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context),
        floatingActionButton: _buildFab(context),
      );

  _buildAppBar(BuildContext context) => AppBar(
        title: Text("Help Reports"),
      );

  _buildBody(BuildContext context) => GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        initialCameraPosition: _kGooglePlex,
      );

  _buildFab(BuildContext context) => FloatingActionButton.extended(
        onPressed: _onHelpPressed,
        label: Text("Help me!"),
        icon: Icon(Icons.flag),
      );

  _buildReportPage(BuildContext context) => ReportPage();

  _onHelpPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: _buildReportPage),
    );
  }
}
