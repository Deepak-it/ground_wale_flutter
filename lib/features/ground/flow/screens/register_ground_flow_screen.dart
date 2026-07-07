import 'package:flutter/material.dart';

import '../../../academy/home/academy_dashboard_screen.dart';
import '../../../box_cricket/home/box_cricket_dashboard_screen.dart';
import '../../../sports_neo/home/sports_neo_dashboard_screen.dart';
import '../../dashboard/dashboard_turf_screen.dart';
import '../controllers/ground_flow_controller.dart';
import '../models/ground_registration_data.dart';
import 'academy_batch_setup_screen.dart';
import 'basic_details_screen.dart';
import 'choose_sports_screen.dart';
import 'choose_role_screen.dart';
import 'ground_details_screen.dart';
import 'ground_photos_screen.dart';
import 'ground_review_screen.dart';
import 'ownership_verification_screen.dart';
import 'shared_details_screen.dart';
import 'under_review_screen.dart';
import 'what_to_offer_screen.dart';

class RegisterGroundFlowScreen extends StatefulWidget {
  const RegisterGroundFlowScreen({
    super.key,
    this.initialController,
    this.initialStep,
  });

  final GroundFlowController? initialController;
  final int? initialStep;

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
    if (widget.initialStep != null) {
      controller.jumpToStep(widget.initialStep!);
    }
  }

  @override
  void dispose() {
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
        final bool academyFlow = controller.isAcademyFlow;
        final List<Widget> screens = academyFlow
            ? <Widget>[
                ChooseRoleScreen(controller: controller),
                BasicDetailsScreen(controller: controller),
                WhatToOfferScreen(controller: controller),
                SharedDetailsScreen(controller: controller),
                ChooseSportsScreen(controller: controller),
                AcademyBatchSetupScreen(controller: controller),
                OwnershipVerificationScreen(controller: controller),
                UnderReviewScreen(
                  offerType: controller.data.offerType,
                  onFinish: () {
                    final OfferType? offerType = controller.data.offerType;
                    controller.reset();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const AcademyDashboardScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ]
            : <Widget>[
                ChooseRoleScreen(controller: controller),
                BasicDetailsScreen(controller: controller),
                WhatToOfferScreen(controller: controller),
                SharedDetailsScreen(controller: controller),
                ChooseSportsScreen(controller: controller),
                GroundPhotosScreen(controller: controller),
                GroundDetailsScreen(controller: controller),
                GroundReviewScreen(controller: controller),
                OwnershipVerificationScreen(controller: controller),
                UnderReviewScreen(
                  offerType: controller.data.offerType,
                  onFinish: () {
                    final OfferType? offerType = controller.data.offerType;
                    controller.reset();
                    final Widget destination;
                    if (offerType == OfferType.boxCricket) {
                      destination = const BoxCricketDashboardScreen();
                    } else if (offerType == OfferType.sportsNeo) {
                      destination = const SportsNeoDashboardScreen();
                    } else {
                      destination = const DashboardTurfScreen();
                    }
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => destination),
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
