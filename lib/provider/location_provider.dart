import 'package:flutter/material.dart';
import 'package:flutterflow_ui/flutterflow_ui.dart';
import 'package:uuid/uuid.dart';

import '../models/address_model.dart';
import '../models/user.dart';
import '../services/riding_request.dart';

class LocationProvider extends ChangeNotifier{
  late double latitude;
  late double longitude;
  late LatLng? userLocation;
  late String? userAddress;
  late String? driverAddress;
  late LatLng? driverLocation;
  late final RideRequestServices _requestServices = RideRequestServices();

  void updateLocation({required double latitude, required double longitude}) async {
    this.latitude = latitude;
    this.longitude = longitude;
    notifyListeners();
  }

  AddressModel? pickUpLocation;
  AddressModel? dropOffLocation;

  void updatePickUpLocation(AddressModel pickUpModel)
  {
    pickUpLocation = pickUpModel;
    notifyListeners();
  }

  void updateDropOffLocation(AddressModel dropOffModel)
  {
    dropOffLocation = dropOffModel;
    notifyListeners();
  }



}