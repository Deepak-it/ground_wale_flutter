import 'package:flutter/material.dart';

import '../../../../core/api/api_session.dart';
import '../../../../core/api/ground_wale_api.dart';
import '../models/ground_registration_data.dart';

class GroundFlowController extends ChangeNotifier {
  GroundRegistrationData data = GroundRegistrationData();
  final GroundWaleApi _api = GroundWaleApi.instance;
  final ApiSession _session = ApiSession.instance;

  GroundFlowController() {
    // offerType starts null so WhatToOfferScreen forces an explicit choice
  }

  int currentStep = 0;
  bool isBusy = false;
  String? errorMessage;
  bool skipOwnershipVerification = false;

  bool get isAcademyFlow => data.offerType == OfferType.academyCoaching;
  bool get isBoxCricketFlow => data.offerType == OfferType.boxCricket || data.offerType == null;

  int get totalSteps => 17;

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
    int next;
    if (isAcademyFlow) {
      switch (currentStep) {
        case 3:  next = 13; break; // WhatToOffer → Academy Details
        case 15: next = 5;  break; // Facilities → Photos
        case 5:  next = skipOwnershipVerification ? 16 : 11; break; // Photos → skip or Ownership
        case 11: next = 16; break; // Ownership → Academy Under Review
        default: next = currentStep + 1;
      }
    } else {
      // Ground / Box Cricket flow
      switch (currentStep) {
        case 7:  next = 8;  break; // Facilities → Configure Slot review
        case 9:  next = 8;  break; // Add Custom Slots → Configure Slot review
        case 10: next = 8;  break; // Day-wise Pricing → Configure Slot review
        case 8:  next = 11; break; // Configure Slot review → Ownership Verification
        default: next = currentStep + 1;
      }
    }
    if (next < totalSteps) {
      currentStep = next;
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
    int prev;
    if (isAcademyFlow) {
      switch (currentStep) {
        case 13: prev = 3;  break; // Academy Details → WhatToOffer
        case 14: prev = 13; break; // Batch → Academy Details
        case 15: prev = 14; break; // Facilities → Batch
        case 5:  prev = 15; break; // Photos → Facilities
        case 11: prev = 5;  break; // Ownership → Photos
        case 16: prev = 11; break; // Under Review → Ownership
        default: prev = currentStep - 1;
      }
    } else {
      // Ground / Box Cricket flow
      switch (currentStep) {
        case 8:  prev = 7;  break; // Configure Slot review → Facilities
        case 9:  prev = 8;  break; // Add Custom Slots → Configure Slot review
        case 10: prev = 8;  break; // Day-wise Pricing → Configure Slot review
        case 11: prev = 8;  break; // Ownership → Configure Slot review (ground path)
        default: prev = currentStep - 1;
      }
    }
    if (prev >= 0) {
      currentStep = prev;
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

  String get _entityType {
    switch (data.offerType) {
      case OfferType.academyCoaching:
        return 'academy';
      case OfferType.cricketGround:
        return 'ground';
      case OfferType.sportsNeo:
        return 'sports_neo';
      default:
        return 'box_cricket';
    }
  }

  Map<String, dynamic> _groundPayload() {
    final bool academy = isAcademyFlow;
    final String entityName = academy
        ? (data.academyName.trim().isNotEmpty ? data.academyName.trim() : 'Academy')
        : data.groundName;
    final String description = academy
        ? 'Academy with facilities: ${data.facilities.join(', ')}'
        : '${data.pitchType.name} pitch for ${data.matchType} with ${data.facilities.join(', ')}';
    return <String, dynamic>{
      'ownerId': _session.ownerId,
      'groundName': entityName,
      'location': '${data.city}, ${data.state}',
      'address': data.address,
      'areaLocation': data.areaLocation,
      'landmark': data.landmark,
      'description': description,
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
      'offerType': (data.offerType ?? OfferType.boxCricket).name,
      'entityType': _entityType,
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

  Map<String, dynamic> _academyPayload() {
    return <String, dynamic>{
      'name': data.academyName.trim().isNotEmpty ? data.academyName.trim() : 'Academy',
      'city': data.city.trim(),
      'state': data.state.trim(),
      'address': data.address.trim(),
      'areaLocation': data.areaLocation.trim(),
      'landmark': data.landmark.trim(),
      'pinCode': data.pinCode.trim(),
      'facilities': data.facilities.toList(),
      'groundImages': data.groundImages,
      'sports': data.selectedSports.toList(),
      'batch': <String, dynamic>{
        'batchName': data.academyBatchName,
        'coachName': data.academyCoachName,
        'coachExperience': data.academyCoachExperience,
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
    };
  }

  Future<void> submitGroundForVerification() async {
    if (!_session.isAuthenticated) {
      throw Exception(
        'Complete OTP verification before submitting',
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

      if (isAcademyFlow) {
        // ── Academy path: only creates an Academy record, no Ground ──
        final Map<String, dynamic> academy = await _api.createAcademy(
          _session.ownerId!,
          _academyPayload(),
        );
        final String academyId =
            academy['_id']?.toString() ?? academy['id']?.toString() ?? '';

        if (academyId.isNotEmpty) {
          _session.setSelectedAcademy(
            academyId: academyId,
            academyName: _academyPayload()['name']?.toString(),
          );

          if (data.ownershipProof.isNotEmpty) {
            await _api.updateAcademyOwnershipProof(
              _session.ownerId!,
              academyId,
              data.ownershipProof,
            );
          }

          await _api.submitAcademyForReview(_session.ownerId!, academyId);
          // Create the AcademyBatch record so it appears in /batches
          if (data.academyBatchName.trim().isNotEmpty) {
            final int capacity =
                int.tryParse(data.academyPerBatchStudents) ?? 30;
            final double monthlyFee = data.academyFeePlans.isNotEmpty
                ? double.tryParse(data.academyFeePlans.first.price) ?? 0
                : 0;
            try {
              await _api.createAcademyBatch(
                _session.ownerId!,
                <String, dynamic>{
                  'name': data.academyBatchName.trim(),
                  'coachName': data.academyCoachName.trim(),
                  'coachExperience': data.academyCoachExperience,
                  'startTime': data.academyStartTime,
                  'endTime': data.academyEndTime,
                  'days': data.academyRecurringDays.toList(),
                  'capacity': capacity,
                  'monthlyFee': monthlyFee,
                  'feePlans': data.academyFeePlans
                      .map((AcademyFeePlan p) => <String, String>{
                            'duration': p.duration,
                            'price': p.price,
                          })
                      .toList(),
                  'academyId': academyId,
                  'status': 'active',
                },
              );
            } catch (_) {
              // Non-fatal — batch can be added manually from dashboard
            }
          }        }
      } else {
        // ── Ground / Box Cricket path ──
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
      }
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
