import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:insu_tracking/helpers/constants.dart';
import 'package:insu_tracking/models/driver.dart';

class DriverService {
  String collection = 'drivers';

  Stream<List<DriverModel>> getDrivers() {
    return firestore.collection(collection).snapshots().map((event) =>
        event.docs.map((e) => DriverModel.fromSnapshot(e)).toList());
  }

  Future<DriverModel> getDriverById(String id) =>
      firestore.collection(collection).doc(id).get().then((doc) {
        return DriverModel.fromSnapshot(doc);
      });

  Stream<QuerySnapshot> driverStream() {
    CollectionReference reference = FirebaseFirestore.instance.collection(collection);
    return reference.snapshots();
  }
}