import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:insu_tracking/helpers/constants.dart';
// import 'package:txapita/helpers/style.dart';
// import 'package:txapita/models/driver.dart';
// import 'package:txapita/models/ride_Request.dart';
import 'package:insu_tracking/models/route.dart';
// import 'package:txapita/models/user.dart';
// import 'package:txapita/services/drivers.dart';
import 'package:insu_tracking/services/google_service.dart';
// import 'package:txapita/services/ride_requests.dart';
// import 'package:txapita/widgets/custom_btn.dart';
// import 'package:txapita/widgets/custom_text.dart';
// import 'package:txapita/widgets/stars.dart';
import 'package:uuid/uuid.dart';

import '../models/driver.dart';
import '../models/ride_request.dart';
import '../models/user.dart';
import '../services/driver_service.dart';
import '../services/riding_request.dart';

// * THIS ENUM WILL CONTAIN THE DRAGGABLE WIDGET TO BE DISPLAYED ON THE MAIN SCREEN
enum Show {
  DESTINATION_SELECTION,
  PICKUP_SELECTION,
  PAYMENT_METHOD_SELECTION,
  DRIVER_FOUND,
  TRIP
}

class AppStateProvider with ChangeNotifier {
  static const ACCEPTED = 'accepted';
  static const CANCELLED = 'cancelled';
  static const PENDING = 'pending';
  static const EXPIRED = 'expired';
  static const PICKUP_MARKER_ID = 'pickup';
  static const LOCATION_MARKER_ID = 'location';
  static const DRIVER_AT_LOCATION_NOTIFICATION = 'DRIVER_AT_LOCATION';
  static const REQUEST_ACCEPTED_NOTIFICATION = 'REQUEST_ACCEPTED';
  static const TRIP_STARTED_NOTIFICATION = 'TRIP_STARTED';

  final Set<Marker> _markers = {};

  //  this polys will be displayed on the map
  final Set<Polyline> _poly = {};

  // this polys temporarely store the polys to destination
  Set<Polyline> _routeToDestinationPolys = {};

  // this polys temporarely store the polys to driver
  Set<Polyline> _routeToDriverpoly = {};

  final GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  late GoogleMapController _mapController;
  static LatLng _center = const LatLng(0.0, 0.0);
  LatLng _lastPosition = _center;
  TextEditingController pickupLocationControlelr = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  late Position position;
  final DriverService _driverService = DriverService();

  //  draggable to show
  Show show = Show.DESTINATION_SELECTION;

  //   taxi pin
  late BitmapDescriptor carPin;

  //   location pin
  late BitmapDescriptor locationPin;

  LatLng get center => _center;

  LatLng get lastPosition => _lastPosition;

  Set<Marker> get markers => _markers;

  Set<Polyline> get poly => _poly;

  GoogleMapController get mapController => _mapController;
  late RouteModel routeModel;

  //  Driver request related variables
  late bool lookingForDriver = false;
  late bool alertsOnUi = false;
  late bool driverFound = false;
  late bool driverArrived = false;
  late final RideRequestServices _requestServices = RideRequestServices();
  late int timeCounter = 0;
  late double percentage = 0;
  late Timer periodicTimer;
  late String requestedDestination;
  late String requestStatus = "";
  late double requestedDestinationLat;

  late double requestedDestinationLng;
  late RideRequestModel rideRequestModel;
  late BuildContext mainContext;

//  this variable will listen to the status of the ride request
  late StreamSubscription<QuerySnapshot> requestStream;

  // this variable will keep track of the drivers position before and during the ride
  late StreamSubscription<QuerySnapshot> driverStream;

//  this stream is for all the driver on the app
  late StreamSubscription<List<DriverModel>> allDriversStream;

  late DriverModel driverModel;
  late LatLng pickupCoordinates;
  late LatLng destinationCoordinates;
  late double ridePrice = 0;
  late String notificationType = "";

