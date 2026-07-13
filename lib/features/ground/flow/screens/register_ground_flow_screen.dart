import 'package:flutter/material.dart';

import '../../../ground_court/home/ground_court_owner_shell_screen.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';
import 'academy_batch_setup_screen.dart';
import 'academy_details_screen.dart';
import 'academy_facilities_screen.dart';
import 'add_custom_slots_screen.dart';
import 'basic_details_screen.dart';
import 'choose_role_screen.dart';
import 'configure_slots_screen.dart';
import 'ground_details_screen.dart';
import 'ground_photos_screen.dart';
import 'ground_review_screen.dart';
import 'ownership_verification_screen.dart';
import 'shared_details_screen.dart';
import 'slot_management_screen.dart';
import 'under_review_screen.dart';
import 'what_to_offer_screen.dart';

class RegisterGroundFlowScreen extends StatefulWidget {
  const RegisterGroundFlowScreen({
    super.key,
    this.initialController,
    this.initialStep,
    this.onFinish,
    this.skipUnderReview = false,
    this.forceCreateGround = false,
  });

  final GroundFlowController? initialController;
  final int? initialStep;
  /// Called when the final Under Review screen's Done button is pressed.
  /// If null the default navigation is used (push GroundCourtOwnerShellScreen).
  final VoidCallback? onFinish;
  /// When true, step 12 (Under Review) is skipped and [onFinish] is invoked
  /// immediately so the caller can pop back without showing the review screen.
  final bool skipUnderReview;
  /// When true, submitting the flow creates a new ground even if session already
  /// has an existing groundId.
  final bool forceCreateGround;

  @override
  State<RegisterGroundFlowScreen> createState() =>
      _RegisterGroundFlowScreenState();
}

class _RegisterGroundFlowScreenState extends State<RegisterGroundFlowScreen> {
  late final GroundFlowController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    controller = widget.initialController ?? GroundFlowController();
    _ownsController = widget.initialController == null;
    controller.forceCreateGround = widget.forceCreateGround;
    if (widget.initialStep != null) {
      controller.jumpToStep(widget.initialStep!);
    }
    if (widget.skipUnderReview) {
      controller.addListener(_skipUnderReviewListener);
    }
  }

  void _skipUnderReviewListener() {
    // Step 12 = UnderReview for box cricket. Skip it and call onFinish.
    if (controller.currentStep == 12 && widget.onFinish != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinish!();
      });
    }
  }

  @override
  void dispose() {
    if (widget.skipUnderReview) {
      controller.removeListener(_skipUnderReviewListener);
    }
    if (_ownsController) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final List<Widget> screens = <Widget>[
          ChooseRoleScreen(controller: controller),
          GroundDetailsScreen(controller: controller),
          BasicDetailsScreen(controller: controller),
          WhatToOfferScreen(controller: controller),
          SharedDetailsScreen(controller: controller),
          GroundPhotosScreen(controller: controller),
          GroundReviewScreen(controller: controller),
          AcademyFacilitiesScreen(controller: controller),    // 7 — Ground Facilities
          ConfigureSlotsScreen(data: controller.data, controller: controller),
          AddCustomSlotsScreen(data: controller.data, controller: controller),
          SlotManagementScreen(controller: controller),            // 10 — Day-wise Pricing
          OwnershipVerificationScreen(controller: controller),   // 11
          UnderReviewScreen(                                        // 12
            offerType: OfferType.boxCricket,
            onFinish: widget.onFinish ?? () {
              controller.reset();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const GroundCourtOwnerShellScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            },
          ),
          // Academy-specific branch (steps 13-16)
          AcademyDetailsScreen(controller: controller),            // 13
          AcademyBatchSetupScreen(controller: controller),         // 14
          AcademyFacilitiesScreen(controller: controller),         // 15
          UnderReviewScreen(                                        // 16
            offerType: OfferType.academyCoaching,
            onFinish: widget.onFinish ?? () {
              controller.reset();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const GroundCourtOwnerShellScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ];

        return PopScope(
          canPop: controller.currentStep == 0,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop && controller.currentStep > 0) {
              controller.previousStep();
            }
          },
          child: Scaffold(
            body: SafeArea(
              child: IndexedStack(
                index: controller.currentStep,
                children: screens,
              ),
            ),
          ),
        );
      },
    );
  }
}
