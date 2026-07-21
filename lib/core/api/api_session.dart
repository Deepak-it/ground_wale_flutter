import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiSession extends ChangeNotifier {
  ApiSession._();

  static final ApiSession instance = ApiSession._();

  static const String _kOwnerId = 'session.ownerId';
  static const String _kGroundId = 'session.groundId';
  static const String _kContactNumber = 'session.contactNumber';
  static const String _kOwnerName = 'session.ownerName';
  static const String _kRole = 'session.role';
  static const String _kCity = 'session.city';
  static const String _kState = 'session.state';
  static const String _kIsGuest = 'session.isGuest';
  static const String _kSelectedAcademyId = 'session.selectedAcademyId';
  static const String _kSelectedAcademyName = 'session.selectedAcademyName';

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
  bool _storageAvailable = true;

  bool get isAuthenticated => ownerId != null && ownerId!.isNotEmpty;
  bool get hasGround => groundId != null && groundId!.isNotEmpty;

  Future<bool> restoreFromStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      ownerId = prefs.getString(_kOwnerId);
      groundId = prefs.getString(_kGroundId);
      contactNumber = prefs.getString(_kContactNumber);
      ownerName = prefs.getString(_kOwnerName);
      role = prefs.getString(_kRole);
      city = prefs.getString(_kCity);
      state = prefs.getString(_kState);
      isGuest = prefs.getBool(_kIsGuest) ?? false;
      selectedAcademyId = prefs.getString(_kSelectedAcademyId);
      selectedAcademyName = prefs.getString(_kSelectedAcademyName);
      _storageAvailable = true;
      notifyListeners();
      return true;
    } on MissingPluginException {
      // Some desktop refresh/hot-reload paths can start before plugins attach.
      // Keep in-memory session and skip persistence for this runtime.
      _storageAvailable = false;
      return false;
    }
  }

  Future<void> _persist() async {
    if (!_storageAvailable) {
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      Future<void> setOrRemoveString(String key, String? value) async {
        if (value == null || value.trim().isEmpty) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, value);
        }
      }

      await setOrRemoveString(_kOwnerId, ownerId);
      await setOrRemoveString(_kGroundId, groundId);
      await setOrRemoveString(_kContactNumber, contactNumber);
      await setOrRemoveString(_kOwnerName, ownerName);
      await setOrRemoveString(_kRole, role);
      await setOrRemoveString(_kCity, city);
      await setOrRemoveString(_kState, state);
      await prefs.setBool(_kIsGuest, isGuest);
      await setOrRemoveString(_kSelectedAcademyId, selectedAcademyId);
      await setOrRemoveString(_kSelectedAcademyName, selectedAcademyName);
    } on MissingPluginException {
      _storageAvailable = false;
    }
  }

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
    _persist();
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
    if (value == 'owner' ||
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
    _persist();
    notifyListeners();
  }

  void setSelectedAcademy({String? academyId, String? academyName}) {
    selectedAcademyId = academyId;
    selectedAcademyName = academyName;
    _persist();
    notifyListeners();
  }

  void setContactNumber(String value) {
    contactNumber = value;
    _persist();
    notifyListeners();
  }

  void setGroundId(String? value) {
    groundId = value;
    _persist();
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
    _persist();
    notifyListeners();
  }
}
