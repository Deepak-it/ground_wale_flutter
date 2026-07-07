import 'package:flutter/material.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../models/ground_registration_data.dart';

class GroundFlowController extends ChangeNotifier {
  GroundRegistrationData data = GroundRegistrationData();
  final GroundWaleApi _api = GroundWaleApi.instance;
  final ApiSession _session = ApiSession.instance;

  int currentStep = 0;
  bool isBusy = false;
  String? errorMessage;

  bool get isAcademyFlow => data.offerType == OfferType.academyCoaching;

  int get totalSteps => isAcademyFlow ? 8 : 10;

  List<String> get stepTitles => isAcademyFlow
      ? const <String>[
          'Choose Your Role',
          'Fill Basic Details',
          'What Do You Want To Offer',
          'Shared Details',
          'Choose Sports',
          'Create Academy Batch',
          'Ownership Verification',
          'Academy Under Review',
        ]
      : const <String>[
          'Choose Your Role',
          'Fill Basic Details',
          'What Do You Want To Offer',
          'Shared Details',
          'Choose Sports',
          'Ground Photos',
          'Ground Details',
          'Ground Review',
          'Ownership Verification',
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
      'offerType': data.offerType?.name,
      'entityType': isAcademyFlow
          ? 'academy'
          : (data.offerType == OfferType.sportsNeo ? 'sports_neo' : 'ground'),
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
      final String role = switch (data.offerType) {
        OfferType.boxCricket => 'box_cricket_owner',
        OfferType.academyCoaching => 'academy_owner',
        _ => 'ground_owner',
      };

      final Map<String, dynamic> profile = await _api.updateOwnerProfile(
        _session.ownerId!,
        <String, dynamic>{
        'ownerName': data.ownerName,
        'contactNumber': data.contactNumber,
        'email': data.email,
        'address': data.address,
        'role': role,
        },
      );
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
}
