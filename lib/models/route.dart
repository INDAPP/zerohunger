import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final String id;
  final int distance;
  final int duration;
  final String? polyline;
  final int foodUnits;
  final int waterUnits;
  final GeoPoint? southwest;
  final GeoPoint? northeast;

  RouteModel.fromMap(String id, Map<String, dynamic> data)
      : id = id,
        distance = data['distance'],
        duration = data['duration'],
        polyline = data['polyline'],
        foodUnits = data['foodUnits'],
        waterUnits = data['waterUnits'],
        southwest = data['southwest'],
        northeast = data['northeast'];

  static RouteModel? parseDocumentSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data != null)
      return RouteModel.fromMap(doc.id, data);
    else
      return null;
  }
}