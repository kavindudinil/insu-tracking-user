import 'package:flutter/material.dart';
// import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:txapita/helpers/constants.dart';
// import 'package:txapita/helpers/style.dart';
// import 'package:txapita/providers/app_state.dart';
// import 'package:txapita/providers/user.dart';

import '../helpers/constants.dart';
import '../provider/app_state.dart';

class DestinationSelectionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AppStateProvider appState = Provider.of<AppStateProvider>(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.28,
      builder: (BuildContext context, myscrollController) {
        return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(.8),
                    offset: const Offset(3, 2),
                    blurRadius: 7)
              ]),
          child: ListView(
            controller: myscrollController,
            children: [
              const Icon(
                Icons.remove,
                size: 40,
                color: Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Container(
                  color: Colors.grey.withOpacity(.3),
                  child: TextField(
                    onTap: () async {
                      // SharedPreferences preferences =
                      //     await SharedPreferences.getInstance();
                      // Prediction p = await PlacesAutocomplete.show(
                      //     context: context,
                      //     apiKey: GOOGLE_MAPS_API_KEY,
                      //     mode: Mode.overlay, // Mode.fullscreen
                      //     // language: "pt",
                      //     components: [
                      //       new Component(Component.country,
                      //           preferences.getString(COUNTRY)?? "ng")
                      //     ]);
                      // PlacesDetailsResponse detail =
                      //     await places.getDetailsByPlaceId(p.placeId??"");
                      // double? lat = detail.result.geometry?.location.lat;
                      // double? lng = detail.result.geometry?.location.lng;
                      // appState.changeRequestedDestination(
                      //     reqDestination: p.description??"", lat: lat!, lng: lng!);
                      // appState.updateDestination(destination: p.description??"");
                      // LatLng coordinates = LatLng(lat, lng);
                      // appState.setDestination(coordinates: coordinates);
                      // appState.addPickupMarker(appState.center);
                      // appState.changeWidgetShowed(
                      //     showWidget: Show.PICKUP_SELECTION);
                      // appState.sendRequest(coordinates: coordinates);
                    },
                    textInputAction: TextInputAction.go,
                    controller: appState.destinationController,
                    cursorColor: Colors.blue.shade900,
                    decoration: InputDecoration(
                      icon: Container(
                        margin: const EdgeInsets.only(left: 20, bottom: 15),
                        width: 10,
                        height: 10,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                        ),
                      ),
                      hintText: "Where to go?",
                      hintStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(15),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepOrange[300],
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                ),
                title: const Text("Home"),
                subtitle: const Text("25th avenue, 23 street"),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepOrange[300],
                  child: const Icon(
                    Icons.work,
                    color: Colors.white,
                  ),
                ),
                title: const Text("Work"),
                subtitle: const Text("25th avenue, 23 street"),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.withOpacity(0.18),
                  child: const Icon(
                    Icons.history,
                    color: Colors.blue,
                  ),
                ),
                title: const Text("Recent location"),
                subtitle: const Text("25th avenue, 23 street"),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.withOpacity(.18),
                  child: const Icon(
                    Icons.history,
                    color: Colors.blue,
                  ),
                ),
                title: const Text("Recent location"),
                subtitle: const Text("25th avenue, 23 street"),
              ),
            ],
          ),
        );
      },
    );
  }
}
