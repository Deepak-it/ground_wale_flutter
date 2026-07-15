import 'package:flutter/foundation.dart';

class ApiSession extends ChangeNotifier {
  ApiSession._();

  static final ApiSession instance = ApiSession._();

  String? ownerId;
  String? groundId;
  String? contactNumber;
  String? ownerName;
  String? role;
  String? city;
  String? state;
  bool isGuest = false;
  String? selectedAcademyId;
  String? selectedAcademyName;

  bool get isAuthenticated => ownerId != null && ownerId!.isNotEmpty;
  bool get hasGround => groundId != null && groundId!.isNotEmpty;

  void updateFromAuth(Map<String, dynamic> user) {
    ownerId = user['_id']?.toString() ?? user['id']?.toString() ?? ownerId;
    ownerName = user['ownerName']?.toString() ?? ownerName;
    contactNumber = user['contactNumber']?.toString() ?? contactNumber;
    final String normalizedRole = _normalizeRole(user['role']);
    role = normalizedRole.isEmpty ? role : normalizedRole;
    final String? c = user['city']?.toString().trim();
    if (c != null && c.isNotEmpty) city = c;
    final String? s = user['state']?.toString().trim();
    if (s != null && s.isNotEmpty) state = s;
    isGuest = false;
    notifyListeners();
  }

  String _normalizeRole(dynamic raw) {
    if (raw == null) {
      return '';
    }
    final String value = raw.toString().trim().toLowerCase();
    if (value.isEmpty) {
      return '';
    }
    if (value == 'player' || value == 'captain') {
      return 'player';
    }
    if (
        value == 'owner' ||
        value == 'ground_owner' ||
        value == 'academy_owner' ||
        value == 'box_cricket_owner' ||
        value == 'box' ||
        value == 'ground' ||
        value == 'academy' ||
        value == 'coach') {
      return 'owner';
    }
    return value;
  }

  void setGuest() {
    ownerId = null;
    role = 'player';
    isGuest = true;
    notifyListeners();
  }

  void setSelectedAcademy({String? academyId, String? academyName}) {
    selectedAcademyId = academyId;
    selectedAcademyName = academyName;
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
    city = null;
    state = null;
    isGuest = false;
    selectedAcademyId = null;
    selectedAcademyName = null;
    notifyListeners();
  }
}

