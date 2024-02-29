// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:percent_indicator/linear_percent_indicator.dart';
// import 'package:provider/provider.dart';
//
// import '../provider/app_state.dart';
// import 'custom_text.dart';
//
// class PaymentMethodSelectionWidget extends StatelessWidget {
//   final GlobalKey<ScaffoldState> scaffoldState;
//
//   const PaymentMethodSelectionWidget({required Key key, required this.scaffoldState})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     AppStateProvider appState = Provider.of<AppStateProvider>(context);
//     // UserProvider userProvider = Provider.of<UserProvider>(context);
//
//     return DraggableScrollableSheet(
//         initialChildSize: 0.3,
//         minChildSize: 0.3,
//         builder: (BuildContext context, myscrollController) {
//           return Container(
//             decoration: BoxDecoration(color: Colors.white,
// //                        borderRadius: BorderRadius.only(
// //                            topLeft: Radius.circular(20),
// //                            topRight: Radius.circular(20)),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.grey.withOpacity(.8),
//                       offset: const Offset(3, 2),
//                       blurRadius: 7)
//                 ]),
//             child: ListView(
//               controller: myscrollController,
//               children: [
//                 const SizedBox(height: 10),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 15),
//                   child: Text(
//                     "How do you want to pay,\n\$${appState.ridePrice}",
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 15),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(
//                                 color: Colors.blue.withOpacity(0.3),
//                                 width: 1.5)),
//                         child: ElevatedButton.icon(
//                             onPressed: () {
//                               // scaffoldState.currentState?.(const SnackBar(
//                               //     content: Text("Method not available!")));
//                             },
//                             icon: const Icon(Icons.credit_card),
//                             label: const Text("With Card")),
//                       ),
//                       Container(
//                         decoration: BoxDecoration(
//                             color: Colors.blueAccent.withOpacity(0.1),
//                             border: Border.all(color: Colors.blue, width: 1.5)),
//                         child: ElevatedButton.icon(
//                             onPressed: () {},
//                             icon: Icon(Icons.monetization_on),
//                             label: Text("With Cash")),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 10,
//                 ),
//                 appState.lookingForDriver
//                     ? Padding(
//                         padding: const EdgeInsets.only(top: 14),
//                         child: Container(
//                           color: Colors.white,
//                           child: const ListTile(
//                             title: SpinKitWave(
//                               color: Colors.black,
//                               size: 30,
//                             ),
//                           ),
//                         ),
//                       )
//                     : SizedBox(
//                         width: double.infinity,
//                         height: 48,
//                         child: Padding(
//                           padding: const EdgeInsets.only(
//                             left: 15.0,
//                             right: 15.0,
//                           ),
//                           child: ElevatedButton(
//                             onPressed: () async {
//                               appState.requestDriver(
//                                   distance:
//                                       appState.routeModel.distance.toJson(),
//                                   user: userProvider.userModel,
//                                   lat: appState.pickupCoordinates.latitude,
//                                   lng: appState.pickupCoordinates.longitude,
//                                   context: context);
//                               appState.changeMainContext(context);
//
//                               showDialog(
//                                   context: context,
//                                   builder: (BuildContext context) {
//                                     return Dialog(
//                                       shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                               20.0)), //this right here
//                                       child: Container(
//                                         height: 200,
//                                         child: Padding(
//                                           padding: const EdgeInsets.all(12.0),
//                                           child: Column(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               SpinKitWave(
//                                                 color: black,
//                                                 size: 30,
//                                               ),
//                                               SizedBox(
//                                                 height: 10,
//                                               ),
//                                               Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment.center,
//                                                 children: [
//                                                   CustomText(
//                                                       text:
//                                                           "Looking for a driver"),
//                                                 ],
//                                               ),
//                                               SizedBox(
//                                                 height: 30,
//                                               ),
//                                               LinearPercentIndicator(
//                                                 lineHeight: 4,
//                                                 animation: true,
//                                                 animationDuration: 100000,
//                                                 percent: 1,
//                                                 backgroundColor: Colors.grey
//                                                     .withOpacity(0.2),
//                                                 progressColor:
//                                                     Colors.deepOrange,
//                                               ),
//                                               SizedBox(
//                                                 height: 20,
//                                               ),
//                                               Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment.center,
//                                                 children: [
//                                                   FlatButton(
//                                                       onPressed: () {
//                                                         Navigator.pop(context);
//                                                         appState
//                                                             .cancelRequest();
//                                                         scaffoldState
//                                                             .currentState
//                                                             .showSnackBar(SnackBar(
//                                                                 content: Text(
//                                                                     "Request cancelled!")));
//                                                       },
//                                                       child: CustomText(
//                                                         text: "Cancel Request",
//                                                         color:
//                                                             Colors.deepOrange,
//                                                       )),
//                                                 ],
//                                               )
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   });
//                             },
//                             color: black,
//                             child: Text(
//                               "Request",
//                               style: TextStyle(color: white, fontSize: 16),
//                             ),
//                           ),
//                         ),
//                       ),
//                 SizedBox(
//                   height: 10,
//                 )
//               ],
//             ),
//           );
//         });
//   }
// }
