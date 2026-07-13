import 'package:flutter/material.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../models/ground_registration_data.dart';

class GroundFlowController extends ChangeNotifier {
  GroundRegistrationData data = GroundRegistrationData();
  final GroundWaleApi _api = GroundWaleApi.instance;
  final ApiSession _session = ApiSession.instance;

  GroundFlowController() {
    data.offerType = OfferType.boxCricket;
  }

  int currentStep = 0;
  bool isBusy = false;
  String? errorMessage;

  bool get isAcademyFlow => false;
  bool get isBoxCricketFlow => true;

  int get totalSteps => 13;

  List<String> get stepTitles => const <String>[
    'Role',
    'Ground Details',
    'OTP',
    'List & Manage',
    'Ground Location',
    'Ground Photos',
    'Ground/Court Review',
    'Ground Facilities',
    'Configure Slot',
    'Add Custom Slots',
    'Slot View',
    'Ownership View',
    'Ground Under Review',
  ];

  bool get canContinueStep0 {
    return data.ownerName.trim().isNotEmpty &&
        data.contactNumber.trim().isNotEmpty &&
        data.address.trim().isNotEmpty &&
        data.otpVerified;
  }

  bool get canContinueStep5 => data.ownershipProof.isNotEmpty;

  void update() {
    notifyListeners();
  }

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      currentStep++;
      notifyListeners();
    }
  }

  void jumpToStep(int step) {
    if (step < 0 || step >= totalSteps) {
      return;
    }
    currentStep = step;
    notifyListeners();
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void reset() {
    data = GroundRegistrationData();
    data.offerType = OfferType.boxCricket;
    currentStep = 0;
    isBusy = false;
    errorMessage = null;
    notifyListeners();
  }

  Map<String, dynamic> _groundPayload() {
    return <String, dynamic>{
      'ownerId': _session.ownerId,
      'groundName': data.groundName,
      'location': '${data.city}, ${data.state}',
      'address': data.address,
      'areaLocation': data.areaLocation,
      'landmark': data.landmark,
      'description':
          '${data.pitchType.name} pitch for ${data.matchType} with ${data.facilities.join(', ')}',
      'state': data.state,
      'city': data.city,
      'sports': data.selectedSports.toList(),
      'academyBatch': <String, dynamic>{
        'batchName': data.academyBatchName,
        'coachName': data.academyCoachName,
        'perBatchStudents': data.academyPerBatchStudents,
        'category': data.academyCategory,
        'recurringDays': data.academyRecurringDays.toList(),
        'startTime': data.academyStartTime,
        'endTime': data.academyEndTime,
        'feePlans': data.academyFeePlans
            .map(
              (AcademyFeePlan plan) => <String, dynamic>{
                'duration': plan.duration,
                'price': plan.price,
              },
            )
            .toList(),
      },
      'pitchType': data.pitchType.name,
      'facilities': data.facilities.toList(),
      'groundImages': data.groundImages,
      'ownershipProof': data.ownershipProof,
      'openingTime': data.openingTime,
      'startDate': data.startDate.toIso8601String(),
      'endDate': data.endDate.toIso8601String(),
      'slotSize': data.slotSize,
      'gap': data.gap,
      'matchType': data.matchType,
      'offerType': OfferType.boxCricket.name,
      'entityType': 'box_cricket',
      'pinCode': data.pinCode,
      'daySlots': data.daySlots
          .map(
            (DaySlotConfig slot) => <String, dynamic>{
              'day': slot.day,
              'isEnabled': slot.isEnabled,
              'slotsPerDay': slot.slotsPerDay,
              'startTime': slot.startTime,
            },
          )
          .toList(),
    };
  }

  Future<void> submitGroundForVerification() async {
    if (!_session.isAuthenticated) {
      throw Exception(
        'Complete OTP verification before submitting your ground',
      );
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> profile = await _api
          .updateOwnerProfile(_session.ownerId!, <String, dynamic>{
            'ownerName': data.ownerName,
            'contactNumber': data.contactNumber,
            'email': data.email,
            'address': data.address,
            'role': 'owner',
          });
      _session.updateFromAuth(profile);

      Map<String, dynamic> ground;
      if (_session.hasGround) {
        ground = await _api.updateGround(_session.groundId!, _groundPayload());
      } else {
        ground = await _api.createGround(_groundPayload());
      }

      _session.setGroundId(
        ground['_id']?.toString() ?? ground['id']?.toString(),
      );

      if (data.ownershipProof.isNotEmpty) {
        await _api.updateOwnershipVerification(
          _session.groundId!,
          data.ownershipProof,
        );
      }

      await _api.submitGroundForReview(_session.groundId!);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<String?> ensureDraftGroundId() async {
    if (_session.hasGround) {
      return _session.groundId;
    }
    if (!_session.isAuthenticated || _session.ownerId == null) {
      return null;
    }

    final String? existing = await _api.ensureGroundIdForOwner(_session.ownerId!);
    if (existing != null && existing.isNotEmpty) {
      _session.setGroundId(existing);
      return existing;
    }

    final Map<String, dynamic> created = await _api.createGround(_groundPayload());
    final String createdId =
        created['_id']?.toString() ?? created['id']?.toString() ?? '';
    if (createdId.isEmpty) {
      return null;
    }
    _session.setGroundId(createdId);
    return createdId;
  }
}
