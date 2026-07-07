import 'package:flutter/foundation.dart';

class ApiSession extends ChangeNotifier {
  ApiSession._();

  static final ApiSession instance = ApiSession._();

  String? ownerId;
  String? groundId;
  String? contactNumber;
  String? ownerName;
  String? role;

  bool get isAuthenticated => ownerId != null && ownerId!.isNotEmpty;
  bool get hasGround => groundId != null && groundId!.isNotEmpty;

  void updateFromAuth(Map<String, dynamic> user) {
    ownerId = user['_id']?.toString() ?? user['id']?.toString() ?? ownerId;
    ownerName = user['ownerName']?.toString() ?? ownerName;
    contactNumber = user['contactNumber']?.toString() ?? contactNumber;
    role = user['role']?.toString() ?? role;
    notifyListeners();
  }

  void setContactNumber(String value) {
    contactNumber = value;
    notifyListeners();
  }

  void setGroundId(String? value) {
    groundId = value;
    notifyListeners();
  }

  void clear() {
    ownerId = null;
    groundId = null;
    contactNumber = null;
    ownerName = null;
    role = null;
    notifyListeners();
  }
}
