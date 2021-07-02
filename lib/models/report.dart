import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Report {
  final String id;
  final GeoPoint coordinates;
  final DateTime date;
  final int people;
  final bool water;
  final String? taken;

  LatLng get latLng => LatLng(coordinates.latitude, coordinates.longitude);
  int get severity => date.difference(DateTime.now()).inDays * (water ? 3 : 1);

  Report.fromMap(String id, Map<String, dynamic> data)
      : id = id,
        coordinates = data['coordinates'],
        date = data['date']?.toDate(),
        people = data['people'],
        water = data['water'],
        taken = data['taken'];

  static List<Report> parseQuerySnapshot(
          QuerySnapshot<Map<String, dynamic>>? snapshot) =>
      snapshot?.docs.map(Report.parseDocumentSnapshot).toList() ?? [];

  static Report parseDocumentSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Report.fromMap(doc.id, doc.data());
  }
}
