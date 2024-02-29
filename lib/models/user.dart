import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  static const String FIELD_ID = 'id'; // Rename static field to avoid conflict
  static const String FIELD_NAME = 'name'; // Use consistent naming convention
  static const String FIELD_EMAIL = 'email';
  static const String FIELD_PHONE = 'phone';
  static const String FIELD_VOTES = 'votes';
  static const String FIELD_TRIPS = 'trips';
  static const String FIELD_RATING = 'rating';
  static const String FIELD_TOKEN = 'token';

  final String _id;
  final String _name;
  final String _email;
  final String _phone;
  final String _token;
  final int _votes;
  final int _trips;
  final double _rating;


  UserModel.fromSnapshot(DocumentSnapshot snapshot)
      : _id = snapshot[FIELD_ID],
        _name = snapshot[FIELD_NAME],
        _email = snapshot[FIELD_EMAIL],
        _phone = snapshot[FIELD_PHONE],
        _votes = snapshot[FIELD_VOTES],
        _trips = snapshot[FIELD_TRIPS],
        _rating = snapshot[FIELD_RATING],
        _token = snapshot[FIELD_TOKEN];

  // Getters
  String get name => _name;
  String get email => _email;
  String get id => _id; // Property for accessing ID

  String get phone => _phone;
  int get votes => _votes;
  int get trips => _trips;
  double get rating => _rating;

}
