import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';

import '../../helpers/constants.dart';
import '../../provider/app_state.dart';
import '../../services/loading.dart';


import 'package:flutter/material.dart';
// import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:txapita/helpers/constants.dart';
// import 'package:txapita/helpers/screen_navigation.dart';
// import 'package:txapita/helpers/style.dart';
// import 'package:txapita/providers/app_state.dart';
// import "package:google_maps_webservice/places.dart";
// import 'package:txapita/providers/user.dart';
// import 'package:txapita/screens/splash.dart';
import 'package:insu_tracking/widgets/custom_text.dart';
import 'package:insu_tracking/widgets/destination_selection.dart';
import 'package:insu_tracking/widgets/driver_found.dart';
import 'package:insu_tracking/widgets/payment_method_selection.dart';
import 'package:insu_tracking/widgets/pickup_selection_widget.dart';
import 'package:insu_tracking/widgets/trip_draggable.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  // final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var scaffoldState = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // _deviceToken();
  }

  // _deviceToken() async {
  //   SharedPreferences preferences = await SharedPreferences.getInstance();
  //   UserProvider _user = Provider.of<UserProvider>(context, listen: false);
  //
  //   if (_user.userModel?.token != preferences.getString('token')) {
  //     Provider.of<UserProvider>(context, listen: false).saveDeviceToken();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // UserProvider userProvider = Provider.of<UserProvider>(context);
    AppStateProvider appState = Provider.of<AppStateProvider>(context);
    return SafeArea(
      child: Scaffold(
        key: scaffoldState,
        // drawer: Drawer(
        //     child: ListView(
        //       children: [
        //         UserAccountsDrawerHeader(
        //             accountName: CustomText(
        //               text: userProvider.userModel?.name ?? "This is null",
        //               size: 18,
        //               weight: FontWeight.bold,
        //             ),
        //             accountEmail: CustomText(
        //               text: userProvider.userModel?.email ?? "This is null",
        //             )),
        //         ListTile(
        //           leading: Icon(Icons.exit_to_app),
        //           title: CustomText(text: "Log out"),
        //           onTap: () {
        //             userProvider.signOut();
        //             changeScreenReplacement(context, LoginScreen());
        //           },
        //         )
        //       ],
        //     )),
        body: Stack(
          children: [
            MapScreen(scaffoldState),
            Visibility(
              visible: appState.show == Show.DRIVER_FOUND,
              child: Positioned(
                  top: 60,
                  left: 15,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: appState.driverArrived ? Container(
                            color: Colors.green,
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                "Meet driver at the pick up location",
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                )
                              ),
                            ),
                          ) : Container(
                            color: Colors.blue,
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                "Meet driver at the pick up location",
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
            Visibility(
              visible: appState.show == Show.TRIP,
              child: Positioned(
                  top: 60,
                  left: MediaQuery.of(context).size.width / 7,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: Container(
                            color: Colors.blue,
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: RichText(text: TextSpan(
                                    children: [
                                      const TextSpan(
                                          text: "You\'ll reach your desiation in \n",
                                          style: TextStyle(fontWeight: FontWeight.w300)
                                      ),
                                      TextSpan(
                                          text: appState.routeModel?.timeNeeded?.text ?? "",
                                          style: const TextStyle(fontSize: 22)
                                      ),
                                    ]
                                ))
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
            // ANCHOR Draggable
            Visibility(
                visible: appState.show == Show.DESTINATION_SELECTION,
                child: DestinationSelectionWidget()),
            // ANCHOR PICK UP WIDGET
            // Visibility(
            //   visible: appState.show == Show.PICKUP_SELECTION,
            //   child: PickupSelectionWidget(
            //     scaffoldState: scaffoldState,
            //   ),
            // ),
            //  ANCHOR Draggable PAYMENT METHOD
            // Visibility(
            //     visible: appState.show == Show.PAYMENT_METHOD_SELECTION,
            //     child: PaymentMethodSelectionWidget(
            //       scaffoldState: scaffoldState,
            //     )),
            //  ANCHOR Draggable DRIVER
            Visibility(
                visible: appState.show == Show.DRIVER_FOUND,
                child: DriverFoundWidget()),

            //  ANCHOR Draggable DRIVER
            // Visibility(
            //     visible: appState.show == Show.TRIP,
            //     child: TripWidget()),
          ],
        ),
      ),
    );
  }
}


class MapScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldState;

  const MapScreen(this.scaffoldState, {super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapsPlaces googlePlaces;
  TextEditingController destinationController = TextEditingController();
  Color darkBlue = Colors.black;
  Color grey = Colors.grey;
  GlobalKey<ScaffoldState> scaffoldSate = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    scaffoldSate = widget.scaffoldState;
  }

  @override
  Widget build(BuildContext context) {
    AppStateProvider appState = Provider.of<AppStateProvider>(context);
    return appState.center == null
        ? const Loading()
        : Stack(
            children: <Widget>[
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: appState.center, zoom: 15),
                onMapCreated: appState.onCreate,
                myLocationEnabled: true,
                mapType: MapType.normal,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                markers: appState.markers,
                onCameraMove: appState.onCameraMove,
                polylines: appState.poly,
              ),
              Positioned(
                top: 10,
                left: 15,
                child: IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.blueAccent,
                      size: 30,
                    ),
                    onPressed: () {
                      scaffoldSate.currentState?.openDrawer();
                    }),
              ),
//              Positioned(
//                bottom: 60,
//                right: 0,
//                left: 0,
//                height: 60,
//                child: Visibility(
//                  visible: appState.routeModel != null,
//                  child: Padding(
//                    padding: const EdgeInsets.only(left: 15.0, right: 15.0),
//                    child: Container(
//                      color: Colors.white,
//                      child: Row(
//                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                        children: <Widget>[
//                          FlatButton.icon(
//                              onPressed: null,
//                              icon: Icon(Icons.timer),
//                              label: Text(
//                                  appState.routeModel?.timeNeeded?.text ?? "")),
//                          FlatButton.icon(
//                              onPressed: null,
//                              icon: Icon(Icons.flag),
//                              label: Text(
//                                  appState.routeModel?.distance?.text ?? "")),
//                          FlatButton(
//                              onPressed: () {},
//                              child: CustomText(
//                                text:
//                                    "\$${appState.routeModel?.distance?.value == null ? 0 : appState.routeModel?.distance?.value / 500}" ??
//                                        "",
//                                color: Colors.deepOrange,
//                              ))
//                        ],
//                      ),
//                    ),
//                  ),
//                ),
//              ),
            ],
          );
  }

  Future<Null> displayPrediction(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
      await places.getDetailsByPlaceId(p.placeId??"");

      var placeId = p.placeId;
      double? lat = detail.result.geometry?.location.lat;
      double? lng = detail.result.geometry?.location.lng;

      // var address = await Geolocator.local.findAddressesFromQuery(p.description??"");

      print(lat);
      print(lng);
    }
  }
}
