import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {

  String _uid="";
  String _name="";
  String _email="";
  int _account_number=0;

  String get uid=>_uid;
  String get name => _name;
  String get email=>_email;
  int get account_number => _account_number;

  void SetAll(String uid,String name,String email, int account_number) {
    this._uid= uid;
    this._name= name;
    this._email= email;
    this._account_number= account_number;

    notifyListeners();
  }
}
