import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverModel {
  final String id;
  final String name;
  final String car;
  final String plate;
  final String photo;
  final String phone;

  final double rating;
  final int votes;

  final DriverPosition position;

  DriverModel({
    required this.id,
    required this.name,
    required this.car,
    required this.plate,
    required this.photo,
    required this.phone,
    required this.rating,
    required this.votes,
    required this.position,
  });

  DriverModel.fromSnapshot(DocumentSnapshot snapshot)
      : id = snapshot.id,
        name = snapshot['name'],
        car = snapshot['car'],
        plate = snapshot['plate'],
        photo = snapshot['photo'],
        phone = snapshot['phone'],
        rating = snapshot['rating'],
        votes = snapshot['votes'],
        position = DriverPosition(
          lat: snapshot['position']['lat'],
          lng: snapshot['position']['lng'],
          heading: snapshot['position']['heading'],
        );

  LatLng getPosition() {
    return LatLng(position.lat!, position.lng!); // Use non-null assertion
  }
}

class DriverPosition {
  final double? lat;
  final double? lng;
  final double? heading;

  DriverPosition({this.lat, this.lng, this.heading});
}
