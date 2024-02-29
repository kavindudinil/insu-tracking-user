

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';

import '../provider/user_provider.dart';

const GOOGLE_MAPS_API_KEY = "AIzaSyALGYvbmqV692V7jOkJ-3ptgAhruVuO5GA";
const COUNTRY = "country";
FirebaseMessaging fcm = FirebaseMessaging.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;
GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: GOOGLE_MAPS_API_KEY);

const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);

String userName = "";
String userPhone = "0112074350";
String userID = FirebaseAuth.instance.currentUser!.uid;

