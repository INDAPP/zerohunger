import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoutesPage extends StatefulWidget {
  final User user;

  const RoutesPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream:
            _firestore.collection('routes').doc(widget.user.uid).snapshots(),
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
      );

  Widget _buildCurrentRouteScreen(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context, "Current route"),
      );

  _logout() async {
    await _auth.signOut();
    Navigator.of(context).pop();
  }
}