  AppStateProvider() {
    _saveDeviceToken();
//     fcm.app(
// //      this callback is used when the app runs on the foreground
//         onMessage: handleOnMessage,
// //        used when the app is closed completely and is launched using the notification
//         onLaunch: handleOnLaunch,
// //        when its on the background and opened using the notification drawer
//         onResume: handleOnResume);

    _setCustomMapPin();
    // _getUserLocation();
    _listemToDrivers();
    Geolocator.getPositionStream().listen(_updatePosition);
  }

// ANCHOR: MAPS & LOCATION METHODS
  _updatePosition(Position newPosition) {
    position = newPosition;
    notifyListeners();
  }

  // Future<Position> getUserLocation() async {
  //   // Ensure permissions before accessing location
  //   LocationPermission permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.deniedForever) {
  //       // Handle permanent denial (e.g., notify user or seek alternative approach)
  //       // For this example, we'll throw an exception for clarity
  //       throw Exception("Location permissions permanently denied");
  //     }
  //   }
  //
  //   // Get current position with high accuracy
  //   Position position = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high,
  //   );
  //
  //   // Get placemark for country information
  //   List<Placemark> placemark = await Geolocator()
  //       .placemarkFromCoordinates(position.latitude, position.longitude);
  //
  //   // Store country code in SharedPreferences if not already present
  //   final prefs = await SharedPreferences.getInstance();
  //   if (!prefs.containsKey(COUNTRY)) {
  //     final country = placemark[0].isoCountryCode.toLowerCase();
  //     await prefs.setString(COUNTRY, country);
  //   }
  //
  //   // Update center coordinates and notify listeners (assuming a state management setup)
  //   _center = LatLng(position.latitude, position.longitude);
  //   notifyListeners();
  //
  //   return position;
  // }

  onCreate(GoogleMapController controller) {
    _mapController = controller;

  }

  setLastPosition(LatLng position) {
    _lastPosition = position;
    notifyListeners();
  }

  onCameraMove(CameraPosition position) {
    // MOVE the pickup marker only when selecting the pickup location
    if (show == Show.PICKUP_SELECTION) {
      _lastPosition = position.target;
      changePickupLocationAddress(address: "loading...");

      if (_markers.isNotEmpty) {
        for (final element in _markers) {
          if (element.markerId.value == PICKUP_MARKER_ID) {
            _markers.remove(element);
            pickupCoordinates = position.target;
            addPickupMarker(position.target);

            // Instead of using Placemark, directly set coordinates as a placeholder
            pickupLocationControlelr.text =
            "(${position.target.latitude}, ${position.target.longitude})";

            notifyListeners();
            break; // Exit the loop as the marker is found and updated
          }
        }
      }
    }
  }


  Future sendRequest(
      {required LatLng origin, required LatLng destination}) async {
    LatLng org;
    LatLng dest;

    if (origin == null && destination == null) {
      org = pickupCoordinates;
      dest = destinationCoordinates;
    } else {
      org = origin;
      dest = destination;
    }

    RouteModel route =
        await _googleMapsServices.getRouteByCoordinates(org, dest);
    routeModel = route;
    List<Marker> mks = _markers
        .where((element) => element.markerId.value == "location")
        .toList();
    if (mks.isNotEmpty) {
      _markers.remove(mks[0]);
    }
// ! another method will be created just to draw the polys and add markers
    _addLocationMarker(destinationCoordinates, routeModel.distance.text ?? "");
    _center = destinationCoordinates;
    _createRoute(route.points, color: Colors.deepOrange);
    _createRoute(
      route.points, color: Colors.blue,
    );
    _routeToDestinationPolys = _poly;
    notifyListeners();
  }

  void updateDestination({required String destination}) {
    destinationController.text = destination;
    notifyListeners();
  }

  _createRoute(String decodeRoute, {required Color color}) {
    clearPoly();
    var uuid = new Uuid();
    String polyId = uuid.v1();
    _poly.add(Polyline(
        polylineId: PolylineId(polyId),
        width: 12,
        color: color ?? Colors.blue,
        onTap: () {},
        points: _convertToLatLong(_decodePoly(decodeRoute))));
    notifyListeners();
  }

