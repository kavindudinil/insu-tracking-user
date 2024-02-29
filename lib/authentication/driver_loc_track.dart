import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart'; // For Realtime Database
// import 'package:cloud_firestore/cloud_firestore.dart'; // For Cloud Firestore (replace as needed)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:insu_tracking/helpers/constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

import '../methods/manage_drivers_methods.dart';
import '../models/online_nearby_drivers.dart';
import '../models/route.dart';
import '../provider/location_provider.dart';
import '../provider/user_provider.dart';
import '../services/google_service.dart';

class DriverLocationTracker extends StatefulWidget {
  // Replace with driver ID or path to location data in your database
  final String driverId;

  const DriverLocationTracker(this.driverId, {super.key});

  @override
  State<DriverLocationTracker> createState() => _DriverLocationTrackerState();
}

class _DriverLocationTrackerState extends State<DriverLocationTracker>
    with TickerProviderStateMixin {
  final _markers = <Marker>{};
  late LatLng _driverLocation = const LatLng(0.0, 0.0);
  late String driverId;

  // late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
  //     _driverLocationSubscription;
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> googleMapController =
      Completer<GoogleMapController>();
  Position? currentPositionOfUser;
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;
  Set<Marker> markerSet = {};
  late AnimationController _controller;
  late Animation<AlignmentGeometry> animation;
  bool showFirstContainer = true;

  // Initialize Firebase (replace with your configuration)
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  makeDriverNearbyCarIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: const Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
              configuration, "asset/images/infimage.png")
          .then((iconImage) {
        carIconNearbyDriver = iconImage;
      });
    }
  }

  onCreate(GoogleMapController controller) {
    _mapController = controller;
    googleMapController.complete(_mapController);
    getCurrentLiveLocationOfUser();
  }

  getCurrentLiveLocationOfUser() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    _mapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    await GoogleMapsServices
        .convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
            currentPositionOfUser!, context);
    //
    // await getUserInfoAndCheckBlockStatus();
    //
    await initializeGeoFireListener();
  }

  updateAvailableNearbyOnlineDriversOnMap() {
    setState(() {
      markerSet.clear();
    });

    Set<Marker> markersTempSet = <Marker>{};

    for (OnlineNearbyDrivers eachOnlineNearbyDriver
        in ManageDriversMethods.nearbyOnlineDriversList) {
      LatLng driverCurrentPosition = LatLng(
          eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

      Marker driverMarker = Marker(
        markerId: MarkerId("driver ID = ${eachOnlineNearbyDriver.uidDriver}"),
        position: driverCurrentPosition,
        icon: carIconNearbyDriver!,
      );

      markersTempSet.add(driverMarker);
    }

    setState(() {
      markerSet = markersTempSet;
    });
  }

  initializeGeoFireListener() {
    Geofire.initialize("onlineDrivers");
    Geofire.queryAtLocation(currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude, 22)!
        .listen((driverEvent) {
      if (driverEvent != null) {
        var onlineDriverChild = driverEvent["callBack"];

        switch (onlineDriverChild) {
          case Geofire.onKeyEntered:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.nearbyOnlineDriversList
                .add(onlineNearbyDrivers);

            if (nearbyOnlineDriversKeysLoaded == true) {
              //update drivers on google map
              updateAvailableNearbyOnlineDriversOnMap();
            }

            break;

          case Geofire.onKeyExited:
            ManageDriversMethods.removeDriverFromList(driverEvent["key"]);

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          case Geofire.onKeyMoved:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.updateOnlineNearbyDriversLocation(
                onlineNearbyDrivers);

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          case Geofire.onGeoQueryReady:
            nearbyOnlineDriversKeysLoaded = true;

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;
        }
      }
    });
  }

  makeTripRequest() {
    tripRequestRef =
        FirebaseDatabase.instance.ref().child("tripRequests").push();

    var pickUpLocation =
        Provider.of<LocationProvider>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<LocationProvider>(context, listen: false).dropOffLocation;

    Map pickUpCoOrdinatesMap = {
      "latitude": pickUpLocation!.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };

    Map dropOffDestinationCoOrdinatesMap = {
      "latitude": dropOffDestinationLocation!.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map driverCoOrdinates = {
      "latitude": "",
      "longitude": "",
    };

    Map dataMap = {
      "tripID": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),
      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickUpCoOrdinatesMap,
      "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
      "pickUpAddress": pickUpLocation.placeName,
      "dropOffAddress": dropOffDestinationLocation.placeName,
      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": driverCoOrdinates,
      "driverName": "",
      "driverPhone": "",
      "driverPhoto": "",
      "fareAmount": "",
      "status": "new",
    };

    tripRequestRef!.set(dataMap);

    // tripStreamSubscription = tripRequestRef!.onValue.listen((eventSnapshot) async
    // {
    //   if(eventSnapshot.snapshot.value == null)
    //   {
    //     return;
    //   }
    //
    //   if((eventSnapshot.snapshot.value as Map)["driverName"] != null)
    //   {
    //     nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
    //   }
    //
    //   if((eventSnapshot.snapshot.value as Map)["driverPhone"] != null)
    //   {
    //     phoneNumberDriver = (eventSnapshot.snapshot.value as Map)["driverPhone"];
    //   }
    //
    //   if((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null)
    //   {
    //     photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
    //   }
    //
    //   if((eventSnapshot.snapshot.value as Map)["carDetails"] != null)
    //   {
    //     carDetailsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
    //   }
    //
    //   if((eventSnapshot.snapshot.value as Map)["status"] != null)
    //   {
    //     status = (eventSnapshot.snapshot.value as Map)["status"];
    //   }
    //
    //   if((eventSnapshot.snapshot.value as Map)["driverLocation"] != null)
    //   {
    //     double driverLatitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"].toString());
    //     double driverLongitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"].toString());
    //     LatLng driverCurrentLocationLatLng = LatLng(driverLatitude, driverLongitude);
    //
    //     if(status == "accepted")
    //     {
    //       //update info for pickup to user on UI
    //       //info from driver current location to user pickup location
    //       updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
    //     }
    //     else if(status == "arrived")
    //     {
    //       //update info for arrived - when driver reach at the pickup point of user
    //       setState(() {
    //         tripStatusDisplay = 'Driver has Arrived';
    //       });
    //     }
    //     else if(status == "ontrip")
    //     {
    //       //update info for dropoff to user on UI
    //       //info from driver current location to user dropoff location
    //       updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng);
    //     }
    //   }
    //
    //   if(status == "accepted")
    //   {
    //     displayTripDetailsContainer();
    //
    //     Geofire.stopListener();
    //
    //     //remove drivers markers
    //     setState(() {
    //       markerSet.removeWhere((element) => element.markerId.value.contains("driver"));
    //     });
    //   }
    //
    //   if(status == "ended")
    //   {
    //     if((eventSnapshot.snapshot.value as Map)["fareAmount"] != null)
    //     {
    //       double fareAmount = double.parse((eventSnapshot.snapshot.value as Map)["fareAmount"].toString());
    //
    //       var responseFromPaymentDialog = await showDialog(
    //         context: context,
    //         builder: (BuildContext context) => PaymentDialog(fareAmount: fareAmount.toString()),
    //       );
    //
    //       if(responseFromPaymentDialog == "paid")
    //       {
    //         tripRequestRef!.onDisconnect();
    //         tripRequestRef = null;
    //
    //         tripStreamSubscription!.cancel();
    //         tripStreamSubscription = null;
    //
    //         resetAppNow();
    //
    //         Restart.restartApp();
    //       }
    //     }
    //   }
    // });
  }

  @override
  void initState() {
    super.initState();
    driverId = widget.driverId;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    animation = Tween<AlignmentGeometry>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // _controller.addListener(() {
    //   setState(() {
    //     animationValue = _controller.value;
    //   });
    // });
    // final location = await Geolocator.getCurrentPosition();
    // final userLocation = LatLng(location.latitude, location.longitude);
    // _initializeFirebase();
    // _listenForDriverLocation();
    // routeModel = await getRouteByCoordinates(userLocation, _driverLocation);
  }

  // Replace with your database reference
  final _driverLocationRef = FirebaseFirestore.instance
      .collection('drivers'); // Replace with your database path

  @override
  void dispose() {
    _controller.dispose();
    // _driverLocationSubscription.cancel();
    super.dispose();
  }

  // void _listenForDriverLocation() {
  //   _driverLocationSubscription =
  //       _driverLocationRef.snapshots().listen((querySnapshot) {
  //     try {
  //       if (querySnapshot.docs.isNotEmpty) {
  //         // Assuming there's only one driver document (modify if needed)
  //         final data = querySnapshot.docs.first.data();
  //         final latitude = data['latitude'];
  //         final longitude = data['longitude'];
  //         setState(() {
  //           _driverLocation = LatLng(latitude, longitude);
  //           _updateMarkers();
  //         });
  //       }
  //     } catch (error) {
  //       // Handle potential errors during data extraction or processing
  //       print('Error retrieving driver location: $error');
  //     }
  //   });
  // }

  void _updateMarkers() {
    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: _driverLocation,
      // icon: BitmapDescriptor.fromAsset('assets/images/car_icon.png'), // Replace with your car icon asset
    ));
  }

  // final List<LatLng> decodedPoints = PolylinePoints().decodePolyline("your polyline");

  Future<RouteModel> getRouteByCoordinates(LatLng l1, LatLng l2) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=$GOOGLE_MAPS_API_KEY";
    Uri uri = Uri.parse(url);
    http.Response response = await http.get(uri);
    Map values = jsonDecode(response.body);
    Map routes = values["routes"][0];
    Map legs = values["routes"][0]["legs"][0];
    RouteModel route = RouteModel(
        points: routes["overview_polyline"]["points"],
        distance: Distance.fromMap(legs['distance']),
        timeNeeded: TimeNeeded.fromMap(legs['duration']),
        endAddress: legs['end_address'],
        startAddress: legs['end_address']);
    return route;
  }

  @override
  Widget build(BuildContext context) {
    makeDriverNearbyCarIcon();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Location'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: const EdgeInsets.only(top: 26, bottom: 210),
            initialCameraPosition: googlePlexInitialPosition,
            markers: markerSet,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            mapType: MapType.normal,
            onMapCreated: onCreate,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomSheet(onClosing: () {
              // Do something when the bottom sheet closes
            }, builder: (BuildContext context) {
              return showFirstContainer
                  ? getBottomSheetContent(
                      context,
                      currentPositionOfUser!.latitude,
                      currentPositionOfUser!.longitude,
                  Provider.of<UserProvider>(context, listen: false).username ??
                      '',
                  Provider.of<UserProvider>(context, listen: false).email,
                  Provider.of<UserProvider>(context, listen: false).photoUrl ??
                      '')
                  : loadingWidget(
                      context,
                      currentPositionOfUser!.latitude,
                      currentPositionOfUser!.longitude,
                  Provider.of<UserProvider>(context, listen: false).username ??
                      '',
                  Provider.of<UserProvider>(context, listen: false).email,
                  Provider.of<UserProvider>(context, listen: false).photoUrl ??
                      '');
            }),
          ),
        ],
      ),
    );
  }

  Widget getBottomSheetContent(BuildContext context, double lat, double long,
      String user, String email, String avatarUrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Add Accident request",
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          // Customer details section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: avatarUrl == ''
                    ? const Icon(
                        Icons.account_circle,
                        // Replace with your desired profile icon
                        size: 60,
                        color: Colors.black12, // Adjust color as needed
                      )
                    : Image.network(
                        avatarUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user, // Replace with customer's name
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      double maxWidth = constraints.maxWidth;

                      // Function to truncate email if it's too long
                      String truncateEmail(String email, double maxWidth) {
                        if (email.length > 20) {
                          // Set your desired length
                          email = '${email.substring(0, 20)}...';
                        }

                        return email;
                      }

                      bool isLandscape = MediaQuery.of(context).orientation ==
                          Orientation.landscape;

                      return Text(
                        isLandscape ? email : truncateEmail(email, maxWidth),
                        // style: FlutterFlowTheme.of(context).labelMedium,
                        // textDirection: TextDirection.ltr,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SwipeButton.expand(
            duration: const Duration(milliseconds: 200),
            thumb: const Icon(
              Icons.double_arrow_rounded,
              color: Colors.white,
            ),
            activeThumbColor: Colors.red,
            activeTrackColor: Colors.grey.shade300,
            onSwipe: () {
              Navigator.pop(context, true);
              // _openMap(lat, long);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Swipped"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "Swipe add Request",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
          LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            bool isLandscape =
                MediaQuery.of(context).orientation == Orientation.landscape;
            return SizedBox(
              height: isLandscape ? 0 : 15,
            );
          }),
        ],
      ),
    );
  }

  Widget loadingWidget(BuildContext context, double lat, double long,
      String user, String email, String avatarUrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Waiting for a Partner",
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 1500),
                alignment: animation.value,
                width: 100, // Adjust width as needed
                height: 10, // Adjust height as needed
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color.lerp(Colors.blue, Colors.purple, _controller.value)!,
                ),
              )
            ],
          ),

          const SizedBox(height: 15),

          SwipeButton.expand(
            duration: const Duration(milliseconds: 200),
            thumb: const Icon(
              Icons.double_arrow_rounded,
              color: Colors.white,
            ),
            activeThumbColor: Colors.red,
            activeTrackColor: Colors.grey.shade300,
            onSwipe: () {
              Navigator.pop(context, true);
              // _openMap(lat, long);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Swipped"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "Swipe add Request",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
          LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                bool isLandscape =
                    MediaQuery.of(context).orientation == Orientation.landscape;
                return SizedBox(
                  height: isLandscape ? 0 : 15,
                );
              }),
          // Customer details section
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     ClipRRect(
          //       borderRadius: BorderRadius.circular(60),
          //       child: avatarUrl == ''
          //           ? const Icon(
          //               Icons.account_circle,
          //               // Replace with your desired profile icon
          //               size: 60,
          //               color: Colors.black12, // Adjust color as needed
          //             )
          //           : Image.network(
          //               avatarUrl,
          //               width: 60,
          //               height: 60,
          //               fit: BoxFit.cover,
          //             ),
          //     ),
          //     const SizedBox(width: 15),
          //     const SizedBox(height: 20),
          //
          //   ],
          // ),
        ],
      ),
    );
  }
}

class SmoothColorProgressPainter extends CustomPainter {
  final Animation<double> animation;

  SmoothColorProgressPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.lerp(Colors.blue, Colors.purple, animation.value)!
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * animation.value, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
