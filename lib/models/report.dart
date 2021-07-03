import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportModel {
  final String id;
  final GeoPoint coordinates;
  final DateTime date;
  final int people;
  final bool water;
  final String? taken;

  LatLng get latLng => LatLng(coordinates.latitude, coordinates.longitude);
  int get severity => DateTime.now().difference(date).inDays * (water ? 3 : 1);
  String get locationString => "${coordinates.latitude} ${coordinates.longitude}";

  BitmapDescriptor get icon {
    final severity = this.severity;
    if (severity > 5)
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    else if (severity > 3)
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    else
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }


  ReportModel.fromMap(String id, Map<String, dynamic> data)
      : id = id,
        coordinates = data['coordinates'],
        date = data['date']?.toDate(),
        people = data['people'],
        water = data['water'],
        taken = data['taken'];

  static List<ReportModel> parseQuerySnapshot(
          QuerySnapshot<Map<String, dynamic>>? snapshot) =>
      snapshot?.docs.map(ReportModel.parseDocumentSnapshot).toList() ?? [];

  static ReportModel parseDocumentSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return ReportModel.fromMap(doc.id, doc.data());
  }
}
