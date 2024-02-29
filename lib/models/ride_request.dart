import 'package:cloud_firestore/cloud_firestore.dart';

class RideRequestModel{
  static const ID = "id";
  static const USERNAME = "username";
  static const USER_ID = "userId";
  static const DRIVER_ID = "driverId";
  static const STATUS = "status";
  static const POSITION = "position";
  static const DESTINATION = "destination";

  final String _id;
  final String _username;
  final String _userId;
  final String _driverId;
  final String _status;
  final Map _position;
  final Map _destination;

  String get id => _id;
  String get username => _username;
  String get userId => _userId;
  String get driverId => _driverId;
  String get status => _status;
  Map get position => _position;
  Map get destination => _destination;

  RideRequestModel.fromSnapshot(DocumentSnapshot snapshot)
      : _id = snapshot[ID],
        _username = snapshot[USERNAME],
        _userId = snapshot[USER_ID],
        _driverId = snapshot[DRIVER_ID],
        _status = snapshot[STATUS],
        _position = snapshot[POSITION],
        _destination = snapshot[DESTINATION];






}