  List<LatLng> _convertToLatLong(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    List lList = [];
    int index = 0;
    int len = poly.length;
    int c = 0;
// repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for decoding value of one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negetive then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

/*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) {
      lList[i] += lList[i - 2];
    }

    print(lList.toString());

    return lList;
  }

// ANCHOR: MARKERS AND POLYS
  _addLocationMarker(LatLng position, String distance) {
    _markers.add(Marker(
        markerId: const MarkerId(LOCATION_MARKER_ID),
        position: position,
        anchor: const Offset(0, 0.85),
        infoWindow:
            InfoWindow(title: destinationController.text, snippet: distance),
        icon: locationPin));
    notifyListeners();
  }

  addPickupMarker(LatLng position) {
    _markers.add(Marker(
        markerId: const MarkerId(PICKUP_MARKER_ID),
        position: position,
        anchor: const Offset(0, 0.85),
        zIndex: 3,
        infoWindow: const InfoWindow(title: "Pickup", snippet: "location"),
        icon: locationPin));
    notifyListeners();
  }

  void _addDriverMarker(
      {required LatLng position,
      required double rotation,
      required String driverId}) {
    var uuid = new Uuid();
    String markerId = uuid.v1();
    _markers.add(Marker(
        markerId: MarkerId(markerId),
        position: position,
        rotation: rotation,
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: const Offset(1, 1),
        icon: carPin));
  }

  _updateMarkers(List<DriverModel> drivers) {
//    this code will ensure that when the driver markers are updated the location marker wont be deleted
    List<Marker> locationMarkers = _markers
        .where((element) => element.markerId.value == 'location')
        .toList();
    clearMarkers();
    if (locationMarkers.isNotEmpty) {
      _markers.add(locationMarkers[0]);
    }

//    here we are updating the drivers markers
    for (var driver in drivers) {
      _addDriverMarker(
          driverId: driver.id,
          position:
              LatLng(driver.position.lat ?? 0.0, driver.position.lng ?? 0.0),
          rotation: driver.position.heading ?? 0.0);
    }
  }

  _updateDriverMarker(Marker marker) {
    _markers.remove(marker);
    sendRequest(
        origin: pickupCoordinates, destination: driverModel.getPosition());
    notifyListeners();
    _addDriverMarker(
        position: driverModel.getPosition(),
        rotation: driverModel.position.heading ?? 0.0,
        driverId: driverModel.id);
  }

  _setCustomMapPin() async {
    carPin = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5), 'images/taxi.png');

    locationPin = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5), 'images/pin.png');
  }

  clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  _clearDriverMarkers() {
    for (var element in _markers) {
      String markerId = element.markerId.value;
      if (markerId != driverModel.id ||
          markerId != LOCATION_MARKER_ID ||
          markerId != PICKUP_MARKER_ID) {
        _markers.remove(element);
        notifyListeners();
      }
    }
  }

  clearPoly() {
    _poly.clear();
    notifyListeners();
  }

// ANCHOR UI METHODS
  changeMainContext(BuildContext context) {
    mainContext = context;
    notifyListeners();
  }

  changeWidgetShowed({required Show showWidget}) {
    show = showWidget;
    notifyListeners();
  }

  showRequestCancelledSnackBar(BuildContext context) {}

  showRequestExpiredAlert(BuildContext context) {
    if (alertsOnUi) Navigator.pop(context);

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)), //this right here
            child: const SizedBox(
              height: 200,
              child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Request Expired",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )),
            ),
          );
        });
  }

  showDriverBottomSheet(BuildContext context) {
    if (alertsOnUi) Navigator.pop(context);

    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SizedBox(
              height: 400,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Driver Found",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: driverModel?.photo == null,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(40)),
                          child: const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 45,
                            child: Icon(
                              Icons.person,
                              size: 65,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: driverModel?.photo != null,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(40)),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundImage: NetworkImage(driverModel!.photo),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        driverModel?.name ?? "Nan",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // _stars(rating: driverModel.rating, votes: driverModel.votes),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Handle button press logic here (e.g., navigate to a driver details page)
                        },
                        icon: const Icon(Icons.directions_car),
                        label: Text(driverModel.car ?? "N/A"),
                      ),
                      Text(driverModel.plate,
                          style: const TextStyle(color: Colors.deepOrange))
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                          onPressed: () {
                            // Handle button press logic here (e.g., navigate to a driver details page)
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green,
                            shadowColor: Colors.green,
                          ),
                          child: const Text("Call")),
                      TextButton(
                        onPressed: () {
                          // Handle button press logic here (e.g., navigate to a driver details page)
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          shadowColor: Colors.redAccent,
                        ),
                        child: const Text("Cancel"),
                      ),
                    ],
                  )
                ],
              ));
        });
  }

  // _stars({required int votes, required double rating}) {
  //   if (votes == 0) {
  //     return StarsWidget(
  //       numberOfStars: 0,
  //     );
  //   } else {
  //     double finalRate = rating / votes;
  //     return StarsWidget(
  //       numberOfStars: finalRate.floor(),
  //     );
  //   }
  // }

  // ANCHOR RIDE REQUEST METHODS
  _saveDeviceToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) {
      String? deviceToken = await fcm.getToken();
      await prefs.setString('token', deviceToken!);
    }
  }

  changeRequestedDestination(
      {required String reqDestination,
      required double lat,
      required double lng}) {
    requestedDestination = reqDestination;
    requestedDestinationLat = lat;
    requestedDestinationLng = lng;
    notifyListeners();
  }

  listenToRequest({required String id, required BuildContext context}) async {
    requestStream = _requestServices.requestStream().listen((querySnapshot) {
      querySnapshot.docChanges.forEach((doc) async {
        if (doc.doc.id == id) {
          rideRequestModel = RideRequestModel.fromSnapshot(doc.doc);
          notifyListeners();
          switch (rideRequestModel.status) {
            case CANCELLED:
              break;
            case ACCEPTED:
              if (lookingForDriver) Navigator.pop(context);
              lookingForDriver = false;
              driverModel = await _driverService
                  .getDriverById("driverId"); // rideRequestModel.driverId
              periodicTimer.cancel();
              clearPoly();
              _stopListeningToDriversStream();
              _listenToDriver();
              show = Show.DRIVER_FOUND;
              notifyListeners();

              // showDriverBottomSheet(context);
              break;
            case EXPIRED:
              showRequestExpiredAlert(context);
              break;
            default:
              break;
          }
        }
      });
    });
  }

  requestDriver(
      {required UserModel user,
      required double lat,
      required double lng,
      required BuildContext context,
      required Map distance}) {
    alertsOnUi = true;
    notifyListeners();
    var uuid = new Uuid();
    String id = uuid.v1();
    _requestServices.createRideRequest(
        id: id,
        userId: user.id,
        username: user.name,
        distance: distance,
        destination: {
          "address": requestedDestination,
          "latitude": requestedDestinationLat,
          "longitude": requestedDestinationLng
        },
        position: {
          "latitude": lat,
          "longitude": lng
        });
    listenToRequest(id: id, context: context);
    percentageCounter(requestId: id, context: context);
  }

  cancelRequest() {
    lookingForDriver = false;
    _requestServices
        .updateRequest({"id": rideRequestModel.id, "status": "cancelled"});
    periodicTimer.cancel();
    notifyListeners();
  }

// ANCHOR LISTEN TO DRIVER
  _listemToDrivers() {
    allDriversStream = _driverService.getDrivers().listen(_updateMarkers);
  }

  _listenToDriver() {
    driverStream = _driverService.driverStream().listen((event) {
      event.docChanges.forEach((change) async {
        if (change.doc.id == driverModel.id) {
          driverModel = DriverModel.fromSnapshot(change.doc);
          // code to update marker
//          List<Marker> _m = _markers
//              .where((element) => element.markerId.value == driverModel.id).toList();
//          _markers.remove(_m[0]);
          clearMarkers();
          sendRequest(
              origin: pickupCoordinates,
              destination: driverModel.getPosition());
          if (routeModel.distance.value! <= 200) {
            driverArrived = true;
          }
          notifyListeners();

          _addDriverMarker(
              position: driverModel.getPosition(),
              rotation: driverModel.position.heading ?? 0.0,
              driverId: driverModel.id);
          addPickupMarker(pickupCoordinates);
          // _updateDriverMarker(_m[0]);
        }
      });
    });

    show = Show.DRIVER_FOUND;
    notifyListeners();
  }

  _stopListeningToDriversStream() {
//    _clearDriverMarkers();
    allDriversStream.cancel();
  }

//  Timer counter for driver request
  percentageCounter(
      {required String requestId, required BuildContext context}) {
    lookingForDriver = true;
    notifyListeners();
    periodicTimer = Timer.periodic(Duration(seconds: 1), (time) {
      timeCounter = timeCounter + 1;
      percentage = timeCounter / 100;
      print("====== GOOOO $timeCounter");
      if (timeCounter == 100) {
        timeCounter = 0;
        percentage = 0;
        lookingForDriver = false;
        _requestServices.updateRequest({"id": requestId, "status": "expired"});
        time.cancel();
        if (alertsOnUi) {
          Navigator.pop(context);
          alertsOnUi = false;
          notifyListeners();
        }
        requestStream.cancel();
      }
      notifyListeners();
    });
  }

  setPickCoordinates({required LatLng coordinates}) {
    pickupCoordinates = coordinates;
    notifyListeners();
  }

  setDestination({required LatLng coordinates}) {
    destinationCoordinates = coordinates;
    notifyListeners();
  }

  changePickupLocationAddress({required String address}) {
    pickupLocationControlelr.text = address;
    _center = pickupCoordinates;
    notifyListeners();
  }

  // ANCHOR PUSH NOTIFICATION METHODS
  Future handleOnMessage(Map<String, dynamic> data) async {
    print("=== data = ${data.toString()}");
    notificationType = data['data']['type'];

    if (notificationType == DRIVER_AT_LOCATION_NOTIFICATION) {
    } else if (notificationType == TRIP_STARTED_NOTIFICATION) {
      show = Show.TRIP;
      sendRequest(
          origin: pickupCoordinates, destination: destinationCoordinates);
      notifyListeners();
    } else if (notificationType == REQUEST_ACCEPTED_NOTIFICATION) {}
    notifyListeners();
  }

  Future handleOnLaunch(Map<String, dynamic> data) async {
    notificationType = data['data']['type'];
    if (notificationType == DRIVER_AT_LOCATION_NOTIFICATION) {
    } else if (notificationType == TRIP_STARTED_NOTIFICATION) {
    } else if (notificationType == REQUEST_ACCEPTED_NOTIFICATION) {}
    driverModel = await _driverService.getDriverById(data['data']['driverId']);
    _stopListeningToDriversStream();

    _listenToDriver();
    notifyListeners();
  }

  Future handleOnResume(Map<String, dynamic> data) async {
    notificationType = data['data']['type'];

    _stopListeningToDriversStream();
    if (notificationType == DRIVER_AT_LOCATION_NOTIFICATION) {
    } else if (notificationType == TRIP_STARTED_NOTIFICATION) {
    } else if (notificationType == REQUEST_ACCEPTED_NOTIFICATION) {}

    if (lookingForDriver) Navigator.pop(mainContext);
    lookingForDriver = false;
    driverModel = await _driverService.getDriverById(data['data']['driverId']);
    periodicTimer.cancel();
    notifyListeners();
  }
}
